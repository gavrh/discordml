let token : string =
    Dotenv.export () |> ignore;
    match Sys.getenv_opt "DISCORD_TOKEN" with
    | Some token -> token
    | None -> failwith "No token found"

let c  = Discord.Client.create token
let () = print_endline (Discord.Client.string_of_client c)
