(lang dune 3.24)

(name arietta)

(generate_opam_files true)

(source
 (github alexander-zhong/Arietta))

(license MIT)

(package
 (name arietta)
 (synopsis "A total-order message log for state machine replication")
 (description
  "Arietta is a message transport that assigns every message a global sequence\n\
   number, so that independent machines replaying the same log converge on the\n\
   same state without coordinating. Inspired by Jane Street's Aria.")
 (depends
  (ocaml
   (>= 5.0))))
