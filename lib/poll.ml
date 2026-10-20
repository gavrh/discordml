module type Poll = sig
  module Media : sig
    type t = { text : string option; emoji : Emoji.t option }

    val text : t -> string option
    val emoji : t -> Emoji.t option
    val pp : Format.formatter -> t -> unit
    val equal : t -> t -> bool
    val of_yojson : Yojson.Safe.t -> (t, string) result
  end

  module Answer : sig
    type t = { answer_id : int; media : Media.t }

    val answer_id : t -> int
    val media : t -> Media.t
    val pp : Format.formatter -> t -> unit
    val equal : t -> t -> bool
    val of_yojson : Yojson.Safe.t -> (t, string) result
  end

  module Answer_count : sig
    type t = { id : int; count : int; me_voted : bool }

    val id : t -> int
    val count : t -> int
    val me_voted : t -> bool
    val pp : Format.formatter -> t -> unit
    val equal : t -> t -> bool
    val of_yojson : Yojson.Safe.t -> (t, string) result
  end

  module Result : sig
    type t = { is_finalized : bool; answer_counts : Answer_count.t list }

    val is_finalized : t -> bool
    val answer_counts : t -> Answer_count.t list
    val pp : Format.formatter -> t -> unit
    val equal : t -> t -> bool
    val of_yojson : Yojson.Safe.t -> (t, string) result
  end

  type t = {
    question : Media.t;
    answers : Answer.t list;
    expiry : string option;
    allow_multiselect : bool;
    layout_type : int;
    results : Result.t option;
  }

  val question : t -> Media.t
  val answers : t -> Answer.t list
  val expiry : t -> string option
  val allow_multiselect : t -> bool
  val layout_type : t -> int
  val results : t -> Result.t option
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
  val show : t -> string
  val of_yojson : Yojson.Safe.t -> (t, string) result
end

include (
  struct
    module Media = struct
      type t = { text : string option; emoji : Emoji.t option }
      [@@deriving show, eq]

      let text (t : t) : string option = t.text
      let emoji (t : t) : Emoji.t option = t.emoji

      let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
          let emoji =
            match json |> member "emoji" with
            | `Null -> None
            | e -> (
                match Emoji.of_yojson e with
                | Ok emoji -> Some emoji
                | Error msg -> raise (Failure msg))
          in
          Ok { text = json |> member "text" |> to_string_option; emoji }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg
        | Failure msg -> Error msg
    end

    module Answer = struct
      type t = { answer_id : int; media : Media.t } [@@deriving show, eq]

      let answer_id (t : t) : int = t.answer_id
      let media (t : t) : Media.t = t.media

      let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
          let media =
            match Media.of_yojson (json |> member "poll_media") with
            | Ok media -> media
            | Error msg -> raise (Failure msg)
          in
          Ok
            {
              answer_id =
                json |> member "answer_id" |> to_int_option
                |> Option.value ~default:0;
              media;
            }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg
        | Failure msg -> Error msg
    end

    module Answer_count = struct
      type t = { id : int; count : int; me_voted : bool } [@@deriving show, eq]

      let id (t : t) : int = t.id
      let count (t : t) : int = t.count
      let me_voted (t : t) : bool = t.me_voted

      let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
          Ok
            {
              id =
                json |> member "id" |> to_int_option |> Option.value ~default:0;
              count =
                json |> member "count" |> to_int_option
                |> Option.value ~default:0;
              me_voted =
                json |> member "me_voted" |> to_bool_option
                |> Option.value ~default:false;
            }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg
    end

    module Result = struct
      type t = { is_finalized : bool; answer_counts : Answer_count.t list }
      [@@deriving show, eq]

      let is_finalized (t : t) : bool = t.is_finalized
      let answer_counts (t : t) : Answer_count.t list = t.answer_counts

      let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
          let answer_counts =
            match json |> member "answer_counts" with
            | `List l ->
                List.map
                  (fun c ->
                    match Answer_count.of_yojson c with
                    | Ok count -> count
                    | Error msg -> raise (Failure msg))
                  l
            | _ -> []
          in
          Ok
            {
              is_finalized =
                json |> member "is_finalized" |> to_bool_option
                |> Option.value ~default:false;
              answer_counts;
            }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg
        | Failure msg -> Error msg
    end

    type t = {
      question : Media.t;
      answers : Answer.t list;
      expiry : string option;
      allow_multiselect : bool;
      layout_type : int;
      results : Result.t option;
    }
    [@@deriving show, eq]

    let question (t : t) : Media.t = t.question
    let answers (t : t) : Answer.t list = t.answers
    let expiry (t : t) : string option = t.expiry
    let allow_multiselect (t : t) : bool = t.allow_multiselect
    let layout_type (t : t) : int = t.layout_type
    let results (t : t) : Result.t option = t.results

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
      let open Yojson.Safe.Util in
      try
        let question =
          match Media.of_yojson (json |> member "question") with
          | Ok media -> media
          | Error msg -> raise (Failure msg)
        in
        let answers =
          match json |> member "answers" with
          | `List l ->
              List.map
                (fun a ->
                  match Answer.of_yojson a with
                  | Ok answer -> answer
                  | Error msg -> raise (Failure msg))
                l
          | _ -> []
        in
        let results =
          match json |> member "results" with
          | `Null -> None
          | r -> (
              match Result.of_yojson r with
              | Ok result -> Some result
              | Error msg -> raise (Failure msg))
        in
        Ok
          {
            question;
            answers;
            expiry = json |> member "expiry" |> to_string_option;
            allow_multiselect =
              json |> member "allow_multiselect" |> to_bool_option
              |> Option.value ~default:false;
            layout_type =
              json |> member "layout_type" |> to_int_option
              |> Option.value ~default:0;
            results;
          }
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg
      | Failure msg -> Error msg
  end :
    Poll)
