val max_frame_size : int
(** Largest payload allowed in bytes *)

exception Frame_too_large of int
(** Raised when a payload is bigger than [max_frame_size]. *)

val write_frame : out_channel -> string -> unit
(** Write a 4-byte big-endian length, then the payload, then flush. *)

val read_frame : in_channel -> string option
(** Read one frame. [None] if the connetion closed cleanly between frames. *)
