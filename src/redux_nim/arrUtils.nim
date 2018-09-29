proc forEach*[T](s: openArray[T], fn: proc(v: T, k: int): void): void =
    ## apply to every element of the given iterable the closure provided

    for i in 0..<s.len():
        fn(s[i], i)
