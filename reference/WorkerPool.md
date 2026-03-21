# R6 Class Representing a Worker Pool

A `WorkerPool` manages multiple workers.

## Details

The implementation for a `WorkerPool` is essentially a container that
holds one or more `Worker` objects, and posesses methods that allow it
to instruct them to assign, start, and complete `Task`s. It can also
check to see if any of the R sessions associated with the `Worker`s have
crashed or stalled, and replace them as needed.

## Methods

### Public methods

- [`WorkerPool$new()`](#method-WorkerPool-new)

- [`WorkerPool$get_pool_worker()`](#method-WorkerPool-get_pool_worker)

- [`WorkerPool$get_pool_state()`](#method-WorkerPool-get_pool_state)

- [`WorkerPool$try_assign()`](#method-WorkerPool-try_assign)

- [`WorkerPool$try_start()`](#method-WorkerPool-try_start)

- [`WorkerPool$try_finish()`](#method-WorkerPool-try_finish)

- [`WorkerPool$refill_pool()`](#method-WorkerPool-refill_pool)

- [`WorkerPool$shutdown_pool()`](#method-WorkerPool-shutdown_pool)

- [`WorkerPool$shutdown_overdue_workers()`](#method-WorkerPool-shutdown_overdue_workers)

- [`WorkerPool$clone()`](#method-WorkerPool-clone)

------------------------------------------------------------------------

### Method `new()`

Create a new worker pool

#### Usage

    WorkerPool$new(workers = 4L)

#### Arguments

- `workers`:

  The number of workers in the pool.

#### Returns

A new `WorkerPool` object.

------------------------------------------------------------------------

### Method `get_pool_worker()`

Return a specific `Worker`

#### Usage

    WorkerPool$get_pool_worker(x)

#### Arguments

- `x`:

  An integer specifying the index of the worker in the pool.

#### Returns

The corresponding `Worker` object.

------------------------------------------------------------------------

### Method `get_pool_state()`

Return a summary of the worker pool

#### Usage

    WorkerPool$get_pool_state()

#### Returns

A named character vector specifying the current state of each worker
("starting", "idle", "busy", or "finished"). Names denote worker ids,
and the interpretations of each return value is as follows:

- `"starting"`: the R session is starting up.

- `"idle"`: the R session is ready to compute.

- `"busy"`: the R session is computing.

- `"finished"`: the R session has terminated.

------------------------------------------------------------------------

### Method `try_assign()`

Attempt to assign tasks to workers. This method is intended to be called
by `Queue` objects. When called, this method will iterate over tasks in
the list and workers in the pool, assigning tasks to workers as long as
there are both idle workers and waiting tasks. It returns once it runs
out of one resource or the other. Note that this method assigns tasks to
workers: it does not instruct the workers to to start working on the
tasks. That is the job of `try_start()`.

#### Usage

    WorkerPool$try_assign(tasks)

#### Arguments

- `tasks`:

  A `TaskList` object

#### Returns

Invisibly returns `NULL`

------------------------------------------------------------------------

### Method `try_start()`

Iterates over `Workers` in the pool and asks them to start any jobs that
the have been assigned but have not yet started. This method is intended
to be called by `Queue` objects.

#### Usage

    WorkerPool$try_start()

#### Returns

Invisibly returns `NULL`

------------------------------------------------------------------------

### Method `try_finish()`

Iterate over `Workers` in the pool and checks to see if any of the busy
sessions are ready to return results. For those that are, it finishes
the tasks and ensures those results are returned to the `Task` object.
This method is intended to be called by `Queue` objects.

#### Usage

    WorkerPool$try_finish()

#### Returns

Invisibly returns `NULL`

------------------------------------------------------------------------

### Method `refill_pool()`

Check the `WorkerPool` looking for `Workers` that have crashed or been
shutdown, and replace them with fresh workers.

#### Usage

    WorkerPool$refill_pool()

#### Returns

This function is called primarily for its side effect. It returns a
named character documenting the outcome, indicating the current state of
each worker: should not be "finished" for any worker. Names denote
worker ids.

------------------------------------------------------------------------

### Method `shutdown_pool()`

Terminate all workers in the pool.

#### Usage

    WorkerPool$shutdown_pool(grace = 1000)

#### Arguments

- `grace`:

  Grace period in milliseconds. If a worker process is still running
  after this period, it will be killed.

#### Returns

This function is called primarily for its side effect. It returns a
named character documenting the outcome, indicating the current state of
each worker: should be "finished" for all workers. Names denote worker
ids.

------------------------------------------------------------------------

### Method `shutdown_overdue_workers()`

Terminate workers that have worked on their current task for longer than
a pre-specified time limit.

#### Usage

    WorkerPool$shutdown_overdue_workers(timelimit, grace = 1000)

#### Arguments

- `timelimit`:

  Pre-specified time limit for the task, in seconds.

- `grace`:

  Grace period for the shutdown, in milliseconds. If a worker process is
  still running after this period, it will be killed.

#### Returns

This function is called primarily for its side effect. It returns a
named character documenting the outcome, indicating the current state of
each worker: should be "finished" for all workers. Names denote worker
ids.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    WorkerPool$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
