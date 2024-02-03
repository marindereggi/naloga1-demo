(** Modul [Xkcd] omogoča branje opisov stripov iz strani xkcd.com, ki so na voljo v formatu JSON **)

type comic = { id : int; title : string; transcript : string; tooltip : string }
(** Tip [comic] hrani podatke o posameznem stripu
   [id]: zaporedna številka stripa
   [title]: naslov stripa
   [transcript]: prepis besedila iz stripa in opis scene
   [tooltip]: napis, ki se pokaže pri stripu
*)

val fetch_latest_comic : unit -> comic

val fetch_comic : int -> (comic, string) result
(**
Funkcija [fetch_comic] prebere podatke iz spletne strani xkcd za strip s številko [id].
Vrne podatkovno strukturo [comic], ki vsebuje podatke o stripu.
*)
