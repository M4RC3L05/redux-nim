import unittest

import redux_nim

suite "Redux Tests":

    setup:
        type User = object
            name: string

        let model = User(name: "João")

        let userReducer: ReduxReducer[User] = proc(state: User = model, action: ReduxAction[User]): User =
            case action.action:
                of "CHNAGE_NAME":
                    return User(name: action.payload.name)

                else:
                    return state

        let store = newReduxStore[User](userReducer, model)

    test "It should create a new Redux Store":

        check(store.getState() == model)

    test "It should notify when new actions is dispatched":


        let changeUserNameAction = ReduxAction[User](action: "CHNAGE_NAME", payload: User(name:"Ana"))

        let sub = store.subscribe do () -> void:
            check(store.getState().name == "Ana")

        store.dispatch(changeUserNameAction)
        sub()

    test "it Should unsubscribe from subscription":
        var tmp = ""

        let changeUserNameAction = ReduxAction[User](action: "CHNAGE_NAME", payload: User(name:"Ana"))

        let sub = store.subscribe do () -> void:
            tmp.add(store.getState().name)

        store.dispatch(changeUserNameAction)
        sub()
        store.dispatch(changeUserNameAction)

        check(tmp == "Ana")

