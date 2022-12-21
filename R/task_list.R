#' R6 class storing a task list
#'
#' The TaskList class is used as a storage class. It provides a container that
#' holds a collection of Task objects, along with a collection of methods for
#' adding, removing, and getting Tasks. It can also report on the status of the
#' Tasks contained within the list and retrieve results from those Tasks. What
#' it cannot do is manage interactions with Workers or arrange for the Tasks to
#' be executed. That's the job of the Queue.
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

    #' @description Add a task to the `TaskList`
    #' @param task The `Task` object to be added
    add_task = function(task) {
      private$tasks[[length(private$tasks) + 1L]] <- task
    },

    #' @description This method removes one or more tasks from the `TaskList`.
    #' @param x Indices of the tasks to be removed
    remove_task = function(x) {
      private$tasks[x] <- NULL
    },

    #' @description Return a single `Task` contained in the `TaskList`. The
    #' `Task` is not removed from the `TaskList`, and has reference semantics:
    #' if the listed task is completed by a `Worker`, then the status of any
    #' `Task` returned by this method will update automatically
    #' @param x The index the task to return
    #' @return A `Task` object
    get_task = function(x) {
      private$tasks[[x]]
    },

    #' @description Return the status of all tasks in the `TaskList`. If
    #' requested, this method will also display messages summarising the
    #' current state of the tasks, and any tasks that have completed since
    #' the last time a status was returned. This messaging system is called
    #' by `Queue` objects as they work on a tasks
    #' @param message Character specifying what type of message to display:
    #' "none" (the default), "minimal", or "verbose"
    #' @param finished_in A numeric value or a difftime specifying how long
    #' the tasks have taken to complete. This argument is only used when
    #' displaying messages, and it is used only to trigger the display of a
    #' tidy "all tasks completed" style message. It is purely cosmetic and
    #' does not affect the task status.
    #' @return A character vector specifying the completion status for all
    #' listed tasks
    get_state = function(message = "none", finished_in = NULL) {
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
    },

    #' @description Return a list of tasks in a given state
    #' @param x The name of the state (e.g., "waiting")
    #' @return A `TaskList` object
    get_tasks_in_state = function(x) {
      which <- vapply(
        private$tasks,
        function(t) t$get_task_state() == x,
        logical(1)
      )
      private$get_subset(which)
    },

    #' @description Retrieves the current state of all tasks.
    #'
    #' @return Returns a tibble containing the results of all tasks and
    #' various other useful metadata. Contains one row per task in the
    #' `TaskList`, and the following columns:
    #' * `task_id` A character string specifying the task identifiers
    #' * `worker_id` An integer specifying the worker process ids (pid)
    #' * `state` A character string indicating the status of each task
    #'   ("created", "waiting", "assigned", "running", or "done")
    #' * `result` A list containing the function outputs, or NULL
    #' * `runtime` Completion time for the task (NA if the task is not done)
    #' * `fun` A list containing the functions
    #' * `args` A list containing the arguments passed to each function
    #' * `created` The time at which each task was created
    #' * `queued` The time at which each task was added to a `Queue`
    #' * `assigned` The time at which each task was assigned to a `Worker`
    #' * `started` The time at which a `Worker` called each function
    #' * `finished` The time at which a `Worker` output was returned for the task
    #' * `code` The status code returned by the callr R session (integer)
    #' * `message` The message returned by the callr R session (character)
    #' * `stdout` List column containing the contents of stdout during function execution
    #' * `stderr` List column containing the contents of stderr during function execution
    #' * `error`  List column containing `NULL` values
    #'
    #' If all tasks have completed this output is the same as the output as the
    #' `run()` method for a `Queue` object.
    #'
    #' Note: at present there is one field from the callr rsession::read() method
    #' that isn't captured here, and that's the error field. I'll add that after
    #' I've finished wrapping my head around what that actually does. The `error`
    #' column, at present, is included only as a placeholder
    #' @md
    retrieve = function() {
      if(!self$length()) return(no_task_output)
      out <- lapply(private$tasks, function(x) x$retrieve())
      do.call(rbind, out)
    }
  ),

  private = list(

    tasks = list(),

    # subsets the tasks list
    get_subset = function(x) {
      subset_list <- TaskList$new()
      for(task in private$tasks[x]) {
        subset_list$add_task(task)
      }
      subset_list
    },

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
