let token : string =
    Dotenv.export () |> ignore;
    match Sys.getenv_opt "DISCORD_TOKEN" with
    | None -> failwith "No token found"
    | Some token -> token

let client = Discord.Client.create Discord.Client.Intent.all

let () = print_endline (Discord.Client.show client)

let () =
    Eio_main.run @@ fun env ->
    Discord.Client.start ~env client token
