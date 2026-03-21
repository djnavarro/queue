# R6 Class Representing a Worker

A `Worker` manages an external R session and completes tasks.

## Details

The `Worker` class interacts with an external R session, and possesses
methods that allow it to work with `Task` objects. At its core, the
class is a thin wrapper around a
[`callr::r_session`](https://callr.r-lib.org/reference/r_session.html)
object, and in fact the session object itself can be obtained by calling
the `get_worker_session()` method. In most cases this shouldn't be
necessary however, because `Worker` objects are typically created as
part of a `WorkerPool` that is managed by a `Queue`, and those higher
level structures use the methods exposed by the `Worker` object.

## Methods

### Public methods

- [`Worker$new()`](#method-Worker-new)

- [`Worker$get_worker_id()`](#method-Worker-get_worker_id)

- [`Worker$get_worker_state()`](#method-Worker-get_worker_state)

- [`Worker$get_worker_runtime()`](#method-Worker-get_worker_runtime)

- [`Worker$get_worker_task()`](#method-Worker-get_worker_task)

- [`Worker$get_worker_session()`](#method-Worker-get_worker_session)

- [`Worker$try_assign()`](#method-Worker-try_assign)

- [`Worker$try_start()`](#method-Worker-try_start)

- [`Worker$try_finish()`](#method-Worker-try_finish)

- [`Worker$shutdown_worker()`](#method-Worker-shutdown_worker)

- [`Worker$clone()`](#method-Worker-clone)

------------------------------------------------------------------------

### Method `new()`

Create a new worker object.

#### Usage

    Worker$new()

#### Returns

A new `Worker` object.

------------------------------------------------------------------------

### Method `get_worker_id()`

Retrieve the worker identifier.

#### Usage

    Worker$get_worker_id()

#### Returns

The worker identifier, which also the process id for the R session

------------------------------------------------------------------------

### Method `get_worker_state()`

Retrieve the worker state.

#### Usage

    Worker$get_worker_state()

#### Returns

A string specifying the current state of the R session. Possible values
are:

- `"starting"`: the R session is starting up.

- `"idle"`: the R session is ready to compute.

- `"busy"`: the R session is computing.

- `"finished"`: the R session has terminated.

Importantly, note that a task function that is still running and a task
function that is essentially finished and waiting to return will both
return "busy". To distinguish between these two cases you need to use
the `poll_process()` method of a `callr::rsession`, as returned by
`get_worker_session()`.

------------------------------------------------------------------------

### Method `get_worker_runtime()`

Return the total length of time the worker session has been running, and
the length of the time that the current task has been running. If the
session is finished both values are `NA`. If the session is idle (no
task running) the total session time will return a value but the current
task time will be `NA`.

#### Usage

    Worker$get_worker_runtime()

#### Returns

A vector of two difftimes.

------------------------------------------------------------------------

### Method `get_worker_task()`

Retrieve the task assigned to the worker.

#### Usage

    Worker$get_worker_task()

#### Returns

The `Task` object currently assigned to this `Worker`, or `NULL`.

------------------------------------------------------------------------

### Method `get_worker_session()`

Retrieve the R session associated with a `Worker`

#### Usage

    Worker$get_worker_session()

#### Returns

An R session object, see
[`callr::r_session`](https://callr.r-lib.org/reference/r_session.html)

------------------------------------------------------------------------

### Method `try_assign()`

Attempt to assign a task to this worker. This method checks that the
task and the worker are both in an appropriate state. If they are, both
objects register their connection to the other. This method is intended
to be called by a `WorkerPool` or a `Queue`.

#### Usage

    Worker$try_assign(task)

#### Arguments

- `task`:

  A `Task` object corresponding to the to-be-assigned task.

#### Returns

Invisibly returns `TRUE` or `FALSE`, depending on whether the attempt
was successful.

------------------------------------------------------------------------

### Method `try_start()`

Attempt to start the task. This method checks to see if the that worker
has an assigned task, and if so starts it running within the R session.
It also registers the change of status within the `Task` object itself.
This method is intended to be called by a `WorkerPool` or a `Queue`.

#### Usage

    Worker$try_start()

#### Returns

Invisibly returns `TRUE` or `FALSE`, depending on whether the attempt
was successful.

------------------------------------------------------------------------

### Method `try_finish()`

Attempt to finish a running task politely. This method checks to see if
the worker has a running task, and if so polls the R session to
determine if the R process claims to be ready to return. If there is a
ready-to-return task the results are read from the R process and
returned to the `Task` object. The task status is updated, and then
unassigned from the `Worker`. This method is intended to be called by a
`WorkerPool` or a `Queue`.

#### Usage

    Worker$try_finish(timeout = 0)

#### Arguments

- `timeout`:

  Length of time to wait when process is polled (default = 0)

#### Returns

Invisibly returns `TRUE` or `FALSE`, depending on whether the attempt
was successful.

------------------------------------------------------------------------

### Method `shutdown_worker()`

Attempt to shut down the R session gracefully, after making an attempt
to salvage any task that the worker believes it has been assigned. The
salvage operation depends on the state of the task. If the `Task` has
been assigned but not started, the `Worker` will return it to a
"waiting" state in the hope that the `Queue` will assign it to another
worker later, and unassign it. If the `Task` is running, the `Worker`
will attempt to read from the R session and then register the `Task` as
"done" regardless of the outcome. (The reason for this is to ensure that
tasks that crash or freeze the R session don't get returned to the
`Queue`).

#### Usage

    Worker$shutdown_worker(grace = 1000)

#### Arguments

- `grace`:

  Grace period in milliseconds. If the process is still running after
  this period, it will be killed.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    Worker$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
