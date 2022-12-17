
# very thin wrapper because really TaskList should be an object, but not
# currently exported because ugh this API...
TaskList <- R6::R6Class(
  classname = "TaskList",

  public = list(
    initialize = function() {},

    length = function() {
      length(private$tasks)
    },

    push = function(task) {
      private$tasks[[length(private$tasks) + 1L]] <- task
    },

    retrieve = function() {
      if(!self$length()) {
        out <- tibble::tibble(
          task_id = character(0),
          worker_id = character(0),
          state = character(0),
          result = list(),
          runtime = numeric(0),
          fun = list(),
          args = list(),
          created = as.POSIXct(numeric(0)),
          queued = as.POSIXct(numeric(0)),
          assigned = as.POSIXct(numeric(0)),
          started = as.POSIXct(numeric(0)),
          finished = as.POSIXct(numeric(0)),
          code = integer(0),
          message = character(0),
          stdout = list(),
          stderr = list()
        )
        return(out)
      }
      out <- lapply(private$tasks, function(x) x$retrieve())
      do.call(rbind, out)
    },

    report = function() {
      if(!self$length()) {
        r <- tibble::tibble(
          task_id = character(0),
          state = character(0),
          runtime = numeric(0)
        )
        return(r)
      }
      tibble::tibble(
        task_id = unlist(lapply(private$tasks, function(x) x$get_task_id())),
        state = unlist(lapply(private$tasks, function(x) x$get_task_state())),
        runtime = unlist(lapply(private$tasks, function(x) x$get_task_runtime()))
      )
    },

    with_state = function(value) {
      which <- vapply(
        private$tasks,
        function(x) x$get_task_state() == value,
        logical(1)
      )
      private$tasks[which]
    }

  ),

  private = list(
    tasks = list()
  )
)
