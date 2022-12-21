#' R6 class for a multi-worker task queue
#'
#' Documentation baby...
#'
#' @export
Queue <- R6::R6Class(
  classname = "Queue",

  public = list(

    #' @description Create a task queue
    #' @param workers Either the number of workers to employ in the task queue,
    #' or a `WorkerPool` object to use when deploying the tasks.
    #' @return A new `Queue` object
    initialize = function(workers = 4L) {
      private$tasks <- TaskList$new()
      if (inherits(workers, "WorkerPool")) private$workers <- workers
      else private$workers <- WorkerPool$new(workers)
    },

    #' @description Adds a task to the queue
    #' @param fun The function to be called when the task is scheduled
    #' @param args A list of arguments to be passed to the task function (optional)
    #' @param id A string specifying a unique identifier for the task (optional: tasks
    #' will be named "task_1", "task_2", etc if this is unspecified)
    #' @return Invisibly returns the `Task` object
    add = function(fun, args = list(), id = NULL) {
      if (is.null(id)) id <- private$get_next_id()
      task <- Task$new(fun, args, id)
      task$register_task_waiting()
      private$tasks$add_task(task)
      invisible(task)
    },

    #' @description Execute tasks in parallel using the worker pool, assigning
    #' tasks to workers in the same order in which they were added to the queue
    #' @param timelimit How long (in seconds) should the worker pool wait for a
    #' task to complete before terminating the child process and moving onto the
    #' next task? (default is 60 seconds, but this is fairly arbitrary)
    #' @param message What messages should be reported by the queue while it is
    #' running? Options are "none" (no messages), "minimal" (a spinner is shown
    #' alongside counts of waiting, running, and completed tasks), and "verbose"
    #' (in addition to the spinner, each task is summarized as it completes).
    #' Default is "minimal".
    #' @param interval How often should the task queue poll the workers to see
    #' if they have finished their assigned tasks? Specified in seconds.
    #' @param shutdown Should the workers in the pool be shut down (i.e., all
    #' R sessions closed) once the tasks are completed. Defaults to `TRUE`.
    #' @return Returns a tibble containing the results of all tasks and
    #' various other useful metadata. Contains one row per task in the
    #' `Queue`, and the following columns:
    #' * `task_id` A character string specifying the task identifiers
    #' * `worker_id` An integer specifying the worker process ids (pid)
    #' * `state` A character string indicating the status of each task
    #'   ("created", "waiting", "assigned", "running", or "done")
    #' * `result` A list containing the function outputs, or NULL
    #' * `runtime` Completion time for the task (NA if the task is not done)
    #' * `fun` A list containing the functions
    #' * `args` A list containing the arguments passed to each function
    #' * `created` The time at which each task was created
    #' * `queued` The time at which each task was added to a `Queue`
    #' * `assigned` The time at which each task was assigned to a `Worker`
    #' * `started` The time at which a `Worker` called each function
    #' * `finished` The time at which a `Worker` output was returned for the task
    #' * `code` The status code returned by the callr R session (integer)
    #' * `message` The message returned by the callr R session (character)
    #' * `stdout` List column containing the contents of stdout during function execution
    #' * `stderr` List column containing the contents of stderr during function execution
    #' * `error`  List column containing `NULL` values
    #'
    #' Note: at present there is one field from the callr rsession::read() method
    #' that isn't captured here, and that's the error field. I'll add that after
    #' I've finished wrapping my head around what that actually does. The `error`
    #' column, at present, is included only as a placeholder
    #' @md
    run = function(timelimit = 60,
                   message = "minimal",
                   interval = 0.05,
                   shutdown = TRUE) {
      private$run_batch(timelimit, message, interval, shutdown)
    },

    #' @description Retrieve the workers
    #' @return A `WorkerPool` object
    get_workers = function() {
      private$workers
    },

    #' @description Retrieve the tasks
    #' @return A `TaskList` object
    get_tasks = function() {
      private$tasks
    }

  ),

  private = list(

    # containers for tasks and workers
    workers = NULL,
    tasks = NULL,

    # helpers used to assign task ids if the user doesn't
    next_id = 1L,
    get_next_id = function() {
      id <- private$next_id
      private$next_id <- id + 1L
      paste0("task_", id)
    },

    # tasks scheduling is mostly devolved to the WorkerPool methods, which
    # in turn ask each Worker to *try* to finish/assign/start the relevant
    # job. the main thing that happens within the Queue itself is finding
    # the list of waiting tasks
    schedule = function(timelimit) {
      private$workers$try_finish()
      private$workers$shutdown_overdue_workers(timelimit)
      private$workers$refill_pool()
      private$workers$try_assign(private$tasks$get_tasks_in_state("waiting"))
      private$workers$try_start()
    },

    # run all tasks assigned to the queue as a batch job, and return
    # the tidied up results to the user
    run_batch = function(timelimit, message, interval, shutdown) {
      time_started <- Sys.time()
      repeat{
        private$schedule(timelimit)
        state <- private$tasks$get_state(message)
        finished <- sum(state %in% c("waiting", "running")) == 0
        if(finished) break
        Sys.sleep(interval)
      }
      time_finished <- Sys.time()
      elapsed <- time_finished - time_started
      private$tasks$get_state(message, finished_in = elapsed)
      if(shutdown) private$workers$shutdown_pool()
      return(private$tasks$retrieve())
    }
  )
)

