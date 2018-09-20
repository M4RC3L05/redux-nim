import unittest
import strformat

import redux_nim

suite "Redux Tests":

    setup:
        type User = ref object of RootObj
            name: string

        proc `$`(user: User): string = &"User: {user.name}"

        type
            ChangeUserNameAction = ref object of ReduxAction
                payload: string

        let initState = User(name: "João")

        let userReducer: ReduxReducer[User] = proc(state: User = initState, action: ReduxAction): User =

            if action of ChangeUserNameAction:
                return User(name: ChangeUserNameAction(action).payload)

            else:

                return if state != nil: state else: initState

        let store = newReduxStore[User](userReducer)

    test "It should create a new Redux Store":
        let store1 = newReduxStore[User](userReducer)
        check(store1.getState() == initState)

    test "It should notify when new actions is dispatched":


        let changeUserNameAction = ChangeUserNameAction(payload: "Ana")

        let sub = store.subscribe do () -> void:
            check(store.getState().name == "Ana")

        store.dispatch(changeUserNameAction)
        sub()

    test "it Should unsubscribe from subscription":
        var tmp = ""

        let changeUserNameAction = ChangeUserNameAction(payload: "Ana")

        let sub = store.subscribe do () -> void:
            tmp.add("s1" & store.getState().name)

        let sub2 = store.subscribe do () -> void:
            tmp.add("s2" & store.getState().name)

        store.dispatch(changeUserNameAction)
        sub2()
        store.dispatch(changeUserNameAction)
        sub()
        store.dispatch(changeUserNameAction)

        check(tmp == "s1Anas2Anas1Ana")

