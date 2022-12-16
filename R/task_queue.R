#' R6 class for a multi-worker task queue
#'
#' Documentation baby...
#'
#' @export
TaskQueue <- R6::R6Class(
  classname = "TaskQueue",

  public = list(
    workers = NULL,
    tasks = list(),
    actions = list(),
    initialize = function(workers = 4) {
      if(inherits(workers, "WorkerPool")) {
        self$workers <- workers
      } else {
        self$workers <- WorkerPool$new(workers)
      }
    },
    push = function(fun, args = list(), id = NULL) {
      if(is.null(id)) id <- private$get_next_id()
      self$tasks[[self$num_tasks + 1]] <- Task$new(fun, args, id, enqueue = TRUE)
    },
    run = function(verbose = FALSE) {
      private$run_batch(verbose)
    },
    retrieve = function() {
      out <- lapply(self$tasks, function(x) x$retrieve())
      do.call(rbind, out)
    }
  ),

  active = list(
    num_tasks = function() length(self$tasks),
    state = function() {
      s <- unlist(lapply(self$tasks, function(x) x$get_task_state()))
      names(s) <- unlist(lapply(self$tasks, function(x) x$task_id))
      s
    }
  ),

  private = list(

    next_id = 1L,

    get_next_id = function() {
      id <- private$next_id
      private$next_id <- id + 1L
      paste0(".", id)
    },

    # these feel like hacks: get rid of it when we have a proper tibble
    get_task_by_id = function(id) {
      ind <- which(unlist(lapply(self$tasks, function(x) x$task_id == id)))
      self$tasks[[ind]]
    },
    get_waiting_tasks = function() {
      waiting <- vapply(self$tasks, function(x) x$get_task_state() == "waiting", logical(1))
      self$tasks[waiting]
    },

    schedule = function() {
      out <- list()
      out$try_finish  <- self$workers$try_finish()
      out$refill_pool <- self$workers$refill_pool()
      out$try_assign  <- self$workers$try_assign(private$get_waiting_tasks())
      out$try_start   <- self$workers$try_start()
      invisible(out)
    },

    message_spinner_progress = function(state) {
      paste(
        "{spin} Queue progress:", sum(state == "waiting"), "waiting",
        "\u1405", sum(state == "running"), "running", "\u1405",
        sum(state == "done"), "done"
      )
    },

    message_batch_finished = function(state, time_elapsed) {
      runtime <- round(as.numeric(time_elapsed), 2)
      paste("Queue complete:", sum(state == "done"), "tasks done",
            "(Total time:", runtime, "seconds)")
    },

    message_task_finished = function(id) {
      task <- private$get_task_by_id(id)
      runtime <- round(as.numeric(task$time_elapsed), 2)
      paste("Task complete:", id, "(Time:", runtime, "seconds)")
    },

    new_spinner = function() {
      cli::make_spinner(which = "dots2", template = "{spin} Queue")
    },

    run_batch = function(verbose) {
      time_started <- Sys.time()
      spinner <- private$new_spinner()
      if(verbose) {
        state <- self$state
        done_before <- names(which(state == "done"))
      }
      repeat{
        private$schedule()
        state <- self$state
        if(verbose) {
          done_now <- names(which(state == "done"))
          done_just_now <- setdiff(done_now, done_before)
          if(length(done_just_now)) {
            done_before <- done_now
            spinner$finish()
            for(id in done_just_now) {
              cli::cli_alert(private$message_task_finished(id))
            }
            spinner <- private$new_spinner()
          }
        }
        spinner$spin(private$message_spinner_progress(state))
        if(sum(state %in% c("waiting", "running")) == 0) break
        Sys.sleep(.05)
      }
      spinner$finish()
      time_finished <- Sys.time()
      time_elapsed <- time_finished - time_started
      cli::cli_alert_success(private$message_batch_finished(state, time_elapsed))
      return(invisible(self$retrieve()))
    }
  )
)
