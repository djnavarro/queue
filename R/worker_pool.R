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

    initialize = function(workers = 4L) {
      for(i in seq_len(workers)) self$pool[[i]] <- Worker$new()
    },

    pool = list(),

    try_assign = function(tasks) {
      n_workers <- length(self$pool)
      n_tasks <- length(tasks)
      w <- 1
      t <- 1
      while(n_workers > 0 & n_tasks > 0) {
        assigned <- self$pool[[w]]$try_assign(tasks[[t]])
        w <- w + 1
        n_workers <- n_workers - 1
        if(assigned) {
          t <- t + 1
          n_tasks <- n_tasks - 1
        }
      }
    },

    try_start = function() {
      lapply(self$pool, function(x) x$try_start())
    },

    try_finish = function() {
      lapply(self$pool, function(x) x$try_finish())
    },

    refill_pool = function() {
      fin <- which(self$state == "finished")
      if(length(fin)) {
        for(i in seq_len(fin)) self$pool[fin][[i]] <- Worker$new()
      }
    }
  ),

  active = list(
    state = function() vapply(self$pool, function(x) x$state, character(1))
  )
)
