type t


val create : unit -> t
val add : t -> string -> int
val read : t -> int -> string option
val length : t -> int