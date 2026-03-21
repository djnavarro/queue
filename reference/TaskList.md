# R6 Class Representing a Task List

A `TaskList` stores and retrieves one or more tasks.

## Details

The `TaskList` class is used as a storage class. It provides a container
that holds a collection of `Task` objects, along with a collection of
methods for adding, removing, and getting `Task`s. It can also report on
the status of the `Task`s contained within the list and retrieve results
from those `Task`s. What it cannot do is manage interactions with
`Worker`s or arrange for the `Task`s to be executed. That's the job of
the `Queue`.

## Methods

### Public methods

- [`TaskList$new()`](#method-TaskList-new)

- [`TaskList$length()`](#method-TaskList-length)

- [`TaskList$add_task()`](#method-TaskList-add_task)

- [`TaskList$remove_task()`](#method-TaskList-remove_task)

- [`TaskList$get_task()`](#method-TaskList-get_task)

- [`TaskList$get_state()`](#method-TaskList-get_state)

- [`TaskList$get_tasks_in_state()`](#method-TaskList-get_tasks_in_state)

- [`TaskList$retrieve()`](#method-TaskList-retrieve)

- [`TaskList$clone()`](#method-TaskList-clone)

------------------------------------------------------------------------

### Method `new()`

Create a new task list

#### Usage

    TaskList$new()

------------------------------------------------------------------------

### Method [`length()`](https://rdrr.io/r/base/length.html)

Return the number of tasks in the list

#### Usage

    TaskList$length()

#### Returns

Integer

------------------------------------------------------------------------

### Method `add_task()`

Add a task to the `TaskList`

#### Usage

    TaskList$add_task(task)

#### Arguments

- `task`:

  The `Task` object to be added

------------------------------------------------------------------------

### Method `remove_task()`

This method removes one or more tasks from the `TaskList`.

#### Usage

    TaskList$remove_task(x)

#### Arguments

- `x`:

  Indices of the tasks to be removed

------------------------------------------------------------------------

### Method `get_task()`

Return a single `Task` contained in the `TaskList`. The `Task` is not
removed from the `TaskList`, and has reference semantics: if the listed
task is completed by a `Worker`, then the status of any `Task` returned
by this method will update automatically

#### Usage

    TaskList$get_task(x)

#### Arguments

- `x`:

  The index the task to return

#### Returns

A `Task` object

------------------------------------------------------------------------

### Method `get_state()`

Return the status of all tasks in the `TaskList`.

#### Usage

    TaskList$get_state()

#### Returns

A character vector specifying the completion status for all listed tasks

------------------------------------------------------------------------

### Method `get_tasks_in_state()`

Return a list of tasks in a given state

#### Usage

    TaskList$get_tasks_in_state(x)

#### Arguments

- `x`:

  The name of the state (e.g., "waiting")

#### Returns

A `TaskList` object

------------------------------------------------------------------------

### Method `retrieve()`

Retrieves the current state of all tasks.

#### Usage

    TaskList$retrieve()

#### Returns

Returns a tibble containing the results of all tasks and various other
useful metadata. Contains one row per task in the `TaskList`, and the
following columns:

- `task_id` A character string specifying the task identifiers

- `worker_id` An integer specifying the worker process ids (pid)

- `state` A character string indicating the status of each task
  ("created", "waiting", "assigned", "running", or "done")

- `result` A list containing the function outputs, or NULL

- `runtime` Completion time for the task (NA if the task is not done)

- `fun` A list containing the functions

- `args` A list containing the arguments passed to each function

- `created` The time at which each task was created

- `queued` The time at which each task was added to a `Queue`

- `assigned` The time at which each task was assigned to a `Worker`

- `started` The time at which a `Worker` called each function

- `finished` The time at which a `Worker` output was returned for the
  task

- `code` The status code returned by the callr R session (integer)

- `message` The message returned by the callr R session (character)

- `stdout` List column containing the contents of stdout during function
  execution

- `stderr` List column containing the contents of stderr during function
  execution

- `error` List column containing `NULL` values

If all tasks have completed this output is the same as the output as the
`run()` method for a `Queue` object.

Note: at present there is one field from the callr rsession::read()
method that isn't captured here, and that's the error field. I'll add
that after I've finished wrapping my head around what that actually
does. The `error` column, at present, is included only as a placeholder

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    TaskList$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
