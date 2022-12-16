#' R6 class storing a pool of workers
#'
#' A WorkerPool is a container that holds one or more workers and can request
#' them to assign tasks, start tasks, and complete tasks. It can also check to
#' see if any worker sessions have crashed and restart them as needed.
#' fields and methods that allow it to work on Tasks
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

    #' @description Return a specific worker
    #' @param ind The index of the worker in the pool
    #' @return The corresponding `Worker` object.
    get_pool_worker = function(ind) {
      private$workers[[ind]]
    },

    #' @description Return a simple summary of the worker pool
    #' @return A named character vector specifying the current state
    #' of each worker ("starting", "idle", "busy", or "finished"). Names
    #' denote worker ids
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
    #' intended to be called by `TaskQueue` objects.
    #' @param tasks A list of `Task` objects
    #' @return Invisibly returns `NULL`
    try_assign = function(tasks) {
      n_workers <- length(private$workers)
      n_tasks <- length(tasks)
      w <- 1
      t <- 1
      while(n_workers > 0 & n_tasks > 0) {
        assigned <- private$workers[[w]]$try_assign(tasks[[t]])
        w <- w + 1
        n_workers <- n_workers - 1
        if(assigned) {
          t <- t + 1
          n_tasks <- n_tasks - 1
        }
      }
      invisible(NULL)
    },

    #' @description Attempt to start any assigned but not-yet-started tasks
    #' in the worker pool. This method is intended to be called by `TaskQueue`
    #' objects.
    #' @return Invisibly returns `NULL`
    try_start = function() {
      lapply(private$workers, function(x) x$try_start())
      invisible(NULL)
    },

    #' @description Attempt to finish any started but not-yet-returned tasks
    #' in the worker pool. This method is intended to be called by `TaskQueue`
    #' objects.
    #' @return Invisibly returns `NULL`
    try_finish = function() {
      lapply(private$workers, function(x) x$try_finish())
      invisible(NULL)
    },

    #' @description Check all workers in the pool looking for workers that
    #' have crashed or been shutdown, and replace them with fresh workers.
    #' @return This function is called primarily for its side effect. It
    #' returns a named character documenting the outcome, indicating the
    #' current state of each worker: should not be "finished" for any worker.
    #' Names denote worker ids.
    refill_pool = function() {
      fin <- which(self$get_pool_state() == "finished")
      if(length(fin)) {
        for(i in seq_len(fin)) private$workers[fin][[i]] <- Worker$new()
      }
      self$get_pool_state()
    },

    #' @description Terminate all workers in the worker pool.
    #' @return This function is called primarily for its side effect. It
    #' returns a named character documenting the outcome, indicating the
    #' current state of each worker: should be "finished" for all workers.
    #' Names denote worker ids.
    shutdown_pool = function() {
      lapply(private$workers, function(x) x$shutdown_worker())
      self$get_pool_state()
    }
  ),

  private = list(
    workers = list()
  )
)
