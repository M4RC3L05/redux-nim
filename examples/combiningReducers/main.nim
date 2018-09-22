import ./../../src/redux_nim
import sequtils, strformat

type
    AppState = object
        name: string
        hobbies: seq[string]

    ChangeNameAction = ref object of ReduxAction
        payload: string

    AddHobbieAction = ref object of ReduxAction
        payload: string

proc `$`(appState: AppState): string =
    let hobsstr = appState.hobbies.foldl(a & "\n")
    return &"State: \n name: {appState.name}\n hobbies: {hobsstr}"

let nameReducer: ReduxReducer[string] = proc(state: string, action: ReduxAction): string =

    if action of ChangeNameAction:
        return ChangeNameAction(action).payload

    return state

let hobbiesReducer: ReduxReducer[seq[string]] = proc(state: seq[string], action: ReduxAction): seq[string] =

    if action of AddHobbieAction:
        return state.concat(@[AddHobbieAction(action).payload])

    return state

let initSate = AppState(name: "", hobbies: @[])


let rootReducer: ReduxReducer[AppState] = proc(state: AppState, action: ReduxAction): AppState =
    return AppState(
        name: nameReducer(state.name, action),
        hobbies: hobbiesReducer(state.hobbies, action)
    )


let store = newReduxStore[AppState](rootReducer)

discard store.subscribe do () -> void: echo(store.getState())

store.dispatch(AddHobbieAction(payload: "Run"))
store.dispatch(ChangeNameAction(payload: "João"))
