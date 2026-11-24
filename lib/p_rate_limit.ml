type bucket = {
  mutable remaining : int;
  mutable limit : int option;
  mutable reset_at : float;
  mutable in_flight : int;
  mutable waiters : int;
  mutable learned : bool;
  mutable last_used : float;
  changed : Eio.Condition.t;
}

type route_entry = { bucket_id : string; mutable last_used : float }

type t = {
  sleep : float -> unit;
  now : unit -> float;
  mutex : Eio.Mutex.t;
  buckets : (string, bucket) Hashtbl.t;
  bucket_ids : (string, route_entry) Hashtbl.t;
  mutable global_until : float;
}

let max_buckets = 4096
let max_routes = 8192
let max_wait_jitter = 0.25

let random_state =
  lazy
    (Mirage_crypto_rng_unix.use_default ();
     let seed = Mirage_crypto_rng.generate 16 in
     Random.State.make (Array.init 16 (fun i -> Char.code seed.[i])))

let jitter () : float =
  Random.State.float (Lazy.force random_state) max_wait_jitter

let create ~(sleep : float -> unit) ~(now : unit -> float) : t =
  {
    sleep;
    now;
    mutex = Eio.Mutex.create ();
    buckets = Hashtbl.create 0;
    bucket_ids = Hashtbl.create 0;
    global_until = 0.;
  }

let is_numeric (segment : string) : bool =
  segment <> "" && String.for_all (fun c -> c >= '0' && c <= '9') segment

let route_key ~(meth : string) (path : string) : string =
  let path =
    match String.index_opt path '?' with
    | Some i -> String.sub path 0 i
    | None -> path
  in
  let segments = String.split_on_char '/' path in
  let kind = match segments with "" :: kind :: _ -> kind | _ -> "" in
  let major =
    kind = "channels" || kind = "guilds" || kind = "webhooks"
    || kind = "interactions"
  in
  let segments =
    List.mapi
      (fun index segment ->
        if index = 2 && major then segment
        else if (kind = "webhooks" || kind = "interactions") && index = 3 then
          ":token"
        else if is_numeric segment then ":id"
        else segment)
      segments
  in
  meth ^ " " ^ String.concat "/" segments

let removable (bucket : bucket) : bool =
  bucket.in_flight = 0 && bucket.waiters = 0

let evict_bucket (t : t) : unit =
  let victim =
    Hashtbl.fold
      (fun key bucket acc ->
        if removable bucket then
          match acc with
          | Some (_, last_used) when last_used <= bucket.last_used -> acc
          | _ -> Some (key, bucket.last_used)
        else acc)
      t.buckets None
  in
  match victim with
  | None -> ()
  | Some (key, _) ->
      Hashtbl.remove t.buckets key;
      let stale =
        Hashtbl.fold
          (fun route entry acc ->
            if entry.bucket_id = key then route :: acc else acc)
          t.bucket_ids []
      in
      List.iter (Hashtbl.remove t.bucket_ids) stale

let lru_route (t : t) : string option =
  Hashtbl.fold
    (fun route entry acc ->
      match acc with
      | Some (_, last_used) when last_used <= entry.last_used -> acc
      | _ -> Some (route, entry.last_used))
    t.bucket_ids None
  |> Option.map fst

let prune_routes (t : t) : unit =
  let stale =
    Hashtbl.fold
      (fun route entry acc ->
        if Hashtbl.mem t.buckets entry.bucket_id then acc else route :: acc)
      t.bucket_ids []
  in
  List.iter (Hashtbl.remove t.bucket_ids) stale;
  let rec evict () =
    if Hashtbl.length t.bucket_ids >= max_routes then
      match lru_route t with
      | Some route ->
          Hashtbl.remove t.bucket_ids route;
          evict ()
      | None -> ()
  in
  evict ()

let remember_route (t : t) (route : string) (bucket_id : string) : unit =
  if Hashtbl.length t.bucket_ids >= max_routes then prune_routes t;
  Hashtbl.replace t.bucket_ids route { bucket_id; last_used = t.now () }

let bucket_for (t : t) (route : string) : bucket =
  let now = t.now () in
  let key =
    match Hashtbl.find_opt t.bucket_ids route with
    | Some entry ->
        entry.last_used <- now;
        entry.bucket_id
    | None -> route
  in
  match Hashtbl.find_opt t.buckets key with
  | Some bucket ->
      bucket.last_used <- now;
      bucket
  | None ->
      if Hashtbl.length t.buckets >= max_buckets then evict_bucket t;
      let bucket =
        {
          remaining = 0;
          limit = None;
          reset_at = 0.;
          in_flight = 0;
          waiters = 0;
          learned = false;
          last_used = now;
          changed = Eio.Condition.create ();
        }
      in
      Hashtbl.replace t.buckets key bucket;
      bucket

let global_wait (t : t) : float =
  Eio.Mutex.use_rw ~protect:true t.mutex (fun () ->
      max 0. (t.global_until -. t.now ()))

let set_global (t : t) (delay : float) : unit =
  Eio.Mutex.use_rw ~protect:true t.mutex (fun () ->
      t.global_until <- t.now () +. delay)

let sleep (t : t) (delay : float) : unit = t.sleep delay

let reserve (t : t) (route : string) : bucket =
  let rec loop () =
    let action =
      Eio.Mutex.use_rw ~protect:false t.mutex (fun () ->
          try
            let bucket = bucket_for t route in
            let now = t.now () in
            if not bucket.learned then
              if bucket.in_flight = 0 then begin
                bucket.in_flight <- 1;
                `Reserved bucket
              end
              else begin
                bucket.waiters <- bucket.waiters + 1;
                Fun.protect
                  ~finally:(fun () -> bucket.waiters <- bucket.waiters - 1)
                  (fun () -> Eio.Condition.await bucket.changed t.mutex);
                `Retry
              end
            else if bucket.remaining > 0 then begin
              bucket.remaining <- bucket.remaining - 1;
              bucket.in_flight <- bucket.in_flight + 1;
              `Reserved bucket
            end
            else if bucket.reset_at <= now then begin
              bucket.learned <- false;
              bucket.in_flight <- bucket.in_flight + 1;
              `Reserved bucket
            end
            else `Wait (bucket.reset_at -. now)
          with Eio.Cancel.Cancelled _ as exn -> `Cancelled exn)
    in
    match action with
    | `Reserved bucket -> bucket
    | `Retry -> loop ()
    | `Cancelled exn -> raise exn
    | `Wait delay ->
        t.sleep (delay +. jitter ());
        loop ()
  in
  loop ()

let finish (t : t) (route : string) (reserved : bucket)
    (headers : Http.Header.t) : unit =
  let bucket_id = Http.Header.get headers "x-ratelimit-bucket" in
  let reported =
    match
      ( Http.Header.get headers "x-ratelimit-remaining",
        Http.Header.get headers "x-ratelimit-reset-after" )
    with
    | Some remaining, Some reset_after -> (
        match
          (int_of_string_opt remaining, float_of_string_opt reset_after)
        with
        | Some remaining, Some reset_after -> Some (remaining, reset_after)
        | _ -> None)
    | _ -> None
  in
  let limit =
    match Http.Header.get headers "x-ratelimit-limit" with
    | Some value -> int_of_string_opt value
    | None -> None
  in
  Eio.Cancel.protect (fun () ->
      Eio.Mutex.use_rw ~protect:true t.mutex (fun () ->
          let target =
            match bucket_id with
            | Some id ->
                let target =
                  match Hashtbl.find_opt t.buckets id with
                  | Some bucket -> bucket
                  | None ->
                      if Hashtbl.length t.buckets >= max_buckets then
                        evict_bucket t;
                      Hashtbl.replace t.buckets id reserved;
                      reserved
                in
                if id <> route then Hashtbl.remove t.buckets route;
                remember_route t route id;
                target
            | None -> reserved
          in
          Option.iter (fun value -> target.limit <- Some value) limit;
          reserved.in_flight <- max 0 (reserved.in_flight - 1);
          (match reported with
          | Some (remaining, reset_after) ->
              target.learned <- true;
              let budget =
                match target.limit with
                | Some limit -> min remaining (max 0 (limit - target.in_flight))
                | None -> remaining
              in
              target.remaining <- max 0 budget;
              target.reset_at <- t.now () +. reset_after
          | None -> ());
          Eio.Condition.broadcast reserved.changed;
          if target != reserved then Eio.Condition.broadcast target.changed))

let retry_after (headers : Http.Header.t) : float =
  match Http.Header.get headers "retry-after" with
  | Some v -> ( match float_of_string_opt v with Some d -> d | None -> 1.)
  | None -> 1.
