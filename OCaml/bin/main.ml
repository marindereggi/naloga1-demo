let fields_of_string str ~keep =
  let nullc = '\x00' in
  String.map (fun c -> if keep c then c else nullc) str
  |> String.split_on_char nullc
  |> List.filter (fun word -> word <> "")

let sanitize str =
  let lower = String.lowercase_ascii str
  and alphanum = function
    | '0' .. '9' | 'a' .. 'z' | 'A' .. 'Z' -> true
    | _ -> false
  in
  fields_of_string lower ~keep:alphanum

let words_in_comic id =
  let open Naloga1.Xkcd in
  let sanitize_comic c =
    sanitize c.title
    @ sanitize (if c.transcript <> "" then c.transcript else c.tooltip)
    |> List.filter (fun word -> String.length word >= 4)
  in
  fetch_comic id |> Result.map sanitize_comic

let print_top freqs n =
  let order (word1, freq1) (word2, freq2) =
    match compare freq2 freq1 with 0 -> String.compare word1 word2 | x -> x
  in
  Hashtbl.to_seq freqs |> List.of_seq |> List.sort order |> List.to_seq
  |> Seq.take n
  |> Seq.iter @@ fun (word, freq) -> Printf.printf "%s, %d\n" word freq

let get_appendfn ht =
  let m = ref @@ Mutex.create () in
  fun ?(v = 1) keylist ->
    let update_ht k =
      let freq = Hashtbl.find_opt ht k |> Option.value ~default:0 in
      Hashtbl.replace ht k (freq + v)
    in
    Mutex.protect !m (fun () -> List.iter update_ht keylist)

let parse_args () =
  let num_domains = ref 7 in
  let verbose = ref false in
  Arg.parse
    [
      ("-domains", Arg.Set_int num_domains, "amount of domains");
      ("-verbose", Arg.Set verbose, "print errors");
    ]
    ignore "Usage: naloga1 [-domains <int>] [-verbose]";
  (!num_domains, !verbose)

let () =
  let num_domains, verbose = parse_args ()
  and num_comics = Naloga1.Xkcd.fetch_latest_comic () |> fun comic -> comic.id
  and freqs = Hashtbl.create 20_000 in

  let append_to_hashtbl = get_appendfn freqs in
  let body id =
    words_in_comic id |> function
    | Ok words -> append_to_hashtbl words
    | Error e -> if verbose then Printf.eprintf "Error #%d: %s\n" id e
  in

  let open Domainslib.Task in
  let pool = setup_pool ~num_domains () in
  run pool (fun () -> parallel_for pool ~start:1 ~finish:num_comics ~body);
  teardown_pool pool;

  print_top freqs 15
