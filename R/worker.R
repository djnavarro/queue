#' R6 class storing a worker
#'
#' A Worker is a container that holds a callr rsession object, and possesses
#' fields and methods that allow it to work on Tasks
#' @export
Worker <- R6::R6Class(
  classname = "Worker",
  public = list(

    #' @description Create a new worker object.
    #' @return A new `Worker` object.
    initialize = function() {
      private$session <- callr::r_session$new(wait = FALSE)
      private$session$initialize()
      private$worker_id <- private$session$get_pid()
    },

    #' @description Retrieve the worker identifier.
    #' @return The worker identifier (also the pid for the R process)
    get_worker_id = function() {
      private$worker_id
    },

    #' @description Retrieve the worker state.
    #' @return A string specifying the current state of the task. Possible
    #' values are "starting" (the R session is starting up), "idle" (the R
    #' session is ready to compute), "busy" (the R session is computing), and
    #' "finished" (the R session has terminated). Importantly, note that a task
    #' function that is still running and a task function that is essentially
    #' finished and waiting to return will both return "busy". To distinguish
    #' between these two cases you need to use the `poll_process()` method of
    #' a `callr::rsession`, as returned by `get_worker_session()`.
    get_worker_state = function() {
      private$session$get_state()
    },

    #' @description Retrieve the task assigned to the worker.
    #' @return The `Task` object currently assigned to this `Worker`, or `NULL`.
    get_worker_task = function() {
      private$task
    },

    #' @description Retrieve the R session linked to the worker
    #' @return An R session object, see `callr::r_session`
    get_worker_session = function() {
      private$session
    },

    #' @description Attempt to assign a task to this worker. This method checks
    #' that the task and the worker are both in an appropriate state. If they
    #' are, both objects register their connection to the other. This method is
    #' intended to be called by a `WorkerPool` or a `TaskQueue`.
    #' @param task A `Task` object corresponding to the to-be-assigned task.
    #' @return Invisibly returns `TRUE` or `FALSE`, depending on whether the
    #' attempt was successful.
    try_assign = function(task) {
      if(is.null(private$task)) {
        private$task <- task
        private$task$register_task_assigned(private$worker_id)
        return(invisible(TRUE))
      }
      invisible(FALSE)
    },

    #' @description Attempt to start the task. This method checks to see if the
    #' that worker has an assigned task, and if so starts it running within the
    #' R session. It also registers the change of status within the `Task`
    #' object itself. This method is intended to be called by a `WorkerPool`
    #' or a `TaskQueue`.
    #' @return Invisibly returns `TRUE` or `FALSE`, depending on whether the
    #' attempt was successful.
    try_start = function() {
      if(!is.null(private$task) && private$task$get_task_state() == "assigned") {
        private$session$call(
          private$task$get_task_fun(),
          private$task$get_task_args()
        )
        private$task$register_task_started(private$worker_id)
        return(invisible(TRUE))
      }
      invisible(FALSE)
    },

    #' @description Attempt to finish a running task politely. This method checks
    #' to see if the worker has a running task, and if so polls the R session to
    #' determine if the R process claims to be ready to return. If there is a
    #' ready-to-return task the results are read from the R process and returned
    #' to the `Task` object. The task status is updated, and then unassigned
    #' from the `Worker`. This method is intended to be called by a `WorkerPool`
    #' or a `TaskQueue`.
    #' @param timeout Length of time to wait when process is polled (default = 0)
    #' @return Invisibly returns `TRUE` or `FALSE`, depending on whether the
    #' attempt was successful.
    try_finish = function(timeout = 0) {

      # if the worker does not have a task, don't try
      if(is.null(private$task)) return(invisible(FALSE))

      # if the session claims to be busy and the task claims to be running,
      # we poll politely and only read out the result if the process signals
      # that it is ready
      is_running <- private$task$get_task_state() == "running"
      is_busy <- private$session$get_state() == "busy"
      if(is_running && is_busy) {
        is_ready <- private$session$poll_process(timeout) == "ready"
        if(is_ready) {
          private$task$register_task_finished(private$session$read())
          private$task <- NULL
          return(invisible(TRUE))
        }
      }


      invisible(FALSE)
    },

    #' @description Attempt to shut down the R session gracefully
    #' @param grace Grace period in milliseconds. If the process is still
    #' running after this period, it will be killed.
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
