type bucket = {
  mutable remaining : int;
  mutable reset_at : float;
  mutable in_flight : int;
  mutable learned : bool;
  changed : Eio.Condition.t;
}

type t = {
  sleep : float -> unit;
  now : unit -> float;
  mutex : Eio.Mutex.t;
  buckets : (string, bucket) Hashtbl.t;
  bucket_ids : (string, string) Hashtbl.t;
  mutable global_until : float;
}

let create ~(sleep : float -> unit) ~(now : unit -> float) : t =
  {
    sleep;
    now;
    mutex = Eio.Mutex.create ();
    buckets = Hashtbl.create 0;
    bucket_ids = Hashtbl.create 0;
    global_until = 0.;
  }

let route_key ~(meth : string) (path : string) : string =
  let path =
    match String.index_opt path '?' with
    | Some i -> String.sub path 0 i
    | None -> path
  in
  meth ^ " " ^ path

let bucket_for (t : t) (route : string) : bucket =
  let key =
    match Hashtbl.find_opt t.bucket_ids route with
    | Some bucket_id -> bucket_id
    | None -> route
  in
  match Hashtbl.find_opt t.buckets key with
  | Some bucket -> bucket
  | None ->
      let bucket =
        {
          remaining = 0;
          reset_at = 0.;
          in_flight = 0;
          learned = false;
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
      Eio.Mutex.use_rw ~protect:true t.mutex (fun () ->
          let bucket = bucket_for t route in
          let now = t.now () in
          if not bucket.learned then
            if bucket.in_flight = 0 then begin
              bucket.in_flight <- 1;
              `Reserved bucket
            end
            else begin
              Eio.Condition.await bucket.changed t.mutex;
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
          else `Wait (bucket.reset_at -. now))
    in
    match action with
    | `Reserved bucket -> bucket
    | `Retry -> loop ()
    | `Wait delay ->
        t.sleep delay;
        loop ()
  in
  loop ()

let finish (t : t) (route : string) (reserved : bucket)
    (headers : Http.Header.t) : unit =
  let bucket_id = Http.Header.get headers "x-ratelimit-bucket" in
  let limit =
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
  Eio.Mutex.use_rw ~protect:true t.mutex (fun () ->
      let target =
        match bucket_id with
        | Some id ->
            Hashtbl.replace t.bucket_ids route id;
            let target =
              match Hashtbl.find_opt t.buckets id with
              | Some bucket -> bucket
              | None ->
                  Hashtbl.replace t.buckets id reserved;
                  reserved
            in
            if id <> route then Hashtbl.remove t.buckets route;
            target
        | None -> reserved
      in
      (match limit with
      | Some (remaining, reset_after) ->
          target.learned <- true;
          target.remaining <- remaining;
          target.reset_at <- t.now () +. reset_after
      | None -> ());
      reserved.in_flight <- max 0 (reserved.in_flight - 1);
      Eio.Condition.broadcast reserved.changed;
      if target != reserved then Eio.Condition.broadcast target.changed)

let retry_after (headers : Http.Header.t) : float =
  match Http.Header.get headers "retry-after" with
  | Some v -> ( match float_of_string_opt v with Some d -> d | None -> 1.)
  | None -> 1.
