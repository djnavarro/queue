#' R6 class storing a task
#'
#' A task is a container that holds a function and arguments, and eventually
#' the results of that function when called. Various metadata fields are stored.
#' @export
Task <- R6::R6Class(
  classname = "Task",
  public = list(

    #' @description Create a new task object.
    #' @param fun The function to be called when the task executes.
    #' @param args A list of arguments to be passed to the function (optional).
    #' @param id A string specifying a unique task identifier (optional).
    #' @param enqueue Should the task list itself as part of a queue (default = FALSE).
    #' @return A new `Task` object.
    initialize = function(fun, args = NULL, id = NULL, enqueue = FALSE) {
      private$fun <- fun
      if(!is.null(args)) private$args <- args
      if(!is.null(id)) private$task_id <- id
      self$task_create()
      if(enqueue) self$task_enqueue()
    },

    #' @description Retrieve a tidy summary of the task state.
    #' @return A tibble with one row
    retrieve = function() {

      out <- tibble::tibble(
        task_id = private$task_id,
        worker_id = private$worker_id,
        state = private$state,
        result = list(NULL),
        runtime = NA_real_,
        fun = list(private$fun),
        args = ifelse(length(args) == 1, list(NULL), args),
        created = private$time_created,
        enqueued = private$time_enqueued,
        assigned = private$time_assigned,
        started = private$time_started,
        finished = private$time_finished,
        code = NA_integer_,
        message = NA_character_,
        stdout = list(NULL),
        stderr = list(NULL)
      )

      if(inherits(private$results, "callr_session_result")) {
        out$runtime <- private$time_finished - private$time_started
        out$result <- list(private$results$result)
        out$code <- private$results$code
        out$message <- private$results$message
        out$stdout <- list(private$results$stdout)
        out$stderr <- list(private$results$stderr)
      }
      out
    },

    #' @description Retrieve the task function.
    #' @return A function.
    get_task_fun = function() {
      private$fun
    },

    #' @description Retrieve the task arguments
    #' @return A list.
    get_task_args = function() {
      private$args
    },

    #' @description Retrieve the task state.
    #' @return A string specifying the current state of the task. Possible
    #' values are "created" (task exists), "waiting" (task exists and is
    #' waiting in a queue), "assigned" (task has been assigned to a worker
    #' but has not yet started), "running" (task is running on a worker),
    #' or "done" (task is completed and results have been assigned back
    #' to the task object)
    get_task_state = function() {
      private$state
    },

    #' @description Retrieve the task id.
    #' @return A string containing the task identifier.
    get_task_id = function() {
      private$task_id
    },

    #' @description Retrieve the task runtime.
    #' @return If the task has completed, a difftime value. If the task has
    #' yet to complete, a `NA` value is returned
    get_task_runtime = function() {
      if(private$state != "done") return(NA_real_)
      private$time_finished - private$time_started
    },

    #' @description Register the task creation by updating internal storage.
    #' This is intended to be called by `Worker` objects. Users should not
    #' need to call it.
    #' @return The function is called for its side-effects. Returns `NULL`
    #' invisibly.
    task_create = function() {
      private$state <- "created"
      private$time_created <- Sys.time()
      invisible(NULL)
    },

    #' @description Register the addition of the task to a queue by updating
    #' internal storage. This is intended to be called by `Worker` objects.
    #' Users should not need to call it.
    #' @return The function is called for its side-effects. Returns `NULL`
    #' invisibly.
    task_enqueue = function() {
      private$state <- "waiting"
      private$time_enqueued <- Sys.time()
      invisible(NULL)
    },

    #' @description Register the assignment of a task to a worker by updating
    #' internal storage. This is intended to be called by `Worker` objects.
    #' Users should not need to call it.
    #' @param worker_id Identifier for the worker to which the task is assigned.
    #' @return The function is called for its side-effects. Returns `NULL`
    #' invisibly.
    task_assign = function(worker_id) {
      private$state <- "assigned"
      private$worker_id <- worker_id
      private$time_assigned <- Sys.time()
      invisible(NULL)
    },

    #' @description Register the commencement of a task to a worker by updating
    #' internal storage. This is intended to be called by `Worker` objects.
    #' Users should not need to call it.
    #' @param worker_id Identifier for the worker on which the task is starting.
    #' @return The function is called for its side-effects. Returns `NULL`
    #' invisibly.
    task_start = function(worker_id) {
      private$state <- "running"
      private$worker_id <- worker_id
      private$time_started <- Sys.time()
      invisible(NULL)
    },

    #' @description Register the finishing of a task to a worker by updating
    #' internal storage. This is intended to be called by `Worker` objects.
    #' Users should not need to call it.
    #' @param results Results read from the R session.
    #' @return The function is called for its side-effects. Returns `NULL`
    #' invisibly.
    task_finish = function(results) {
      private$results <- results
      private$state <- "done"
      private$time_finished <- Sys.time()
    }
  ),

  private = list(
    fun = NULL,
    args = list(NULL),
    results = list(NULL),
    task_id = NA_character_,
    worker_id = NA_character_,
    state = NA_character_,
    time_created = NA_real_,
    time_enqueued = NA_real_,
    time_assigned = NA_real_,
    time_started = NA_real_,
    time_finished = NA_real_
  )
)



