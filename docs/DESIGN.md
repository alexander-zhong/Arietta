# Design

## The guarantee

Arietta provides exactly one thing: **a total order over messages.**

Every message appended gets a sequence number. Sequence numbers start at 1,
increase by exactly 1, and have no gaps. Every subscriber sees every message,
exactly once, in sequence order.

That is deliberately a small promise. Everything else — what a message means,
what state it produces, whether an operation is valid — belongs to the
application.

## Why that guarantee is the useful one

A deterministic function `apply : state -> message -> state` folded over an
ordered log produces the same final state on every machine that runs it. No
locks, no coordination, no consensus protocol in application code.

The consequence that surprises people: **conditions must be evaluated after
sequencing, not before.** This is wrong:

```
if balance >= amount then log.add (withdraw amount)   (* TOCTOU race *)
```

Two machines both read a stale balance and both append. The fix is to append
the *request* and let `apply` adjudicate it at a definite log position, where
no concurrency remains:

```
log.add (withdraw_request amount)
(* ... later, inside apply, at a known sequence number ... *)
if balance >= amount then accept else reject
```

Sequencing is the line between the racy region and the ordered region. The
application's job is to get its decisions onto the right side of it.

## Architecture

```
  apps --> injectors --> sequencer --> buffer --> [disk]
                                          |
                                          +--> publishers --> apps
```

| Component | Role | Milestone |
|---|---|---|
| **sequencer** | assigns sequence numbers. exactly one. | M2 |
| **buffer** | in-memory; serves subscribers before fsync completes | M4 |
| **disk** | durable ordered record; serves replay | M3 |
| **publishers** | fan out to subscribers; chainable into a tree | M6 |
| **injectors** | absorb client connections | not planned |

Every component except the sequencer exists to protect the sequencer. One
machine must touch every message, so everything else is arranged so that is
all it does.

Injectors are deliberately out of scope: they solve a problem (thousands of
inbound connections) that does not arise at the scale this project targets.

## Decisions

**One sequencer, no partitioning.** This caps write throughput at what one
machine can do. That is the cost of total order, and total order is the
product. Partitioning would make this Kafka.

**Subscribers own their offsets.** The server tracks no per-consumer state.
A subscriber asks for `from_seq = N` and gets everything from there. This
makes replay, catch-up, and crash recovery the same code path.

**The transport never deserializes payloads.** A message is opaque bytes.
The moment the sequencer understands what a "withdraw" is, this stops being a
transport.

**Blocking `Unix` I/O for v0.1.** Simpler to get correct than Eio, and the
sequencer's hot loop is single-threaded anyway. An Eio backend is plausible for
v0.2 once the semantics are pinned down.

**Durability is a caller's choice.** `add` acks from the in-memory buffer by
default; an explicit durable mode waits for fsync. The gap between those two is
the single most interesting number this project can produce, and M4 exists to
measure it.

## Known limits

- Write throughput is bounded by one sequencer.
- Total order holds within one sequencer's domain. There is no cross-datacenter
  ordering, and there will not be — the speed of light makes a globally ordered
  low-latency log impossible, not merely difficult.
- Default `add` acks before fsync. A simultaneous loss of the sequencer and all
  replicas can lose acknowledged messages. M6 replication narrows that window;
  it does not close it.
- `apply` must be deterministic. Clocks, randomness, and I/O inside the state
  machine break replay. The library cannot enforce this.

## Testing strategy

The ordering guarantees are the product, so they get property tests rather than
examples: generate random concurrent producer and subscriber schedules, then
assert that every subscriber observed a prefix of one single sequence, with no
gaps, no duplicates, and no reordering. (M7.)
