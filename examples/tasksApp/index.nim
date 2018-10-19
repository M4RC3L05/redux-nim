import ./../../src/redux_nim
import ./../../src/redux_nim/arrUtils
import strformat
import ./models/Task
import parseutils
import sequtils


# SOME TYPES FOR THIS APP
type
    # STATE TYPE
    AppState = ref object
        tasks: seq[Task]

    # ACTIONS TYPES THAT WILL BE DISPATCHES TO THE REDUCER
    # SO THAT THE STATE IS UPDATE
    AddTaskAction = ref object of ReduxAction
        payload: Task

    RemoveTaskAction = ref object of ReduxAction
        payload: Task

    UpdateTaskAction = ref object of ReduxAction
        payload: tuple[prevTask: Task, newTaskText: string]
    # END OF ACTION TYPES


# CREATE THE REDUCER, THAT IS RESPONSIBLE FOR RETURN THE
# UPDATED STATE, GIVEN THE ACTION
let initState = AppState(tasks: @[])

let tasksReducer: ReduxReducer[AppState] = proc (state: AppState, action: ReduxAction): AppState =

    if action of AddTaskAction:
        var tasks = state.tasks.cycle(1)
        tasks.add(AddTaskAction(action).payload)
        return AppState(tasks: tasks)

    if action of RemoveTaskAction:
        let newTasks = state.tasks.filter do (t: Task) -> bool : t.text != RemoveTaskAction(action).payload.text
        return AppState(tasks: newTasks)

    if action of UpdateTaskAction:
        let tasks = state.tasks.map do (t: Task) -> Task:
            if t.text == UpdateTaskAction(action).payload.prevTask.text:
                return Task(text: UpdateTaskAction(action).payload.newTaskText)

            return t

        return AppState(tasks: tasks)

    return if state != nil: state else: initState

# CREATE THE STORE
let store = newReduxStore[AppState](tasksReducer);

# PROCEDURE TO PRINT ALL TASKS IN STATE
proc printTasks(tasks: seq[Task]) =
    echo("Tasks:")
    tasks.forEach do (t: Task, k: int) -> void: echo(&"Task#{k}: {t.text}")
    echo("")


# PROCEDURE TO CREATE AND DISPATCH THE CREATED TASK
proc newTask() =
    var task = Task()

    stdout.write("Task text:")
    let txt = stdin.readLine()
    task.text = txt

    discard store.dispatch(AddTaskAction(payload: task))
    echo("saved")

# PROCEDURE TO PRINT THE APPLICATION MENU
proc printMenu() =
    echo("1 - Add task")
    echo("2 - Remove Task")
    echo("3 - Update Task")
    echo("4 - List Tasks")
    echo("0 - Exit")
    echo("")

# PROCEDURE TO REMOVE AND DISPATCH A GIVEN TASK
proc removeTask() =
    var op: int

    printTasks(store.getState().tasks)

    stdout.write("Task num: ")
    discard parseInt(stdin.readLine(), op)

    if op > store.getState().tasks.len() - 1 or op < 0:
        echo("Opção invalida")
        return

    discard store.dispatch(RemoveTaskAction(payload: store.getState().tasks[op]))
    echo("removed")

# PROCEDURE TO UPDATE AND DISPATCH A GIVEN TASK
proc updateTask() =
    var op: int

    printTasks(store.getState().tasks)

    stdout.write("Task num: ")
    discard parseInt(stdin.readLine(), op)

    if op > store.getState().tasks.len() - 1 or op < 0:
        echo("Opção invalida")
        return

    stdout.write("Task text(-1 to not change): ")
    let textNewTask = stdin.readLine()

    let prevTask = store.getState().tasks[op]

    discard store.dispatch(UpdateTaskAction(
        payload: (
            prevTask: prevTask,
            newTaskText: if textNewTask == "-1": prevTask.text else: textNewTask
        )
    ))

    echo("updated")

# SUBESCRIPTION TO THE STORE SO THAT WE CAN BE NOTIFIED
# WHEN UPDATES OCURR TO THE STORE
let sub = store.subscribe do () -> void:
    echo("From sub:")
    printTasks(store.getState().tasks)

var op = ""

# MAIN LOOP OF THE APLICATION
while true:
    printMenu()
    stdout.write("Opção: ")
    op = stdin.readLine()

    case op:
        of "0":
            sub()
            quit()

        of "1":
            newTask()

        of "2":
            removeTask()

        of "3":
            updateTask()

        of "4":
            printTasks(store.getState().tasks)

        else:
            echo("Not a valid option!")
