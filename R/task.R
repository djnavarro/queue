#' R6 Class Representing a Task
#'
#' @description
#' A `Task` stores a function, arguments, output, and metadata.
#'
#' @details
#' A `Task` object is used as a storage class. It is a container used to hold an
#' R function and any arguments to be passed to the function. It can also hold
#' any output returned by the function, anything printed to stdout or stderr
#' when the function is called, and various other metadata such as the process
#' id of the worker that executed the function, timestamps, and so on.
#'
#' The methods for `Task` objects fall into two groups, roughly speaking. The
#' `get_*()` methods are used to return information about the `Task`, and the
#' `register_*()` methods are used to register information related to events
#' relevant to the `Task` status.
#'
#' The `retrieve()` method is special, and returns a tibble containing all
#' information stored about the task. Objects further up the hierarchy use this
#' method to return nicely organised output that summarise the results from
#' many tasks.
#'
#' @export
Task <- R6::R6Class(
  classname = "Task",
  public = list(

    #' @description Create a new task. Conceptually, a `Task` is viewed as a
    #' function that will be executed by the `Worker` to which it is assigned,
    #' and it is generally expected that any resources the function requires
    #' are passed through the arguments since the execution context will be a
    #' different R session to the one in which the function is defined.
    #' @param fun The function to be called when the task executes.
    #' @param args A list of arguments to be passed to the function (optional).
    #' @param id A string specifying a unique task identifier (optional).
    #' @return A new `Task` object.
    initialize = function(fun, args = list(), id = NULL) {
      private$fun <- fun
      private$args <- args
      if(!is.null(id)) private$task_id <- id
      self$register_task_created()
    },

    #' @description Retrieve a tidy summary of the task state.
    #' @return A tibble containing a single row, and the following columns:
    #' * `task_id` A character string specifying the task identifier
    #' * `worker_id` An integer specifying the worker process id (pid)
    #' * `state` A character string indicating the task status ("created",
    #'   "waiting", "assigned", "running", or "done")
    #' * `result` A list containing the function output, or NULL
    #' * `runtime` Completion time for the task (NA if the task is not done)
    #' * `fun` A list containing the function
    #' * `args` A list containing the arguments
    #' * `created` The time at which the task was created
    #' * `queued` The time at which the task was added to a `Queue`
    #' * `assigned` The time at which the task was assigned to a `Worker`
    #' * `started` The time at which the `Worker` called the function
    #' * `finished` The time at which the `Worker` output was returned
    #' * `code` The status code returned by the callr R session (integer)
    #' * `message` The message returned by the callr R session (character)
    #' * `stdout` List containing the contents of stdout during function execution
    #' * `stderr` List containing the contents of stderr during function execution
    #' * `error`  List containing `NULL`
    #'
    #' Note: at present there is one field from the callr rsession::read() method
    #' that isn't captured here, and that's the error field. I'll add that after
    #' I've finished wrapping my head around what that actually does. The `error`
    #' column, at present, is included only as a placeholder
    #' @md
    retrieve = function() {

      # data structure to return to user
      out <- tibble::tibble(
        task_id = private$task_id,
        worker_id = private$worker_id,
        state = private$state,
        result = list(NULL),
        runtime = NA_real_,
        fun = list(private$fun),
        args = list(private$args),
        created = private$time_created,
        queued = private$time_queued,
        assigned = private$time_assigned,
        started = private$time_started,
        finished = private$time_finished,
        code = NA_integer_,
        message = NA_character_,
        stdout = list(NULL),
        stderr = list(NULL),
        error = list(NULL)
      )

      # populate fields from callr session
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
    #' When this method is called, the state of the `Task` is set to "created"
    #' and a timestamp is recorded, registering the creation time for the task.
    #' This method is intended to be called by `Worker` objects. Users should
    #' not need to call it.
    #' @return Returns `NULL` invisibly.
    register_task_created = function() {
      private$state <- "created"
      private$time_created <- Sys.time()
      invisible(NULL)
    },

    #' @description Register the addition of the task to a queue by updating
    #' internal storage. When this method is called, the state of the `Task`
    #' is set to "waiting" and a timestamp is recorded, registering the time
    #' at which the task was added to a queue. This method is intended to be
    #' called by `Worker` objects. Users should not need to call it.
    #' @return Returns `NULL` invisibly.
    register_task_waiting = function() {
      private$state <- "waiting"
      private$time_queued <- Sys.time()
      invisible(NULL)
    },

    #' @description Register the assignment of a task to a worker by updating
    #' internal storage. When this method is called, the state of the `Task`
    #' is set to "assigned" and a timestamp is recorded, registering the time
    #' at which the task was assigned to a `Worker`. In addition, the
    #' `worker_id` of the worker object (which is also it's pid) is registered
    #' with the task. This method is intended to be called by `Worker` objects.
    #' Users should not need to call it.
    #' @param worker_id Identifier for the worker to which the task is assigned.
    #' @return Returns `NULL` invisibly.
    register_task_assigned = function(worker_id) {
      private$state <- "assigned"
      private$worker_id <- worker_id
      private$time_assigned <- Sys.time()
      invisible(NULL)
    },

    #' @description Register the commencement of a task to a worker by updating
    #' internal storage. When this method is called, the state of the `Task` is
    #' set to "running" and a timestamp is recorded, registering the time at
    #' which the `Worker` called the task function. In addition, the `worker_id`
    #' is recorded, albeit somewhat unnecessarily since this information is
    #' likely already stored when `register_task_assigned()` is called. This
    #' method is intended to be called by `Worker` objects. Users should not
    #' need to call it.
    #' @param worker_id Identifier for the worker on which the task is starting.
    #' @return Returns `NULL` invisibly.
    register_task_running = function(worker_id) {
      private$state <- "running"
      private$worker_id <- worker_id
      private$time_started <- Sys.time()
      invisible(NULL)
    },

    #' @description Register the finishing of a task to a worker by updating
    #' internal storage. When this method is called, the state of the `Task` is
    #' set to "done" and a timestamp is recorded, registering the time at which
    #' the `Worker` returned results to the `Task`. The `results` object is
    #' read from the R session, and is stored locally by the `Task` at this time.
    #' This method is intended to be called by `Worker` objects. Users should
    #' not need to call it.
    #' @param results Results read from the R session.
    #' @return Returns `NULL` invisibly.
    register_task_done = function(results) {
      private$results <- results
      private$state <- "done"
      private$time_finished <- Sys.time()
    }
  ),

  private = list(
    fun = list(NULL),
    args = list(NULL),
    results = list(NULL),
    task_id = NA_character_,
    worker_id = NA_character_,
    state = NA_character_,
    time_created = NA_real_,
    time_queued = NA_real_,
    time_assigned = NA_real_,
    time_started = NA_real_,
    time_finished = NA_real_
  )
)

# I suppose if I were being rigorous this would be a NullTask object
# with a retrieve method but that feels a bit like overkill
no_task_output <- tibble::tibble(
    task_id = character(0),
    worker_id = character(0),
    state = character(0),
    result = list(),
    runtime = numeric(0),
    fun = list(),
    args = list(),
    created = numeric(0),
    queued = numeric(0),
    assigned = numeric(0),
    started = numeric(0),
    finished = numeric(0),
    code = numeric(0),
    message = character(0),
    stdout = list(),
    stderr = list(),
    error = list()
  )



