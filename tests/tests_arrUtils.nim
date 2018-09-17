import unittest
import redux_nim/arrUtils

suite "Arr utils tests":

    setup:
        let sequence = @[1, 2, 3, 4]
        let arr = [1, 2, 3]

    test "it should loop and iterable and apply de cb to each element":
        var seqtmp = ""

        sequence.forEach do (v: int, k: int) -> void:
            seqtmp.add(v)
            seqtmp.add(k)

        var arrtmp = ""

        arr.forEach do (v: int, k: int) -> void:
            arrtmp.add(v)
            arrtmp.add(k)

        check seqtmp == "10213243"
        check arrtmp == "102132"


