import redux_nim/arrUtils

type ReduxSubscription = proc(): void
type ReduxUnsubscription = proc(): void
type ReduxAction* = ref object of RootObj
type ReduxReducer*[T] = proc(state: T, action: ReduxAction): T

type ReduxStore*[T] = ref object
    state*: T
    reducer*: proc(state: T, action: ReduxAction): T
    subscriptions*: seq[proc(): void]

proc newReduxStore*[T](reducer: ReduxReducer[T], initialState: T): ReduxStore[T]
proc getState*[T](store: ReduxStore[T]): T
proc subscribe*[T](store: ReduxStore[T], fn: ReduxSubscription): ReduxUnsubscription
proc unsubscribe*[T](store: ReduxStore[T], id: int): void
proc notify[T](store: ReduxStore[T]): void
proc dispatch*[T](store: ReduxStore[T], action: ReduxAction): void

proc newReduxStore*[T](reducer: ReduxReducer[T], initialState: T): ReduxStore[T] =
    result = ReduxStore[T](reducer: reducer, state: initialState)

proc getState*[T](store: ReduxStore[T]): T = store.state

proc subscribe*[T](store: ReduxStore[T], fn: ReduxSubscription): ReduxUnsubscription =
    store.subscriptions.add(fn)
    let currSubId = store.subscriptions.len() - 1
    result = proc(): void = store.subscriptions.delete(currSubId)

proc unsubscribe*[T](store: ReduxStore[T], id: int): void =
    store.subscriptions.delete(id)

proc dispatch*[T](store: ReduxStore[T], action: ReduxAction): void =
    store.state = store.reducer(store.state, action)
    store.notify()

proc notify[T](store: ReduxStore[T]): void =
    store.subscriptions.forEach do (v: proc(): void, k: int) -> void: v()
