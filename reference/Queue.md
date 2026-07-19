# R6 Class Representing a Multi-Worker Task Queue

A `Queue` executes tasks concurrently using multiple workers.

## Details

The `Queue` class is primary interface provided by the queue package. It
allows users to execute an arbitrary collection of tasks in parallel
across multiple R sessions, managed automatically in the background.
Once a new queue is initialised, tasks can be added to the queue using
the `add()` method. Once all tasks are added, they are executed in
parallel by calling the `run()` method. When completed, `run()` returns
a tibble that contains the results for all tasks, and some additional
metadata besides.

Internally, a `Queue` uses a `TaskList` object as its data store and a
`WorkerPool` object to execute the tasks in parallel. These objects can
be accessed by calling the `get_tasks()` method and the `get_workers()`
methods. Usually you would not need to do this, but occasionally it can
be useful because those objects have some handy methods that allow
finer-grained control (see the documentation for `TaskList` and
`WorkerPool` respectively).

## Methods

### Public methods

- [`Queue$new()`](#method-Queue-new)

- [`Queue$add()`](#method-Queue-add)

- [`Queue$run()`](#method-Queue-run)

- [`Queue$get_workers()`](#method-Queue-get_workers)

- [`Queue$get_tasks()`](#method-Queue-get_tasks)

- [`Queue$clone()`](#method-Queue-clone)

------------------------------------------------------------------------

### Method `new()`

Create a task queue

#### Usage

    Queue$new(workers = 4L)

#### Arguments

- `workers`:

  Either the number of workers to employ in the task queue, or a
  `WorkerPool` object to use when deploying the tasks.

#### Returns

A new `Queue` object

------------------------------------------------------------------------

### Method `add()`

Adds a task to the queue

#### Usage

    Queue$add(fun, args = list(), id = NULL)

#### Arguments

- `fun`:

  The function to be called when the task is scheduled

- `args`:

  A list of arguments to be passed to the task function (optional)

- `id`:

  A string specifying a unique identifier for the task (optional: tasks
  will be named "task_1", "task_2", etc if this is unspecified)

#### Returns

Invisibly returns the `Task` object

------------------------------------------------------------------------

### Method `run()`

Execute tasks in parallel using the worker pool, assigning tasks to
workers in the same order in which they were added to the queue

#### Usage

    Queue$run(
      timelimit = 60,
      message = "minimal",
      interval = 0.05,
      shutdown = TRUE
    )

#### Arguments

- `timelimit`:

  How long (in seconds) should the worker pool wait for a task to
  complete before terminating the child process and moving onto the next
  task? (default is 60 seconds, but this is fairly arbitrary)

- `message`:

  What messages should be reported by the queue while it is running?
  Options are "none" (no messages), "minimal" (a spinner is shown
  alongside counts of waiting, running, and completed tasks), and
  "verbose" (in addition to the spinner, each task is summarized as it
  completes). Default is "minimal".

- `interval`:

  How often should the task queue poll the workers to see if they have
  finished their assigned tasks? Specified in seconds.

- `shutdown`:

  Should the workers in the pool be shut down (i.e., all R sessions
  closed) once the tasks are completed. Defaults to `TRUE`.

#### Returns

Returns a tibble containing the results of all tasks and various other
useful metadata. Contains one row per task in the `Queue`, and the
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

Note: at present there is one field from the callr rsession::read()
method that isn't captured here, and that's the error field. I'll add
that after I've finished wrapping my head around what that actually
does. The `error` column, at present, is included only as a placeholder

------------------------------------------------------------------------

### Method `get_workers()`

Retrieve the workers

#### Usage

    Queue$get_workers()

#### Returns

A `WorkerPool` object

------------------------------------------------------------------------

### Method `get_tasks()`

Retrieve the tasks

#### Usage

    Queue$get_tasks()

#### Returns

A `TaskList` object

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    Queue$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
queue <- Queue$new(workers = 4L)
wait <- function(x) Sys.sleep(runif(1))
for(i in 1:6) queue$add(wait)
queue$run()
#> ✔ Queue complete: 6 tasks done in 1.16 secs
#> # A tibble: 6 × 17
#>   task_id worker_id state result runtime        fun   args   created            
#>   <chr>       <int> <chr> <list> <drtn>         <lis> <list> <dttm>             
#> 1 task_1       6855 done  <NULL> 0.7395797 secs <fn>  <list> 2026-07-19 03:13:33
#> 2 task_2       6873 done  <NULL> 0.8428593 secs <fn>  <list> 2026-07-19 03:13:33
#> 3 task_3       6891 done  <NULL> 0.1561053 secs <fn>  <list> 2026-07-19 03:13:33
#> 4 task_4       6909 done  <NULL> 0.5730157 secs <fn>  <list> 2026-07-19 03:13:33
#> 5 task_5       6891 done  <NULL> 0.5238111 secs <fn>  <list> 2026-07-19 03:13:33
#> 6 task_6       6909 done  <NULL> 0.5614467 secs <fn>  <list> 2026-07-19 03:13:33
#> # ℹ 9 more variables: queued <dttm>, assigned <dttm>, started <dttm>,
#> #   finished <dttm>, code <int>, message <chr>, stdout <list>, stderr <list>,
#> #   error <list>
```
