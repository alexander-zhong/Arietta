type t = {
    mutable data : string array;
    mutable count : int;
    lock : Mutex.t;
    changed: Condition.t;
}

let create () = 
    { data = Array.make 16 ""; count = 0; lock = Mutex.create (); changed = Condition.create () }

let add t payload = 
    Mutex.protect t.lock (fun() -> 
    if t.count = Array.length t.data then begin
        let bigger = Array.make (2 * Array.length t.data) "" in
        Array.blit t.data 0 bigger 0 t.count;
        t.data <- bigger
    end;
    t.data.(t.count) <- payload;
    t.count <- t.count + 1;
    Condition.broadcast t.changed;
    t.count)

let read t n = 
    Mutex.protect t.lock (fun () ->
    match n with 
    | _ when n < 1 || n > t.count -> None
    | _ -> Some t.data.(n - 1))

let length t = 
    Mutex.protect t.lock (fun() -> t.count)

let wait_read t n = 
    Mutex.protect t.lock (fun () -> 
        while t.count < n do
            Condition.wait t.changed t.lock
        done;
        t.data.(n - 1))

let subscribe t ~from_seq = 
    let rec go n () = 
        Seq.Cons ((n, wait_read t n), go (n + 1))
    in 
    go from_seq