let token : string =
    Dotenv.export () |> ignore;
    match Sys.getenv_opt "DISCORD_TOKEN" with
    | None -> failwith "No token found"
    | Some token -> token

let client = Discord.Client.create Discord.Intent.all

let () =
    Discord.Client.on_ready client (fun client ->
        match Discord.Client.user client with
        | Some user ->
                Printf.printf "%s (%s) is ready!\n%!"
                (Discord.User.username user)
                (Discord.User.id user)
        | None -> ())

let () =
    Discord.Client.on_message client (fun client message ->
        match Discord.Client.user client with
        | Some user
          when Discord.User.id user
               = Discord.User.id (Discord.Message.author message) -> ()
        | _ ->
            let content : string = Discord.Message.content message in
            if content <> "" then
                Discord.Message.reply (Discord.Client.rest client)
                    message content)

let () =
    Eio_main.run @@ fun env ->
    Discord.Client.start ~env client token
