import redux_nim/arrUtils
import redux_nim/compose
import sequtils, strformat

type
    ReduxSubscription = proc(): void

    ReduxUnsubscription = proc(): void

    ReduxAction* = ref object of RootObj

    ReduxReducer*[T] = proc(state: T, action: ReduxAction): T

    # ReduxMiddleware* = proc[T](store: ReduxStore[T]): proc(action: ReduxAction): proc(next: proc[T](store: ReduxStore[T], action: ReduxAction): void): ReduxAction

    INITReduxAction = ref object of ReduxAction

    ReduxStore*[T] = ref object
        state: T
        reducer: ReduxReducer[T]
        subscriptions: seq[ReduxSubscription]
        middlewares: seq[proc(action: ReduxAction): ReduxAction]

    ReduxMiddleware*[T] = proc(store: ReduxStore[T]): proc(next: proc(store: ReduxStore[T], action: ReduxAction): void): proc(action: ReduxAction): ReduxAction

proc newReduxStore*[T](reducer: ReduxReducer[T]): ReduxStore[T]
proc newReduxStore*[T](reducer: ReduxReducer[T], initialState: T): ReduxStore[T]
proc newReduxStore*[T](reducer: ReduxReducer[T], initialState: T, middlewares: seq[proc(action: ReduxAction): ReduxAction]): ReduxStore[T]
proc getState*[T](store: ReduxStore[T]): T
proc subscribe*[T](store: ReduxStore[T], fn: ReduxSubscription): ReduxUnsubscription
proc unsubscribe*[T](store: ReduxStore[T], id: int): void
proc notify[T](store: ReduxStore[T]): void
proc dispatch*[T](store: ReduxStore[T], action: ReduxAction): void
proc innerDispatch[T](store: ReduxStore[T], action: ReduxAction): void

proc newReduxStore*[T](reducer: ReduxReducer[T]): ReduxStore[T] =
    result = ReduxStore[T](reducer: reducer)
    result.dispatch(INITReduxAction())

proc newReduxStore*[T](reducer: ReduxReducer[T], initialState: T): ReduxStore[T] =
    result = ReduxStore[T](reducer: reducer, state: initialState)
    result.dispatch(INITReduxAction())

proc newReduxStore*[T](reducer: ReduxReducer[T], initialState: T, middlewares: seq[proc(action: ReduxAction): ReduxAction]): ReduxStore[T] =
    result = ReduxStore[T](reducer: reducer, state: initialState, middlewares: middlewares)
    result.dispatch(INITReduxAction())

proc getState*[T](store: ReduxStore[T]): T = store.state

proc subscribe*[T](store: ReduxStore[T], fn: ReduxSubscription): ReduxUnsubscription =
    store.subscriptions.add(fn)
    let currSubId = store.subscriptions.len() - 1
    result = proc(): void = store.subscriptions.delete(currSubId)

proc unsubscribe*[T](store: ReduxStore[T], id: int): void =
    store.subscriptions.delete(id)

proc dispatch*[T](store: ReduxStore[T], action: ReduxAction): void =
    if store.middlewares.len <= 0:
        store.innerDispatch(action)
    else:
        let middleCompose = compose[ReduxAction](store.middlewares)(action)
        discard

proc innerDispatch[T](store: ReduxStore[T], action: ReduxAction): void =
    store.state = store.reducer(state = store.state, action = action)
    store.notify()

proc notify[T](store: ReduxStore[T]): void =
    store.subscriptions.forEach do (v: proc(): void, k: int) -> void: v()


let loggerMiddleware: ReduxMiddleware[int] = proc(store: ReduxStore[int]): proc(next: proc(store: ReduxStore[int], action: ReduxAction): void): proc(action: ReduxAction): ReduxAction =
    return proc(next: proc(store: ReduxStore[int], action: ReduxAction): void): proc(action: ReduxAction): ReduxAction =
        return proc(action: ReduxAction): ReduxAction =
            echo("After: ", store.getState())
            next(store, action)
            echo("Before: ", store.getState())
            return action

type
    PlusReduxAction = ref object of ReduxAction
        payload: int

let reducer: ReduxReducer[int] = proc(state: int = 0, action: ReduxAction): int =
    return state

let store = newReduxStore[int](reducer, 0)
store.middlewares.add(loggerMiddleware(store)(innerDispatch))

let sub = store.subscribe do () -> void:
    echo("STATE: ", store.getState())


store.dispatch(PlusReduxAction(payload: 1))
