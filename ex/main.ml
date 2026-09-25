let token : string =
    Dotenv.export () |> ignore;
    match Sys.getenv_opt "DISCORD_TOKEN" with
    | None -> failwith "No token found"
    | Some token -> token

let client = Discord.Client.create Discord.Client.Intent.all
let () = Discord.Client.start client token
