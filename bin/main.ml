(* 1. The state machine: balance + message -> new balance *)
let apply balance msg =
  match String.split_on_char ' ' msg with
  | [ "deposit"; amount ] -> balance + int_of_string amount
  | [ "withdraw"; amount ] ->
      let amount = int_of_string amount in
      if balance >= amount then balance - amount else balance
  | _ -> balance

(* 2. A replica: read the first [total] messages, fold them into a balance *)
let run_replica log total =
  let balance = ref 0 in
  Seq.iter
    (fun (_seq, msg) -> balance := apply !balance msg)
    (Seq.take total (Arietta.Log.subscribe log ~from_seq:1));
  !balance

(* 3. Main: one log, one producer, two replicas *)
let () =
  let log = Arietta.Log.create () in
  let messages =
    [ "deposit 100"; "withdraw 80"; "withdraw 80";
      "deposit 50"; "withdraw 30"; "deposit 10" ]
  in
  let total = List.length messages in
  let result_a = ref 0 and result_b = ref 0 in

  let ta = Thread.create (fun () -> result_a := run_replica log total) () in
  let tb = Thread.create (fun () -> result_b := run_replica log total) () in

  let producer =
    Thread.create
      (fun () ->
        List.iter
          (fun m ->
            Thread.delay 0.05;
            ignore (Arietta.Log.add log m))
          messages)
      ()
  in

  Thread.join producer;
  Thread.join ta;
  Thread.join tb;

  Printf.printf "replica A: %d\nreplica B: %d\n" !result_a !result_b;
  if !result_a = !result_b then print_endline "CONVERGED"
  else print_endline "DIVERGED (bug!)"