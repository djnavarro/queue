#' R6 Class Representing a Worker
#'
#' @description
#' A `Worker` manages an external R session and completes tasks.
#'
#' @details
#' The `Worker` class interacts with an external R session, and possesses
#' methods that allow it to work with `Task` objects. At its core, the
#' class is a thin wrapper around a `callr::r_session` object, and in fact
#' the session object itself can be obtained by calling the
#' `get_worker_session()` method. In most cases this shouldn't be necessary
#' however, because `Worker` objects are typically created as part of a
#' `WorkerPool` that is managed by a `Queue`, and those higher level structures
#' use the methods exposed by the `Worker` object.
#'
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
      private$started_at <- Sys.time() # remove when https://github.com/r-lib/callr/issues/241 is fixed
    },

    #' @description Retrieve the worker identifier.
    #' @return The worker identifier, which also the process id for the R session
    get_worker_id = function() {
      private$worker_id
    },

    #' @description Retrieve the worker state.
    #' @return A string specifying the current state of the R session. Possible
    #' values are:
    #' * `"starting"`: the R session is starting up.
    #' * `"idle"`: the R session is ready to compute.
    #' * `"busy"`: the R session is computing.
    #' * `"finished"`: the R session has terminated.
    #'
    #' Importantly, note that a task
    #' function that is still running and a task function that is essentially
    #' finished and waiting to return will both return "busy". To distinguish
    #' between these two cases you need to use the `poll_process()` method of
    #' a `callr::rsession`, as returned by `get_worker_session()`.
    #' @md
    get_worker_state = function() {
      private$session$get_state()
    },

    #' @description Return the total length of time the worker session
    #' has been running, and the length of the time that the current task
    #' has been running. If the session is finished both values are `NA`.
    #' If the session is idle (no task running) the total session time will
    #' return a value but the current task time will be `NA`.
    #' @return A vector of two difftimes.
    get_worker_runtime = function() {
      # after https://github.com/r-lib/callr/issues/241 resolves use this:
      # private$session$get_running_time()

      # temporary workaround:
      now <- Sys.time()
      finished <- private$session$get_state() == "finished"
      idle <- private$session$get_state() == "idle"
      no_uptime <- as.difftime(NA_real_, units = "secs")
      c(total = if (finished) no_uptime else now - private$started_at,
        current = if (finished | idle) no_uptime else now - private$fun_started_at)
    },

    #' @description Retrieve the task assigned to the worker.
    #' @return The `Task` object currently assigned to this `Worker`, or `NULL`.
    get_worker_task = function() {
      private$task
    },

    #' @description Retrieve the R session associated with a `Worker`
    #' @return An R session object, see `callr::r_session`
    get_worker_session = function() {
      private$session
    },

    #' @description Attempt to assign a task to this worker. This method checks
    #' that the task and the worker are both in an appropriate state. If they
    #' are, both objects register their connection to the other. This method is
    #' intended to be called by a `WorkerPool` or a `Queue`.
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
    #' or a `Queue`.
    #' @return Invisibly returns `TRUE` or `FALSE`, depending on whether the
    #' attempt was successful.
    try_start = function() {
      if(!is.null(private$task) && private$task$get_task_state() == "assigned") {
        private$session$call(
          private$task$get_task_fun(),
          private$task$get_task_args()
        )
        private$task$register_task_running(private$worker_id)
        private$fun_started_at <- Sys.time() # remove when https://github.com/r-lib/callr/issues/241 is fixed
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
    #' or a `Queue`.
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
          private$task$register_task_done(private$session$read())
          private$task <- NULL
          return(invisible(TRUE))
        }
      }
      invisible(FALSE)
    },

    #' @description Attempt to shut down the R session gracefully, after making
    #' an attempt to salvage any task that the worker believes it has been
    #' assigned. The salvage operation depends on the state of the task. If the
    #' `Task` has been assigned but not started, the `Worker` will return it
    #' to a "waiting" state in the hope that the `Queue` will assign it to
    #' another worker later, and unassign it. If the `Task` is running, the
    #' `Worker` will attempt to read from the R session and then register the
    #' `Task` as "done" regardless of the outcome. (The reason for this is to
    #' ensure that tasks that crash or freeze the R session don't get returned
    #' to the `Queue`).
    #' @param grace Grace period in milliseconds. If the process is still
    #' running after this period, it will be killed.
    shutdown_worker = function(grace = 1000) {

      # rescue task if possible
      if(length(private$task)) {

        task_state <- private$task$get_task_state()
        if(task_state == "assigned") {
          private$task$register_task_waiting()
          private$task <- NULL
        }
        if(task_state == "running") {
          result <- private$session$read()
          private$task$register_task_done(result)
          private$task <- NULL
        }
        if(task_state %in% c("done", "created")) {
          private$task <- NULL
        }
      }

      # send shutdown
      private$session$close(grace)
    }
  ),

  private = list(
    task = NULL,
    worker_id = NULL,
    session = NULL,
    started_at = as.POSIXct(NA),    # remove when https://github.com/r-lib/callr/issues/241 is fixed
    fun_started_at = as.POSIXct(NA) # remove when https://github.com/r-lib/callr/issues/241 is fixed
  )
)
