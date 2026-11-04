type t


val create : unit -> t
val add : t -> string -> int
val read : t -> int -> string option
val length : t -> int

val wait_read : t -> int -> string
val subscribe : t -> from_seq:int -> (int * string) Seq.t