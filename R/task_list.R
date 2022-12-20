#' R6 class storing a task list
#'
#' A task list is a container that holds a collection of tasks
#' @export
TaskList <- R6::R6Class(
  classname = "TaskList",

  public = list(
    #' @description Create a new task list
    initialize = function() {},

    #' @description Return the number of tasks in the list
    #' @return Integer
    length = function() {
      length(private$tasks)
    },

    #' @description Append a single task to the bottom of the `TaskList`
    #' @param task A `Task` object
    add_task = function(task) {
      private$tasks[[length(private$tasks) + 1L]] <- task
    },

    #' @description Remove one or more tasks from the `TaskList`
    #' @param x Indices or names of the tasks to remove
    remove_task = function(x) {
      private$tasks[x] <- NULL
    },

    #' @description Return a single `Task` contained in the `TaskList`
    #' @param x The index or name of the task to return
    #' @return A `Task` object
    get_task = function(x) {
      private$tasks[[x]]
    },

    #' @description Return a subset of the `TaskList` as another `TaskList`
    #' @param x The indices of the `Tasks` to retain
    #' @return A `TaskList` object
    subset = function(x) {
      subset_list <- TaskList$new()
      for(task in private$tasks[x]) {
        subset_list$add_task(task)
      }
      subset_list
    },

    #' @description Return a list of tasks in a given state
    #' @param x The name of the state (e.g., "waiting")
    #' @return A `TaskList` object
    subset_in_state = function(x) {
      which <- vapply(
        private$tasks,
        function(t) t$get_task_state() == x,
        logical(1)
      )
      self$subset(which)
    },

    #' @description Retrieve the full state of the tasks in tidy form. If
    #' all tasks have completed this output is the same as the output as the
    #' `run()` method for a `Queue` object.
    #' @return Returns a tibble containing the results of all executed tasks and
    #' various other useful metadata. Incomplete tasks may have missing data.
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

    #' @description Report an abbreviated summary of the tasks
    #' @return Returns a tibble with three columns: task_id, state, runtime
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
    }


  ),

  private = list(
    tasks = list()
  )
)
