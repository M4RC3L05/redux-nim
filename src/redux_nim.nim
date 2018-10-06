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

    ReduxMiddleware*[T] = proc(store: ReduxStore[T]): proc(next: proc(store: ReduxStore[T], action: ReduxAction): void): proc(action: ReduxAction): ReduxAction

proc newReduxStore*[T](reducer: ReduxReducer[T]): ReduxStore[T]
proc newReduxStore*[T](reducer: ReduxReducer[T], initialState: T): ReduxStore[T]
proc newReduxStore*[T](reducer: ReduxReducer[T], initialState: T, middlewares: seq[ReduxMiddleware[T]]): ReduxStore[T]
proc getState*[T](store: ReduxStore[T]): T
proc subscribe*[T](store: ReduxStore[T], fn: ReduxSubscription): ReduxUnsubscription
proc unsubscribe*[T](store: ReduxStore[T], id: int): void
proc notify[T](store: ReduxStore[T]): void
proc dispatch*[T](store: ReduxStore[T], action: ReduxAction): ReduxAction
proc innerDispatch[T](store: ReduxStore[T], action: ReduxAction): void

proc newReduxStore*[T](reducer: ReduxReducer[T]): ReduxStore[T] =
    ## Creates a new redux store of a given type

    var localStore = ReduxStore[T](reducer: reducer)
    discard localStore.dispatch(INITReduxAction())
    return localStore

proc newReduxStore*[T](reducer: ReduxReducer[T], initialState: T): ReduxStore[T] =
    ## Creates a new redux store of a given type

    var localStore = ReduxStore[T](reducer: reducer, state: initialState)
    discard localStore.dispatch(INITReduxAction())
    return localStore

proc newReduxStore*[T](reducer: ReduxReducer[T], initialState: T, middlewares: seq[ReduxMiddleware[T]]): ReduxStore[T] =
    ## Creates a new redux store of a given type

    var localStore = ReduxStore[T](reducer: reducer, state: initialState)
    let goodStateMiddles = map(middlewares, proc(m: ReduxMiddleware[T]): proc(action: ReduxAction): ReduxAction = m(localStore)(innerDispatch))
    localStore.middlewares = goodStateMiddles
    discard localStore.dispatch(INITReduxAction())
    return localStore

proc getState*[T](store: ReduxStore[T]): T =
    ## Returns the state of the store

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

    if store.middlewares.len <= 0:
        store.innerDispatch(action)
        return action
    else:
        let actionCompose = compose(store.middlewares)(action)
        return actionCompose

proc innerDispatch[T](store: ReduxStore[T], action: ReduxAction): void =
    store.state = store.reducer(state = store.state, action = action)
    store.notify()

proc notify[T](store: ReduxStore[T]): void =
    store.subscriptions.forEach do (v: proc(): void, k: int) -> void: v()
