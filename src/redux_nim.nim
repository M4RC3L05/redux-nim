import redux_nim/arrUtils
import sequtils, strformat

type
    ReduxSubscription = proc(): void

    ReduxUnsubscription = proc(): void

    ReduxAction* = ref object of RootObj

    ReduxReducer*[T] = proc(state: T, action: ReduxAction): T

    INITReduxAction = ref object of ReduxAction


    ReduxStore*[T] = ref object
        state*: T
        reducer*: ReduxReducer[T]
        subscriptions*: seq[ReduxSubscription]

proc newReduxStore*[T](reducer: ReduxReducer[T]): ReduxStore[T]
proc newReduxStore*[T](reducer: ReduxReducer[T], initialState: T): ReduxStore[T]
proc getState*[T](store: ReduxStore[T]): T
proc subscribe*[T](store: ReduxStore[T], fn: ReduxSubscription): ReduxUnsubscription
proc unsubscribe*[T](store: ReduxStore[T], id: int): void
proc notify[T](store: ReduxStore[T]): void
proc dispatch*[T](store: ReduxStore[T], action: ReduxAction): void

proc newReduxStore*[T](reducer: ReduxReducer[T]): ReduxStore[T] =
    result = ReduxStore[T](reducer: reducer)
    result.dispatch(INITReduxAction())

proc newReduxStore*[T](reducer: ReduxReducer[T], initialState: T): ReduxStore[T] =
    result = ReduxStore[T](reducer: reducer, state: initialState)
    result.dispatch(INITReduxAction())

proc getState*[T](store: ReduxStore[T]): T = store.state

proc subscribe*[T](store: ReduxStore[T], fn: ReduxSubscription): ReduxUnsubscription =
    store.subscriptions.add(fn)
    let currSubId = store.subscriptions.len() - 1
    result = proc(): void = store.subscriptions.delete(currSubId)

proc unsubscribe*[T](store: ReduxStore[T], id: int): void =
    store.subscriptions.delete(id)

proc dispatch*[T](store: ReduxStore[T], action: ReduxAction): void =
    store.state = store.reducer(state = store.state, action = action)
    store.notify()

proc notify[T](store: ReduxStore[T]): void =
    store.subscriptions.forEach do (v: proc(): void, k: int) -> void: v()
