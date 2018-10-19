import redux_nim/arrUtils
import redux_nim/compose
import sequtils, strformat, typetraits

type
    ReduxSubscription* = proc(): void

    ReduxUnsubscription* = proc(): void

    ReduxAction* = ref object of RootObj

    ReduxReducer*[T] = proc(state: T, action: ReduxAction): T

    INITReduxAction = ref object of ReduxAction

    ReduxStore*[T] = ref object
        state: T
        reducer: ReduxReducer[T]
        subscriptions: seq[ReduxSubscription]
        middlewares: seq[proc(action: ReduxAction): ReduxAction]
        isDispatching: bool

    ReduxMiddleware*[T] = proc(store: ReduxStore[T]): proc(next: proc(store: ReduxStore[T], action: ReduxAction): ReduxAction): proc(action: ReduxAction): ReduxAction

    InDispatchingProcessError* = object of Exception

proc newReduxStore*[T](reducer: ReduxReducer[T]): ReduxStore[T]
proc newReduxStore*[T](reducer: ReduxReducer[T], initialState: T): ReduxStore[T]
proc newReduxStore*[T](reducer: ReduxReducer[T], initialState: T, middlewares: seq[ReduxMiddleware[T]]): ReduxStore[T]
proc getState*[T](store: ReduxStore[T]): T {.raises: [InDispatchingProcessError].}
proc subscribe*[T](store: ReduxStore[T], fn: ReduxSubscription): ReduxUnsubscription
proc unsubscribe*[T](store: ReduxStore[T], id: int): void
proc notify[T](store: ReduxStore[T]): void
proc dispatch*[T](store: ReduxStore[T], action: ReduxAction): ReduxAction
proc innerDispatch[T](store: ReduxStore[T], action: ReduxAction): ReduxAction

proc newReduxStore*[T](reducer: ReduxReducer[T]): ReduxStore[T] =
    ## Creates a new redux store of a given type

    var localStore = ReduxStore[T](reducer: reducer, isDispatching: false, middlewares: @[])
    discard localStore.dispatch(INITReduxAction())
    return localStore

proc newReduxStore*[T](reducer: ReduxReducer[T], initialState: T): ReduxStore[T] =
    ## Creates a new redux store of a given type

    var localStore = ReduxStore[T](reducer: reducer, state: initialState, isDispatching: false, middlewares: @[])
    discard localStore.dispatch(INITReduxAction())
    return localStore

proc newReduxStore*[T](reducer: ReduxReducer[T], initialState: T, middlewares: seq[ReduxMiddleware[T]]): ReduxStore[T] =
    ## Creates a new redux store of a given type

    var localStore = ReduxStore[T](reducer: reducer, state: initialState, isDispatching: false)
    localStore.middlewares = map(middlewares, proc(m: ReduxMiddleware[T]): proc(action: ReduxAction): ReduxAction = m(localStore)(innerDispatch))
    discard localStore.dispatch(INITReduxAction())
    return localStore

proc getState*[T](store: ReduxStore[T]): T {.raises: [InDispatchingProcessError].} =
    ## Returns the state of the store

    if store.isDispatching:
        raise newException(InDispatchingProcessError, "You cannot get state while the dispatch is in progress!")

    return store.state

proc subscribe*[T](store: ReduxStore[T], fn: ReduxSubscription): ReduxUnsubscription =
    ## Subscribe to changes on the store, to be notified of
    ## It returns an unsubscription closure to unsubscribe to
    ## the store

    store.subscriptions.add(fn)
    let currSubId = store.subscriptions.len() - 1
    result = proc(): void = store.subscriptions.delete(currSubId)

proc unsubscribe*[T](store: ReduxStore[T], id: int): void =
    ## Unsubscribes from the store

    store.subscriptions.delete(id)

proc dispatch*[T](store: ReduxStore[T], action: ReduxAction): ReduxAction =
    ## Dispatches an action to the reducer, so that the reducer
    ## produces the new state

    if store.isDispatching:
        raise newException(InDispatchingProcessError, "You cannot dispatch on reducers!")

    if store.middlewares.len <= 0:
        return store.innerDispatch(action)
    else:
        return compose(store.middlewares)(action)

proc innerDispatch[T](store: ReduxStore[T], action: ReduxAction): ReduxAction =

    if store.isDispatching:
        raise newException(InDispatchingProcessError, "You cannot dispatch on reducers!")

    try:
        store.isDispatching = true
        store.state = store.reducer(state = store.state, action = action)
    finally:
        store.isDispatching = false

    store.notify()
    return action

proc notify[T](store: ReduxStore[T]): void =
    store.subscriptions.forEach do (v: proc(): void, k: int) -> void: v()
