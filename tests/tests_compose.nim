import unittest
import redux_nim/compose

suite "Compose Tests":

    setup:
        proc addOne(): proc(x: int): int=
            return proc(x: int): int=
                return x + 1

        proc multiplyTwo(): proc(x: int): int=
            return proc(x: int): int=
                return x * 2

        proc subtractThree(): proc(x: int): int=
            return proc(x: int): int=
                return x - 3

        proc addFour(): proc(x: int): int=
            return proc(x: int): int=
                return x + 4

    test "it should compose closure functions":
        let res = compose[int](
            @[addOne(),
            multiplyTwo(),
            subtractThree(),
            addFour()]
        )(0)

        check(res == 3)
