proc forEach*[T](s: openArray[T], fn: proc(v: T, k: int): void): void =
    for i in 0..<s.len():
        fn(s[i], i)
