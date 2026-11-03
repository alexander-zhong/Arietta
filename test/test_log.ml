let check name condition =
  if condition then Printf.printf "  ok   %s\n" name
  else (Printf.printf "  FAIL %s\n" name; exit 1)

let () =
  print_endline "Log:";

  let log = Arietta.Log.create () in
  check "a new log is empty" (Arietta.Log.length log = 0);

  (* Sequence numbers start at 1 and increase by exactly 1. *)
  let s1 = Arietta.Log.add log "alpha" in
  let s2 = Arietta.Log.add log "beta" in
  let s3 = Arietta.Log.add log "gamma" in
  check "first message is seq 1" (s1 = 1);
  check "sequence numbers have no gaps" (s2 = 2 && s3 = 3);
  check "length tracks the appends" (Arietta.Log.length log = 3);

  (* Reading back gives the payloads in the order they were appended. *)
  check "read 1" (Arietta.Log.read log 1 = Some "alpha");
  check "read 2" (Arietta.Log.read log 2 = Some "beta");
  check "read 3" (Arietta.Log.read log 3 = Some "gamma");

  (* Out of range reads are None rather than an exception. *)
  check "read 0 is None" (Arietta.Log.read log 0 = None);
  check "read past the end is None" (Arietta.Log.read log 4 = None);

  (* Growing past the initial capacity must preserve everything. *)
  let big = Arietta.Log.create () in
  for i = 1 to 100 do
    ignore (Arietta.Log.add big (string_of_int i))
  done;
  check "grows past initial capacity" (Arietta.Log.length big = 100);
  check "nothing lost when growing" (Arietta.Log.read big 1 = Some "1");
  check "last entry survives growth" (Arietta.Log.read big 100 = Some "100");

  print_endline "all passed"
