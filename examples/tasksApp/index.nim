import redux_nim
import redux_nim/arrUtils
import strformat
import ./models/Task
import parseutils
import sequtils

type
    AppState = ref object
        tasks: seq[Task]

    AddTaskAction = ref object of ReduxAction
        payload: Task

    RemoveTaskAction = ref object of ReduxAction
        payload: int

    UpdateTaskAction = ref object of ReduxAction
        payload: tuple[prevTask: Task, newTaskText: string]



let tasksReducer: ReduxReducer[AppState] = proc (state: AppState, action: ReduxAction): AppState =

    if action of AddTaskAction:
        state.tasks.add(AddTaskAction(action).payload)
        return AppState(tasks: state.tasks)

    if action of RemoveTaskAction:
        state.tasks.delete(RemoveTaskAction(action).payload)
        return AppState(tasks: state.tasks)

    if action of UpdateTaskAction:
        let tasks = state.tasks.map do (t: Task) -> Task:
            if t.text == UpdateTaskAction(action).payload.prevTask.text:
                return Task(text: UpdateTaskAction(action).payload.newTaskText)

            return t

        return AppState(tasks: tasks)

    return state


let store = newReduxStore[AppState](tasksReducer, AppState(tasks: @[]));

proc printTasks(tasks: seq[Task]) =
    echo("Tasks:")
    tasks.forEach do (t: Task, k: int) -> void: echo(&"Task#{k}: {t.text}")
    echo("")

proc newTask() =
    var task = Task()

    stdout.write("Task text:")
    let txt = stdin.readLine()
    task.text = txt

    store.dispatch(AddTaskAction(payload: task))
    echo("saved")

proc printMenu() =
    echo("1 - Add task")
    echo("2 - Remove Task")
    echo("3 - Update Task")
    echo("4 - List Tasks")
    echo("0 - Exit")
    echo("")

proc removeTask() =
    var op: int

    printTasks(store.getState().tasks)

    stdout.write("Task num: ")
    discard parseInt(stdin.readLine(), op)

    if op > store.getState().tasks.len() - 1 or op < 0:
        echo("Opção invalida")
        return

    store.dispatch(RemoveTaskAction(payload: op))
    echo("removed")

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

    store.dispatch(UpdateTaskAction(
        payload: (
            prevTask: prevTask,
            newTaskText: if textNewTask == "-1": prevTask.text else: textNewTask
        )
    ))

    echo("updated")

let sub = store.subscribe do () -> void:
    echo("From sub:")
    printTasks(store.getState().tasks)

var op = ""

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
