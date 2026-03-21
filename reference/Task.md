# R6 Class Representing a Task

A `Task` stores a function, arguments, output, and metadata.

## Details

A `Task` object is used as a storage class. It is a container used to
hold an R function and any arguments to be passed to the function. It
can also hold any output returned by the function, anything printed to
stdout or stderr when the function is called, and various other metadata
such as the process id of the worker that executed the function,
timestamps, and so on.

The methods for `Task` objects fall into two groups, roughly speaking.
The `get_*()` methods are used to return information about the `Task`,
and the `register_*()` methods are used to register information related
to events relevant to the `Task` status.

The `retrieve()` method is special, and returns a tibble containing all
information stored about the task. Objects further up the hierarchy use
this method to return nicely organised output that summarise the results
from many tasks.

## Methods

### Public methods

- [`Task$new()`](#method-Task-new)

- [`Task$retrieve()`](#method-Task-retrieve)

- [`Task$get_task_fun()`](#method-Task-get_task_fun)

- [`Task$get_task_args()`](#method-Task-get_task_args)

- [`Task$get_task_state()`](#method-Task-get_task_state)

- [`Task$get_task_id()`](#method-Task-get_task_id)

- [`Task$get_task_runtime()`](#method-Task-get_task_runtime)

- [`Task$register_task_created()`](#method-Task-register_task_created)

- [`Task$register_task_waiting()`](#method-Task-register_task_waiting)

- [`Task$register_task_assigned()`](#method-Task-register_task_assigned)

- [`Task$register_task_running()`](#method-Task-register_task_running)

- [`Task$register_task_done()`](#method-Task-register_task_done)

- [`Task$clone()`](#method-Task-clone)

------------------------------------------------------------------------

### Method `new()`

Create a new task. Conceptually, a `Task` is viewed as a function that
will be executed by the `Worker` to which it is assigned, and it is
generally expected that any resources the function requires are passed
through the arguments since the execution context will be a different R
session to the one in which the function is defined.

#### Usage

    Task$new(fun, args = list(), id = NULL)

#### Arguments

- `fun`:

  The function to be called when the task executes.

- `args`:

  A list of arguments to be passed to the function (optional).

- `id`:

  A string specifying a unique task identifier (optional).

#### Returns

A new `Task` object.

------------------------------------------------------------------------

### Method `retrieve()`

Retrieve a tidy summary of the task state.

#### Usage

    Task$retrieve()

#### Returns

A tibble containing a single row, and the following columns:

- `task_id` A character string specifying the task identifier

- `worker_id` An integer specifying the worker process id (pid)

- `state` A character string indicating the task status ("created",
  "waiting", "assigned", "running", or "done")

- `result` A list containing the function output, or NULL

- `runtime` Completion time for the task (NA if the task is not done)

- `fun` A list containing the function

- `args` A list containing the arguments

- `created` The time at which the task was created

- `queued` The time at which the task was added to a `Queue`

- `assigned` The time at which the task was assigned to a `Worker`

- `started` The time at which the `Worker` called the function

- `finished` The time at which the `Worker` output was returned

- `code` The status code returned by the callr R session (integer)

- `message` The message returned by the callr R session (character)

- `stdout` List containing the contents of stdout during function
  execution

- `stderr` List containing the contents of stderr during function
  execution

- `error` List containing `NULL`

Note: at present there is one field from the callr rsession::read()
method that isn't captured here, and that's the error field. I'll add
that after I've finished wrapping my head around what that actually
does. The `error` column, at present, is included only as a placeholder

------------------------------------------------------------------------

### Method `get_task_fun()`

Retrieve the task function.

#### Usage

    Task$get_task_fun()

#### Returns

A function.

------------------------------------------------------------------------

### Method `get_task_args()`

Retrieve the task arguments

#### Usage

    Task$get_task_args()

#### Returns

A list.

------------------------------------------------------------------------

### Method `get_task_state()`

Retrieve the task state.

#### Usage

    Task$get_task_state()

#### Returns

A string specifying the current state of the task. Possible values are
"created" (task exists), "waiting" (task exists and is waiting in a
queue), "assigned" (task has been assigned to a worker but has not yet
started), "running" (task is running on a worker), or "done" (task is
completed and results have been assigned back to the task object)

------------------------------------------------------------------------

### Method `get_task_id()`

Retrieve the task id.

#### Usage

    Task$get_task_id()

#### Returns

A string containing the task identifier.

------------------------------------------------------------------------

### Method `get_task_runtime()`

Retrieve the task runtime.

#### Usage

    Task$get_task_runtime()

#### Returns

If the task has completed, a difftime value. If the task has yet to
complete, a `NA` value is returned

------------------------------------------------------------------------

### Method `register_task_created()`

Register the task creation by updating internal storage. When this
method is called, the state of the `Task` is set to "created" and a
timestamp is recorded, registering the creation time for the task. This
method is intended to be called by `Worker` objects. Users should not
need to call it.

#### Usage

    Task$register_task_created()

#### Returns

Returns `NULL` invisibly.

------------------------------------------------------------------------

### Method `register_task_waiting()`

Register the addition of the task to a queue by updating internal
storage. When this method is called, the state of the `Task` is set to
"waiting" and a timestamp is recorded, registering the time at which the
task was added to a queue. This method is intended to be called by
`Worker` objects. Users should not need to call it.

#### Usage

    Task$register_task_waiting()

#### Returns

Returns `NULL` invisibly.

------------------------------------------------------------------------

### Method `register_task_assigned()`

Register the assignment of a task to a worker by updating internal
storage. When this method is called, the state of the `Task` is set to
"assigned" and a timestamp is recorded, registering the time at which
the task was assigned to a `Worker`. In addition, the `worker_id` of the
worker object (which is also it's pid) is registered with the task. This
method is intended to be called by `Worker` objects. Users should not
need to call it.

#### Usage

    Task$register_task_assigned(worker_id)

#### Arguments

- `worker_id`:

  Identifier for the worker to which the task is assigned.

#### Returns

Returns `NULL` invisibly.

------------------------------------------------------------------------

### Method `register_task_running()`

Register the commencement of a task to a worker by updating internal
storage. When this method is called, the state of the `Task` is set to
"running" and a timestamp is recorded, registering the time at which the
`Worker` called the task function. In addition, the `worker_id` is
recorded, albeit somewhat unnecessarily since this information is likely
already stored when `register_task_assigned()` is called. This method is
intended to be called by `Worker` objects. Users should not need to call
it.

#### Usage

    Task$register_task_running(worker_id)

#### Arguments

- `worker_id`:

  Identifier for the worker on which the task is starting.

#### Returns

Returns `NULL` invisibly.

------------------------------------------------------------------------

### Method `register_task_done()`

Register the finishing of a task to a worker by updating internal
storage. When this method is called, the state of the `Task` is set to
"done" and a timestamp is recorded, registering the time at which the
`Worker` returned results to the `Task`. The `results` object is read
from the R session, and is stored locally by the `Task` at this time.
This method is intended to be called by `Worker` objects. Users should
not need to call it.

#### Usage

    Task$register_task_done(results)

#### Arguments

- `results`:

  Results read from the R session.

#### Returns

Returns `NULL` invisibly.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    Task$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
