type t = {
    mutable data : string array;
    mutable count : int;
}

let create () = 
    { data = Array.make 16 ""; count = 0 }

let add t payload = 
    if t.count = Array.length t.data then begin
        let bigger = Array.make (2 * Array.length t.data) "" in
        Array.blit t.data 0 bigger 0 t.count;
        t.data <- bigger
    end;
    t.data.(t.count) <- payload;
    t.count <- t.count + 1;
    t.count 

let read t n = 
    match n with 
    | _ when n < 1 || n > t.count -> None
    | _ -> Some t.data.(n - 1)

let length t = 
    t.count