# arietta

* INSPIRED BY Aria from Jane Street* — a total-order message log for state machine replication, in OCaml.

> **Status: pre-alpha.** The in-memory log works. Nothing is networked or
> persisted yet. Not usable for anything real.

## What it is

Run the same deterministic code on several machines and have them stay in sync,
without writing any consensus code.

Arietta assigns every message a single global sequence number. Machines that
replay the same log compute the same state — not eventually, not approximately,
but exactly, because they ran the same function over the same inputs in the
same order.

```ocaml
(* each machine, independently *)
let state = ref initial in
Arietta.Log.iter log ~f:(fun _seq msg -> state := apply !state msg)
```

If `apply` is deterministic, every machine lands on the same `state`. That is
the entire product. The transport is the means.

## Why not Kafka

Kafka gives up global ordering to scale writes across partitions. That trade
makes it excellent at event streaming and useless for state machine
replication, because two replicas reading different partitions have no agreed
order to replay.

Arietta refuses that trade: **one sequencer, one total order**, and everything
else is engineering to make that fast enough.

| | Kafka & friends | arietta |
|---|---|---|
| Ordering | per-partition | **one total order** |
| Scaling writes | add partitions | one sequencer, made fast |
| Delivery | consumer pulls | **push** |
| Optimized for | throughput | **latency** |
| Durability | ack after replication | **ack from buffer, fsync off the path** |
| Consumer offsets | tracked by broker | **owned by the subscriber** |
| Primary use case | event streaming | **state machine replication** |

If you need to scale writes beyond one machine, use Kafka. If you need every
subscriber to see every message in the same order, that is what this is for.

## Inspiration

Built after a Jane Street tech talk on Aria, their internal message transport
(30 µs roundtrip in-datacenter, 10 Gbps through a single sequencer). Arietta is
an independent open-source implementation of the same architectural ideas. It
is not affiliated with Jane Street and shares no code with Aria.

## Build

```sh
dune build
dune test
dune exec bin/main.exe
```

Requires OCaml >= 5.0.

## Roadmap

- [x] **M1** in-memory ordered log, deterministic replay, replica convergence
- [ ] **M2** TCP sequencer + client library
- [ ] **M3** persistence and replay from an offset
- [ ] **M4** hot loop: buffer-ack vs fsync-ack, measured
- [ ] **M5** benchmarks against Redis Streams, NATS, and a raw TCP floor
- [ ] **M6** publisher fanout tier
- [ ] **M7** docs, property tests, API polish

## License

MIT
