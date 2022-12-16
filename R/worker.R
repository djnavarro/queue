#' R6 class storing a worker
#'
#' A Worker is a container that holds a callr rsession object, and possesses
#' fields and methods that allow it to work on Tasks
#' @export
Worker <- R6::R6Class(
  classname = "Worker",
  public = list(

    initialize = function() {
      private$session <- callr::r_session$new(wait = FALSE)
      private$session$initialize()
      private$worker_id <- private$session$get_pid()
    },

    get_worker_id = function() {
      private$worker_id
    },

    get_worker_state = function() {
      private$session$get_state()
    },

    get_worker_task = function() {
      private$task
    },

    get_worker_session = function() {
      private$session
    },

    try_assign = function(task) {
      if(is.null(private$task)) {
        private$task <- task
        private$task$task_assign(self$id)
        return(invisible(TRUE))
      }
      invisible(FALSE)
    },

    try_start = function() {
      if(!is.null(private$task) && private$task$get_task_state() == "assigned") {
        private$session$call(
          private$task$get_task_fun(),
          private$task$get_task_args()
        )
        private$task$task_start(self$id)
        return(invisible(TRUE))
      }
      invisible(FALSE)
    },

    try_finish = function(timeout = 0) {
      if(!is.null(private$task) && private$task$get_task_state() == "running") {
        if(private$session$poll_process(timeout) == "ready") {
          private$task$task_finish(private$session$read())
          private$task <- NULL
          return(invisible(TRUE))
        }
      }
      invisible(FALSE)
    },

    shutdown_worker = function(grace = 1000) {
      private$session$close(grace)
    }
  ),

  private = list(
    task = NULL,
    worker_id = NULL,
    session = NULL
  )
)
