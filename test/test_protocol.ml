let check name condition =
  if condition then Printf.printf "  ok   %s\n" name
  else (Printf.printf "  FAIL %s\n" name; exit 1)

(* Round-trip frames through a real file to exercise the actual channel code
   rather than a mock. *)
let roundtrip payloads =
  let path = Filename.temp_file "arietta" ".frames" in
  let oc = open_out_bin path in
  List.iter (Arietta.Protocol.write_frame oc) payloads;
  close_out oc;
  let ic = open_in_bin path in
  let rec drain acc =
    match Arietta.Protocol.read_frame ic with
    | Some p -> drain (p :: acc)
    | None -> List.rev acc
  in
  let got = drain [] in
  close_in ic;
  Sys.remove path;
  got

let () =
  print_endline "Protocol:";

  check "a single frame survives" (roundtrip [ "hello" ] = [ "hello" ]);

  check "frames keep their order and boundaries"
    (roundtrip [ "alpha"; "beta"; "gamma" ] = [ "alpha"; "beta"; "gamma" ]);

  (* The boundary case framing exists to solve: payloads that contain what
     would otherwise look like delimiters. *)
  check "payloads may contain newlines and nulls"
    (roundtrip [ "a\nb\000c" ] = [ "a\nb\000c" ]);

  check "empty payloads are a valid frame" (roundtrip [ "" ] = [ "" ]);

  (* A payload larger than the initial read buffer, to confirm really_input
     loops rather than returning a short read. *)
  let big = String.make 500_000 'x' in
  check "large payloads survive intact" (roundtrip [ big ] = [ big ]);

  check "clean EOF reads as None" (roundtrip [] = []);

  check "oversized payloads are rejected"
    (match
       Arietta.Protocol.write_frame stdout
         (String.make (Arietta.Protocol.max_frame_size + 1) 'x')
     with
    | () -> false
    | exception Arietta.Protocol.Frame_too_large _ -> true);

  print_endline "all passed"
