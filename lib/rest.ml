module type Rest = sig
  type t
  type meth = Get | Post | Put | Patch | Delete

  type gateway_info = {
    url : string;
    shards : int;
    max_concurrency : int;
    sessions_remaining : int;
    sessions_reset_after : float;
  }

  val create :
    sw:Eio.Switch.t ->
    net:'a Eio.Net.t ->
    clock:'b Eio.Time.clock ->
    token:string ->
    t

  val request :
    t ->
    ?headers:(string * string) list ->
    ?body:string ->
    ?files:(string * string * string option) list ->
    meth ->
    string ->
    int * string

  val gateway_bot : t -> gateway_info
end

include (
  struct
    type meth = Get | Post | Put | Patch | Delete

    type gateway_info = {
      url : string;
      shards : int;
      max_concurrency : int;
      sessions_remaining : int;
      sessions_reset_after : float;
    }

    type t = { http : P_http.t; rate_limit : P_rate_limit.t }

    let create ~(sw : Eio.Switch.t) ~(net : 'a Eio.Net.t)
        ~(clock : 'b Eio.Time.clock) ~(token : string) : t =
      let http = P_http.create ~sw ~net ~token in
      let rate_limit =
        P_rate_limit.create
          ~sleep:(fun d -> Eio.Time.sleep clock d)
          ~now:(fun () -> Eio.Time.now clock)
      in
      { http; rate_limit }

    let meth_name = function
      | Get -> "GET"
      | Post -> "POST"
      | Put -> "PUT"
      | Patch -> "PATCH"
      | Delete -> "DELETE"

    let request (t : t) ?headers ?body ?files (meth : meth) (path : string) :
        int * string =
      let method_name = meth_name meth in
      let route = P_rate_limit.route_key ~meth:method_name path in
      let rec attempt n =
        let wait = P_rate_limit.global_wait t.rate_limit in
        if wait > 0. then P_rate_limit.sleep t.rate_limit wait;
        let bucket = P_rate_limit.reserve t.rate_limit route in
        let resp, body =
          match
            P_http.send t.http ?headers ?body ?files ~meth:method_name path
          with
          | response -> response
          | exception exn ->
              P_rate_limit.finish t.rate_limit route bucket
                (Http.Header.of_list []);
              raise exn
        in
        let headers = Http.Response.headers resp in
        P_rate_limit.finish t.rate_limit route bucket headers;
        let status = Http.Status.to_int (Http.Response.status resp) in
        if status = 429 && n < 3 then begin
          let delay = P_rate_limit.retry_after headers in
          (match Http.Header.get headers "x-ratelimit-scope" with
          | Some "global" -> P_rate_limit.set_global t.rate_limit delay
          | _ -> ());
          P_rate_limit.sleep t.rate_limit delay;
          attempt (n + 1)
        end
        else (status, body)
      in
      attempt 0

    let gateway_bot (t : t) : gateway_info =
      let code, body = request t Get "/gateway/bot" in
      if code <> 200 then
        failwith (Printf.sprintf "gateway/bot: HTTP %d: %s" code body);
      let json = Yojson.Safe.from_string body in
      let open Yojson.Safe.Util in
      let session_start_limit = json |> member "session_start_limit" in
      {
        url = json |> member "url" |> to_string;
        shards = json |> member "shards" |> to_int;
        max_concurrency =
          session_start_limit |> member "max_concurrency" |> to_int;
        sessions_remaining = session_start_limit |> member "remaining" |> to_int;
        sessions_reset_after =
          float_of_int (session_start_limit |> member "reset_after" |> to_int)
          /. 1000.;
      }
  end :
    Rest)
