module type Client = sig
    type t

    val token : t -> string option

    val create : int -> t
    val start : env:Eio_unix.Stdenv.base -> t -> string -> unit

    val guild : t -> string -> Guild.t option
    val user : t -> User.t option

    val on_event : t -> Event.t -> (t -> Yojson.Safe.t -> unit) -> unit

    val show : t -> string
end

include (struct

    type t = {
        mutable token : string option;
        intents : int;
        guilds : (string, Guild.t) Hashtbl.t [@printer fun fmt tbl -> Format.fprintf fmt "[ ...%d ]" (Hashtbl.length tbl)];
        guilds_mutex : Eio.Mutex.t [@opaque];
        shards : (int, Discord_private.P_shard.t) Hashtbl.t [@printer fun fmt tbl -> Format.fprintf fmt "[ ...%d ]" (Hashtbl.length tbl)];
        shards_mutex : Eio.Mutex.t [@opaque];
        handlers : (Event.t, (t -> Yojson.Safe.t -> unit) list) Hashtbl.t Atomic.t [@opaque];
        mutable user : User.t option [@printer fun fmt u ->
            match u with
            | Some u -> Format.pp_print_string fmt (User.show u)
            | None -> Format.pp_print_string fmt "None"];
        mutable rest : Discord_private.P_rest.t option [@opaque];
    } [@@deriving show]

    let token (c : t) : string option = c.token

    let guild (c : t) (gid : string) : Guild.t option =
        Eio.Mutex.use_ro c.guilds_mutex (fun () -> Hashtbl.find_opt c.guilds gid)

    let user (c : t) : User.t option = c.user

    let on_event (c : t) (event : Event.t)
            (f : t -> Yojson.Safe.t -> unit) : unit =
        let rec add () =
            let old = Atomic.get c.handlers in
            let tbl = Hashtbl.copy old in
            let existing =
                match Hashtbl.find_opt tbl event with Some l -> l | None -> []
            in
            Hashtbl.replace tbl event (f :: existing);
            if not (Atomic.compare_and_set c.handlers old tbl) then add ()
        in
        add ()

    let create (i : int) : t = {
        token = None;
        intents = i;
        guilds = Hashtbl.create 0;
        guilds_mutex = Eio.Mutex.create ();
        shards = Hashtbl.create 0;
        shards_mutex = Eio.Mutex.create ();
        handlers = Atomic.make (Hashtbl.create 0);
        user = None;
        rest = None;
    }

    let start ~(env : Eio_unix.Stdenv.base) (c : t) (token : string) : unit =
        let net = Eio.Stdenv.net env in
        let clock = Eio.Stdenv.clock env in
        Eio.Switch.run @@ fun sw ->
        c.token <- Some token;
        let rest = Discord_private.P_rest.create ~sw ~net ~clock ~token in
        c.rest <- Some rest;
        let info = Discord_private.P_rest.gateway_bot rest in
        let open Yojson.Safe.Util in
        let dispatch (name : string) (json : Yojson.Safe.t) : unit =
            match Event.of_string name with
            | None -> ()
            | Some event ->
                (match event with
                 | Event.Ready ->
                     (match User.of_yojson (json |> member "user") with
                      | Ok user ->
                          c.user <- Some user
                      | Error _ -> ())
                 | _ -> ());
                let handlers =
                    match Hashtbl.find_opt (Atomic.get c.handlers) event with
                    | Some l -> l
                    | None -> []
                in
                List.iter
                    (fun f -> Eio.Fiber.fork ~sw (fun () -> f c json))
                    handlers
        in
        let rec spawn i =
            if i < info.shards then begin
                let shard =
                    Discord_private.P_shard.connect ~url:info.url
                        ~id:i ~num_shards:info.shards ~token ~intents:c.intents
                in
                Eio.Mutex.use_rw ~protect:true c.shards_mutex (fun () ->
                    Hashtbl.replace c.shards i shard);
                Eio.Fiber.fork ~sw (fun () ->
                    Fun.protect
                        ~finally:(fun () ->
                            Eio.Mutex.use_rw ~protect:true c.shards_mutex (fun () ->
                                Hashtbl.remove c.shards i))
                        (fun () ->
                            Discord_private.P_shard.run ~net ~dispatch clock
                                shard));
                if (i + 1) mod info.max_concurrency = 0 then
                    Eio.Time.sleep clock 5.;
                spawn (i + 1)
            end
        in
        spawn 0

end : Client)
