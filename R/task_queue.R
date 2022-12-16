#' R6 class for a multi-worker task queue
#'
#' Documentation baby...
#'
#' @export
TaskQueue <- R6::R6Class(
  classname = "TaskQueue",

  public = list(

    #' @description Create a task queue
    #' @param workers Either the number of workers to employ in the task queue,
    #' or a `WorkerPool` object to use when deploying the tasks.
    #' @return A new `TaskQueue` object
    initialize = function(workers = 4L) {
      if (inherits(workers, "WorkerPool")) private$workers <- workers
      else private$workers <- WorkerPool$new(workers)
    },

    #' @description Adds a task to the queue
    #' @param fun The function to be called when the task is scheduled
    #' @param args A list of arguments to be passed to the task function (optional)
    #' @param id A string specifying a unique identifier for the task (optional: tasks
    #' will be named "task_1", "task_2", etc if this is unspecified)
    #' @return Invisibly returns the `Task` object
    push = function(fun, args = list(), id = NULL) {
      if (is.null(id)) id <- private$get_next_id()
      task <- Task$new(fun, args, id, enqueue = TRUE)
      private$tasks[[length(private$tasks) + 1L]] <- task
      invisible(task)
    },

    #' @description Execute tasks in parallel using the worker pool, assigning
    #' tasks to workers in the same order in which they were added to the queue
    #' @param verbose Should the queue be chatty and report on every task
    #' completion? Defaults to `TRUE`. If set to `FALSE`, only a spinner will
    #' be shown, along with a count of the number of waiting, running, and
    #' completed tasks.
    #' @param interval How often should the task queue poll the workers to see
    #' if they have finished their assigned tasks? Specified in seconds.
    #' @param shutdown Should the workers in the pool be shut down (i.e., all
    #' R sessions closed) once the tasks are completed. Defaults to `TRUE`.
    #' @return Returns a tibble containing the results of all executed tasks and
    #' various other useful metadata.
    run = function(verbose = FALSE, interval = 0.05, shutdown = TRUE) {
      private$run_batch(verbose, interval, shutdown)
    },

    #' @description Retrieve the full state of the tasks queue in tidy form. If
    #' all tasks have completed this output is the same as the output as the
    #' `run()` method.
    #' @return Returns a tibble containing the results of all executed tasks and
    #' various other useful metadata. Incomplete tasks nay have missing data.
    retrieve = function() {
      out <- lapply(private$tasks, function(x) x$retrieve())
      do.call(rbind, out)
    },

    #' @description Get as simplified description of the current state of the
    #' task queue. The corresponding private method is used internally to
    #' generate progress reports and to monitor progress of the task queue,
    #' but might be handy to have a public version.
    #' @return Returns a tibble with three columns: task_id, state, and runtime
    get_queue_report = function() {
      private::get_report()
    },

    #' @description Retrieve the workers
    #' @return A `WorkerPool` object
    get_queue_workers = function() {
      private$workers
    }

  ),

  private = list(

    # containers for tasks and workers
    workers = NULL,
    tasks = list(),

    # helpers used to assign task ids if the user doesn't
    next_id = 1L,
    get_next_id = function() {
      id <- private$next_id
      private$next_id <- id + 1L
      paste0("task_", id)
    },

    # retrieve the list of tasks still in "waiting" status
    get_waiting_tasks = function() {
      waiting <- vapply(
        private$tasks,
        function(x) x$get_task_state() == "waiting",
        logical(1)
      )
      private$tasks[waiting]
    },

    # tasks scheduling is mostly devolved to the WorkerPool methods, which
    # in turn ask each Worker to *try* to finish/assign/start the relevant
    # job. the main thing that happens within the TaskQueue itself is finding
    # the list of waiting tasks
    schedule = function() {
      private$workers$try_finish()
      private$workers$refill_pool()
      private$workers$try_assign(private$get_waiting_tasks())
      private$workers$try_start()
    },

    # send the user a pretty progress report on how the queue has progressed
    # since the last time we polled it
    update_progress = function(report, last_report, spinner, verbose) {
      if(verbose) {
        done <- setdiff(
          which(report$state == "done"),
          which(last_report$state == "done")
        )
        if(length(done) > 0) {
          spinner$finish()
          for(id in done) {
            msg <- paste0("Task done: ", report$task_id[id], " (",
                          round(as.numeric(report$runtime[id]), 2), "s)")
            cli::cli_alert(msg)
          }
          spinner <- private$new_spinner()
        }
      }
      msg <- paste("{spin} Queue progress:", sum(report$state == "waiting"),
                   "waiting", "\u1405", sum(report$state == "running"),
                   "running", "\u1405", sum(report$state == "done"), "done")
      spinner$spin(msg)
      spinner
    },

    # send the user a final status report on the queue
    update_final = function(report, time_started, time_finished) {
      elapsed <- time_finished - time_started
      runtime <- round(as.numeric(elapsed), 2)
      msg <- paste0("Queue complete: ", sum(report$state == "done"),
                    " tasks done", " (", runtime, "s)")
      cli::cli_alert_success(msg)
    },

    # helper function to create a spinner
    new_spinner = function() {
      cli::make_spinner(which = "dots2", template = "{spin} Queue")
    },

    # get progress report containing only those fields needed to monitior
    # the queue and to update the user
    get_report = function() {
      tibble::tibble(
        task_id = unlist(lapply(private$tasks, function(x) x$get_task_id())),
        state = unlist(lapply(private$tasks, function(x) x$get_task_state())),
        runtime = unlist(lapply(private$tasks, function(x) x$get_task_runtime()))
      )
    },

    # run all tasks assigned to the queue as a batch job, and return
    # the tidied up results to the user
    run_batch = function(verbose, interval, shutdown) {
      time_started <- Sys.time()
      spinner <- private$new_spinner()
      report <- private$get_report()
      repeat{
        last_report <- report
        private$schedule()
        report <- private$get_report()
        spinner <- private$update_progress(
          report,
          last_report,
          spinner,
          verbose
        )
        finished <- sum(report$state %in% c("waiting", "running")) == 0
        if(finished) break
        Sys.sleep(interval)
      }
      spinner$finish()
      time_finished <- Sys.time()
      private$update_final(report, time_started, time_finished)
      if(shutdown) private$workers$shutdown_pool()
      return(self$retrieve())
    }
  )

)
