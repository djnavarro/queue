#' R6 Class Representing a Worker Pool
#'
#' @description
#' A `WorkerPool` manages multiple workers.
#'
#' @details
#' The implementation for a `WorkerPool` is essentially a container that holds
#' one or more `Worker` objects, and posesses methods that allow it to instruct
#' them to assign, start, and complete `Task`s. It can also check to
#' see if any of the R sessions associated with the `Worker`s have crashed or
#' stalled, and replace them as needed.
#'
#' @export
WorkerPool <- R6::R6Class(
  classname = "WorkerPool",

  public = list(

    #' @description Create a new worker pool
    #' @param workers The number of workers in the pool.
    #' @return A new `WorkerPool` object.
    initialize = function(workers = 4L) {
      for(i in seq_len(workers)) private$workers[[i]] <- Worker$new()
    },

    #' @description Return a specific `Worker`
    #' @param x An integer specifying the index of the worker in the pool.
    #' @return The corresponding `Worker` object.
    get_pool_worker = function(x) {
      private$workers[[x]]
    },

    #' @description Return a summary of the worker pool
    #' @return A named character vector specifying the current state
    #' of each worker ("starting", "idle", "busy", or "finished"). Names
    #' denote worker ids, and the interpretations of each return value is as
    #' follows:
    #' * `"starting"`: the R session is starting up.
    #' * `"idle"`: the R session is ready to compute.
    #' * `"busy"`: the R session is computing.
    #' * `"finished"`: the R session has terminated.
    get_pool_state = function() {
      state <- vapply(
        private$workers,
        function(x) x$get_worker_state(),
        character(1)
      )
      names(state) <- vapply(
        private$workers,
        function(x) as.character(x$get_worker_id()),
        character(1)
      )
      state
    },

    #' @description Attempt to assign tasks to workers. This method is
    #' intended to be called by `Queue` objects. When called, this method
    #' will iterate over tasks in the list and workers in the pool, assigning
    #' tasks to workers as long as there are both idle workers and waiting
    #' tasks. It returns once it runs out of one resource or the other. Note
    #' that this method assigns tasks to workers: it does not instruct the
    #' workers to to start working on the tasks. That is the job of
    #' `try_start()`.
    #' @param tasks A `TaskList` object
    #' @return Invisibly returns `NULL`
    try_assign = function(tasks) {
      n_workers <- length(private$workers)
      n_tasks <- tasks$length()
      w <- 1
      t <- 1
      while(n_workers > 0 & n_tasks > 0) {
        assigned <- private$workers[[w]]$try_assign(tasks$get_task(t))
        w <- w + 1
        n_workers <- n_workers - 1
        if(assigned) {
          t <- t + 1
          n_tasks <- n_tasks - 1
        }
      }
      invisible(NULL)
    },

    #' @description Iterates over `Workers` in the pool and asks them to
    #' start any jobs that the have been assigned but have not yet started.
    #' This method is intended to be called by `Queue` objects.
    #' @return Invisibly returns `NULL`
    try_start = function() {
      lapply(private$workers, function(x) x$try_start())
      invisible(NULL)
    },

    #' @description Iterate over `Workers` in the pool and checks to see if
    #' any of the busy sessions are ready to return results. For those that
    #' are, it finishes the tasks and ensures those results are returned to
    #' the `Task` object. This method is intended to be called by `Queue`
    #' objects.
    #' @return Invisibly returns `NULL`
    try_finish = function() {
      lapply(private$workers, function(x) x$try_finish())
      invisible(NULL)
    },

    #' @description Check the `WorkerPool` looking for `Workers` that
    #' have crashed or been shutdown, and replace them with fresh workers.
    #' @return This function is called primarily for its side effect. It
    #' returns a named character documenting the outcome, indicating the
    #' current state of each worker: should not be "finished" for any worker.
    #' Names denote worker ids.
    refill_pool = function() {
      for(i in seq_along(private$workers)) {
        if(private$workers[[i]]$get_worker_state() == "finished") {
          private$workers[[i]] <- Worker$new()
        }
      }
      self$get_pool_state()
    },

    #' @description Terminate all workers in the pool.
    #' @param grace Grace period in milliseconds. If a worker process is still
    #' running after this period, it will be killed.
    #' @return This function is called primarily for its side effect. It
    #' returns a named character documenting the outcome, indicating the
    #' current state of each worker: should be "finished" for all workers.
    #' Names denote worker ids.
    shutdown_pool = function(grace = 1000) {
      lapply(private$workers, function(x) x$shutdown_worker(grace))
      self$get_pool_state()
    },

    #' @description Terminate workers that have worked on their current task
    #' for longer than a pre-specified time limit.
    #' @param timelimit Pre-specified time limit for the task, in seconds.
    #' @param grace Grace period for the shutdown, in milliseconds. If a
    #' worker process is still running after this period, it will be killed.
    #' @return This function is called primarily for its side effect. It
    #' returns a named character documenting the outcome, indicating the
    #' current state of each worker: should be "finished" for all workers.
    #' Names denote worker ids.
    shutdown_overdue_workers = function(timelimit, grace = 1000) {
      private$enforce_runtime_limit(timelimit, grace)
      self$get_pool_state()
    }

  ),

  private = list(
    workers = list(),

    # check how long each worker has been working at its current task
    # and kill those that have been at it too long
    enforce_runtime_limit = function(timelimit, grace) {
      runtime <- vapply(
        private$workers,
        function(x) x$get_worker_runtime()["current"],
        as.difftime(NA_real_, units = "secs")
      )
      runtime <- as.numeric(runtime, units = "secs")
      too_long <- which(runtime > timelimit)
      for(i in too_long) {
        private$workers[[i]]$shutdown_worker(grace)
      }
    }
  )
)
