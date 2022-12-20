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
    push = function(fun, args = list(), id = NULL) {
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
    #' @return Returns a tibble containing the results of all executed tasks and
    #' various other useful metadata.
    run = function(timelimit = 60,
                   message = "minimal",
                   interval = 0.05,
                   shutdown = TRUE) {
      private$run_batch(timelimit, message, interval, shutdown)
    },

    #' @description Retrieve the full state of the tasks queue in tidy form. If
    #' all tasks have completed this output is the same as the output as the
    #' `run()` method.
    #' @return Returns a tibble containing the results of all executed tasks and
    #' various other useful metadata. Incomplete tasks may have missing data.
    retrieve = function() {
      private$tasks$retrieve()
    },

    #' @description Retrieve the workers
    #' @return A `WorkerPool` object
    get_queue_workers = function() {
      private$workers
    },

    #' @description Retrieve the tasks
    #' @return A `TaskList` object
    get_queue_tasks = function() {
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
      private$workers$try_assign(private$tasks$subset_in_state("waiting"))
      private$workers$try_start()
    },

    # send the user a pretty progress report on how the queue has progressed
    # since the last time we polled it
    update_progress = function(report, last_report, spinner, message) {
      if(message == "none") return(spinner)
      if(message == "verbose") {
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
      if(message %in% c("verbose", "minimal")) {
        msg <- paste("{spin} Queue progress:", sum(report$state == "waiting"),
                     "waiting", "\u1405", sum(report$state == "running"),
                     "running", "\u1405", sum(report$state == "done"), "done")
        spinner$spin(msg)
      }
      spinner
    },

    # send the user a final status report on the queue
    update_final = function(report, time_started, time_finished, message) {
      if(message == "none") return()
      if(message %in% c("verbose", "minimal")) {
        elapsed <- time_finished - time_started
        runtime <- round(as.numeric(elapsed), 2)
        msg <- paste0("Queue complete: ", sum(report$state == "done"),
                      " tasks done", " (", runtime, "s)")
        cli::cli_alert_success(msg)
      }
    },

    # helper function to create a spinner
    new_spinner = function() {
      cli::make_spinner(which = "dots2", template = "{spin} Queue")
    },

    # run all tasks assigned to the queue as a batch job, and return
    # the tidied up results to the user
    run_batch = function(timelimit, message, interval, shutdown) {
      time_started <- Sys.time()
      spinner <- private$new_spinner()
      report <- private$tasks$report()
      repeat{
        last_report <- report
        private$schedule(timelimit)
        report <- private$tasks$report()
        spinner <- private$update_progress(
          report,
          last_report,
          spinner,
          message
        )
        finished <- sum(report$state %in% c("waiting", "running")) == 0
        if(finished) break
        Sys.sleep(interval)
      }
      spinner$finish()
      time_finished <- Sys.time()
      private$update_final(report, time_started, time_finished, message)
      if(shutdown) private$workers$shutdown_pool()
      return(self$retrieve())
    }
  )
)

