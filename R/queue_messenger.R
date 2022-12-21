QueueMessenger <- R6::R6Class(
  classname = "QueueMessenger",

  public = list(

    initialize = function(tasks, message_type) {
      private$tasks <- tasks
      private$message_type <- message_type
      private$spinner <- private$make_spinner()
    },

    post = function(state, finished_in = NULL) {
      if(private$message_type == "none") return(invisible(state))
      if(private$message_type == "verbose") {
        done <- which(state == "done")
        just_done <- setdiff(done, private$done_last_update)
        if(length(just_done) > 0) {
          private$done_last_update <- done
          private$spinner$finish()
          for(id in just_done) cli::cli_alert(private$update_task_done(id))
          private$spinner <- private$make_spinner()
        }
      }
      if(private$message_type %in% c("verbose", "minimal")) {
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

    tasks = NULL,
    spinner = NULL,
    message_type = NULL,

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

    update_overall = function(state) {
      n_waiting <- sum(state == "waiting")
      n_running <- sum(state == "running")
      n_done <- sum(state == "done")
      paste("{spin} Queue progress:", n_waiting, "waiting", "\u1405",
            n_running, "running", "\u1405", n_done, "done")
    },

    update_task_done = function(id) {
      task_id <- private$tasks$get_task(id)$get_task_id()
      runtime <- private$tasks$get_task(id)$get_task_runtime()
      paste("Done:", task_id, "in", private$display_time(runtime))
    },

    update_final = function(state, finished_in) {
      cli::cli_alert_success(paste(
        "Queue complete:", sum(state == "done"),
        "tasks done in", private$display_time(finished_in)
      ))
    },

    # elapsed is a difftime
    display_time = function(elapsed) {
      format(elapsed, digits = 3)
    }
  )
)


