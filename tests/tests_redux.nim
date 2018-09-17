import unittest

import redux_nim

suite "Redux Tests":

    setup:
        type User = object
            name: string

        type
            ChangeUserNameAction = ref object of ReduxAction
                payload: string

        let model = User(name: "João")

        let userReducer: ReduxReducer[User] = proc(state: User = model, action: ReduxAction): User =
            if action of ChangeUserNameAction:
                return User(name: ChangeUserNameAction(action).payload)

            else:
                return state



        let store = newReduxStore[User](userReducer, model)

    test "It should create a new Redux Store":

        check(store.getState() == model)

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
            tmp.add(store.getState().name)

        store.dispatch(changeUserNameAction)
        sub()
        store.dispatch(changeUserNameAction)

        check(tmp == "Ana")

