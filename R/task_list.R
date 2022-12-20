#' R6 class storing a task list
#'
#' A task list is a container that holds a collection of tasks
#' @export
TaskList <- R6::R6Class(
  classname = "TaskList",

  public = list(
    #' @description Create a new task list
    initialize = function() {
      private$spinner <- private$make_spinner()
    },

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

    #' @description Update the user on the current state of the `TaskList`
    #' @param message Character specifying whether the message type: "none",
    #' "minimal" (the default), or "verbose"
    #' @param finished_in Specifies the finishing time, and triggers a task completion
    #' message
    #' @return Invisibly returns a vector of the states of all tasks
    status = function(message, finished_in = NULL) {
      state <- vapply(
        private$tasks,
        function(t) t$get_task_state(),
        character(1)
      )
      if(message == "none") return(invisible(state))
      if(message == "verbose") {
        done <- private$which_tasks_done()
        just_done <- setdiff(done, private$done_last_update)
        if(length(just_done) > 0) {
          private$done_last_update <- done
          private$spinner$finish()
          for(id in just_done) cli::cli_alert(private$update_task_done(id))
          private$spinner <- private$make_spinner()
        }
      }
      if(message %in% c("verbose", "minimal")) {
        private$spinner$spin(private$update_overall(state))
      }
      if(!is.null(finished_in)) {
        private$spinner$finish()
        private$update_final(state, finished_in)
      }
      invisible(state)
    }
  ),

  private = list(

    tasks = list(),

    which_tasks_done = function() {
      which(vapply(
        private$tasks,
        function(t) t$get_task_state() == "done",
        logical(1)
      ))
    },

    done_last_update = numeric(0),

    make_spinner = function() {
      cli::make_spinner(which = "dots2", template = "{spin} Queue")
    },

    spinner = NULL,

    update_overall = function(state) {
      n_waiting <- sum(state == "waiting")
      n_running <- sum(state == "running")
      n_done <- sum(state == "done")
      paste("{spin} Queue progress:", n_waiting, "waiting", "\u1405",
            n_running, "running", "\u1405", n_done, "done")
    },

    update_task_done = function(id) {
      task_id <- private$tasks[[id]]$get_task_id()
      runtime <- private$tasks[[id]]$get_task_runtime()
      paste0("Task done: ", task_id, " (", round(as.numeric(runtime), 2), "s)")
    },

    update_final = function(state, finished_in) {
      cli::cli_alert_success(paste0(
        "Queue complete: ", sum(state == "done"),
        " tasks done", " (", round(as.numeric(finished_in), 2), "s)"
      ))
    }
  )
)
