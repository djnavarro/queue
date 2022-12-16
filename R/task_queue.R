#' R6 class for a multi-worker task queue
#'
#' Documentation baby...
#'
#' @export
TaskQueue <- R6::R6Class(
  classname = "TaskQueue",

  public = list(

    initialize = function(workers = 4L) {
      if (inherits(workers, "WorkerPool")) private$workers <- workers
      else private$workers <- WorkerPool$new(workers)
    },

    push = function(fun, args = list(), id = NULL) {
      if (is.null(id)) id <- private$get_next_id()
      task <- Task$new(fun, args, id, enqueue = TRUE)
      private$tasks[[length(private$tasks) + 1L]] <- task
    },

    run = function(verbose = FALSE, interval = 0.05) {
      private$run_batch(verbose, interval)
    },

    retrieve = function() {
      out <- lapply(private$tasks, function(x) x$retrieve())
      do.call(rbind, out)
    },

    get_queue_progress = function() {
      tibble::tibble(
        task_id = unlist(lapply(private$tasks, function(x) x$get_task_id())),
        state = unlist(lapply(private$tasks, function(x) x$get_task_state())),
        runtime = unlist(lapply(private$tasks, function(x) x$get_task_runtime()))
      )
    }
  ),

  private = list(

    workers = NULL,
    tasks = list(),

    next_id = 1L,

    get_next_id = function() {
      id <- private$next_id
      private$next_id <- id + 1L
      paste0(".", id)
    },

    get_waiting_tasks = function() {
      waiting <- vapply(
        private$tasks,
        function(x) x$get_task_state() == "waiting",
        logical(1)
      )
      private$tasks[waiting]
    },

    schedule = function() {
      private$workers$try_finish()
      private$workers$refill_pool()
      private$workers$try_assign(private$get_waiting_tasks())
      private$workers$try_start()
    },

    update_progress = function(report, last_report, spinner, verbose) {
      if(verbose) {
        done <- setdiff(
          which(report$state == "done"),
          which(last_report$state == "done")
        )
        if(length(done) > 0) {
          spinner$finish()
          for(id in done) {
            msg <- paste("Task complete:", report$task_id[id], "(Time:",
                         round(as.numeric(report$runtime[id]), 2), "seconds)")
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

    update_final = function(report, time_started, time_finished) {
      elapsed <- time_finished - time_started
      runtime <- round(as.numeric(elapsed), 2)
      msg <- paste("Queue complete:", sum(report$state == "done"),
                   "tasks done", "(Total time:", runtime, "seconds)")
      cli::cli_alert_success(msg)
    },

    new_spinner = function() {
      cli::make_spinner(which = "dots2", template = "{spin} Queue")
    },

    run_batch = function(verbose, interval) {
      time_started <- Sys.time()
      spinner <- private$new_spinner()
      report <- self$get_queue_progress()
      repeat{
        last_report <- report
        private$schedule()
        report <- self$get_queue_progress()
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
      return(invisible(self$retrieve()))
    }
  )

)
