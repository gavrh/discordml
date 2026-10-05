let token : string =
    Dotenv.export () |> ignore;
    match Sys.getenv_opt "DISCORD_TOKEN" with
    | None -> failwith "No token found"
    | Some token -> token

let client = Discord.Client.create Discord.Intent.standard

let () =
    Discord.Client.on_ready client (fun client ->
        match Discord.Client.user client with
        | Some user -> 
                Printf.printf "%s (%s) is ready!\n%!"
                (Discord.User.username user)
                (Discord.User.id user)
        | None -> ())

let () =
    Eio_main.run @@ fun env ->
    Discord.Client.start ~env client token
