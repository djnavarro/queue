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
      self$id <- private$session$get_pid()
    },

    id = NULL,

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
    }
  ),

  active = list(
    state = function() private$session$get_state()
  ),

  private = list(
    task = NULL,
    session = NULL
  )
)
