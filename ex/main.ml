let token : string =
    Dotenv.export () |> ignore;
    match Sys.getenv_opt "DISCORD_TOKEN" with
    | None -> failwith "No token found"
    | Some token -> token

let client = Discord.Client.create Discord.Client.Intent.all

let () =
    Discord.Client.on_ready client (fun ctx ->
        match Discord.Client.id ctx with
        | Some id -> Printf.printf "ready as %s\n%!" id
        | None -> ())

let () =
    Eio_main.run @@ fun env ->
    Discord.Client.start ~env client token
