import redux_nim/arrUtils
import redux_nim/compose
import sequtils, strformat, typetraits

type
    ReduxSubscription* = proc(): void ## The type of a redux subscription

    ReduxUnsubscription* = proc(): void ## The type of a redux subscription

    ReduxAction* = ref object of RootObj ## The type of a redux action

    ReduxReducer*[T] = proc(state: T, action: ReduxAction): T ## The type of a redux reducer

    INITReduxAction = ref object of ReduxAction

    ReduxStore*[T] = ref object ## The type of a redux store
        state: T
        reducer: ReduxReducer[T]
        subscriptions: seq[ReduxSubscription]
        middlewares: seq[proc(action: ReduxAction): ReduxAction]
        isDispatching: bool

    ReduxMiddleware*[T] = proc(store: ReduxStore[T]): proc(next: proc(store: ReduxStore[T], action: ReduxAction): ReduxAction): proc(action: ReduxAction): ReduxAction ## The type of a redux middleware

    ReduxInDispatchingProcessError* = object of Exception ## The type of a redux dispatch in progress error
    ReduxDispatchProcessError* = object of Exception ## The type of a redux dispatch error

proc newReduxStore*[T](reducer: ReduxReducer[T]): ReduxStore[T]
proc newReduxStore*[T](reducer: ReduxReducer[T], initialState: T): ReduxStore[T]
proc newReduxStore*[T](reducer: ReduxReducer[T], initialState: T, middlewares: seq[ReduxMiddleware[T]]): ReduxStore[T]
proc getState*[T](store: ReduxStore[T]): T {.raises: [ReduxInDispatchingProcessError].}
proc subscribe*[T](store: ReduxStore[T], fn: ReduxSubscription): ReduxUnsubscription
proc unsubscribe*[T](store: ReduxStore[T], id: int): void
proc notify[T](store: ReduxStore[T]): void
proc dispatch*[T](store: ReduxStore[T], action: ReduxAction): ReduxAction {.raises: [ReduxInDispatchingProcessError, ReduxDispatchProcessError].}
proc innerDispatch[T](store: ReduxStore[T], action: ReduxAction): ReduxAction

proc newReduxStore*[T](reducer: ReduxReducer[T]): ReduxStore[T] =
    ## Creates a new redux store of a given type

    var localStore = ReduxStore[T](reducer: reducer, isDispatching: false)
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

proc getState*[T](store: ReduxStore[T]): T {.raises: [ReduxInDispatchingProcessError].} =
    ## Returns the state of the store

    if store.isDispatching:
        raise newException(ReduxInDispatchingProcessError, "You cannot get state while the dispatch is in progress!")

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

proc dispatch*[T](store: ReduxStore[T], action: ReduxAction): ReduxAction {.raises: [ReduxInDispatchingProcessError, ReduxDispatchProcessError].} =
    ## Dispatches an action to the reducer, so that the reducer
    ## produces the new state

    if store.isDispatching:
        raise newException(ReduxInDispatchingProcessError, "You cannot dispatch on reducers!")

    try:
        if store.middlewares.len <= 0:
            return store.innerDispatch(action)

        else:
            return compose(store.middlewares)(action)

    except Exception:
        raise newException(ReduxDispatchProcessError, "An error ocurr when you try to dispatch and action")

proc innerDispatch[T](store: ReduxStore[T], action: ReduxAction): ReduxAction {.raises: [ReduxInDispatchingProcessError, ReduxDispatchProcessError].} =

    if store.isDispatching:
        raise newException(ReduxInDispatchingProcessError, "You cannot dispatch on reducers!")

    try:
        store.isDispatching = true
        store.state = store.reducer(state = store.state, action = action)

    except Exception:
        raise newException(ReduxDispatchProcessError, "An error ocurr when you try to dispatch and action")

    finally:
        store.isDispatching = false

    store.notify()
    return action

proc notify[T](store: ReduxStore[T]): void =
    store.subscriptions.forEach do (v: proc(): void, k: int) -> void: v()
