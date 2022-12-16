#' R6 class storing a task
#'
#' A task is a container that holds a function and arguments, and eventually
#' the results of that function when called. Various metadata fields are stored.
#' @export
Task <- R6::R6Class(
  classname = "Task",
  public = list(

    initialize = function(fun, args = NULL, id = NULL, enqueue = FALSE) {
      private$fun <- fun
      if(!is.null(args)) private$args <- args
      if(!is.null(id)) private$task_id <- id
      self$task_create()
      if(enqueue) self$task_enqueue()
    },

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

    get_task_fun = function() {
      private$fun
    },

    get_task_args = function() {
      private$args
    },

    get_task_state = function() {
      private$state
    },

    get_task_id = function() {
      private$task_id
    },

    task_create = function() {
      private$state <- "created"
      private$time_created <- Sys.time()
    },

    task_enqueue = function() {
      private$state <- "waiting"
      private$time_enqueued <- Sys.time()
    },

    task_assign = function(worker_id) {
      private$state <- "assigned"
      private$worker_id <- worker_id
      private$time_assigned <- Sys.time()
    },

    task_start = function(worker_id) {
      private$state <- "running"
      private$worker_id <- worker_id
      private$time_started <- Sys.time()
    },

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




