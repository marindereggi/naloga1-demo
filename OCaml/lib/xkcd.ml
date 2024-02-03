type comic = {
  id : int; [@key "num"]
  title : string;
  transcript : string;
  tooltip : string; [@key "alt"]
}
[@@deriving of_yojson { strict = false }]

let fetch_data url =
  let open Curly in
  let request = Request.make ~url ~meth:`GET () in
  match run request with
  | Ok response when response.code = 200 -> Ok response.body
  | Error e -> Error (Format.asprintf "Failed: %a" Error.pp e)
  | _ -> Error "HTTP request failed"

let parse_json json_string =
  try Ok (Yojson.Safe.from_string json_string)
  with Yojson.Json_error msg -> Error msg

let fetch_comic_from url =
  let ( >>= ) = Result.bind in
  fetch_data url >>= parse_json >>= comic_of_yojson

let url = "https://xkcd.com/"
let fetch_comic id = fetch_comic_from (url ^ string_of_int id ^ "/info.0.json")

let fetch_latest_comic () =
  match fetch_comic_from (url ^ "info.0.json") with
  | Ok comic -> comic
  | Error e -> failwith e
