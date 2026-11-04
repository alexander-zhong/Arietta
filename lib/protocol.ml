let max_frame_size = 64 * 1024 * 1024

exception Frame_too_large of int

let write_frame oc payload = 
  let n = String.length payload in
  if n > max_frame_size then raise (Frame_too_large n);
  output_binary_int oc n;
  output_string oc payload;
  flush oc

let read_frame ic = 
  match really_input_string ic 4 with 
  | exception End_of_file -> None
  | header -> 
    let n = Int32.to_int (String.get_int32_be header 0) in
    if n < 0 || n > max_frame_size then raise (Frame_too_large n);
    Some (really_input_string ic n)