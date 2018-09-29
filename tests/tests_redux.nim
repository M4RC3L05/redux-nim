import unittest
import strformat

import redux_nim

suite "Redux Tests":

    setup:
        type User = ref object
            name: string


        proc `$`(user: User): string =
            return &"User: {user.name}"

        type
            ChangeUserNameAction = ref object of ReduxAction
                payload: string

        let initState = User(name: "João")

        let userReducer: ReduxReducer[User] = proc(state: User = initState, action: ReduxAction): User =

            if action of ChangeUserNameAction:
                return User(name: ChangeUserNameAction(action).payload)

            return if state != nil: state else: initState

        let store = newReduxStore[User](userReducer)

    test "It should create a new Redux Store":
        let store1 = newReduxStore[User](userReducer)
        check(store1.getState() == initState)

    test "It should notify when new actions is dispatched":


        let changeUserNameAction = ChangeUserNameAction(payload: "Ana")

        let sub = store.subscribe do () -> void:
            check(store.getState().name == "Ana")

        discard store.dispatch(changeUserNameAction)
        sub()

    test "it Should unsubscribe from subscription":
        var tmp = ""

        let changeUserNameAction = ChangeUserNameAction(payload: "Ana")

        let sub = store.subscribe do () -> void:
            tmp.add("s1" & store.getState().name)

        let sub2 = store.subscribe do () -> void:
            tmp.add("s2" & store.getState().name)

        discard store.dispatch(changeUserNameAction)
        sub2()
        discard store.dispatch(changeUserNameAction)
        sub()
        discard store.dispatch(changeUserNameAction)

        check(tmp == "s1Anas2Anas1Ana")


    test "it should apply middlewares":
        var tmp: string = ""

        let loggerMiddleware: ReduxMiddleware[User] = proc(store: ReduxStore[User]): proc(next: proc(store: ReduxStore[User], action: ReduxAction): void): proc(action: ReduxAction): ReduxAction =
            return proc(next: proc(store: ReduxStore[User], action: ReduxAction): void): proc(action: ReduxAction): ReduxAction =
                return proc(action: ReduxAction): ReduxAction =
                    tmp.add(&"Before: {store.getState()}")
                    next(store, action)
                    tmp.add(&"After: {store.getState()}")
                    return action



        let store2 = newReduxStore[User](userReducer, initState, @[loggerMiddleware])
        discard store2.dispatch(ChangeUserNameAction(payload: "Ana"))

        check(tmp == "Before: User: JoãoAfter: User: JoãoBefore: User: JoãoAfter: User: Ana")
