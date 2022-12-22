QueueMessenger <- R6::R6Class(
  classname = "QueueMessenger",

  public = list(

    initialize = function(tasks, message_type) {
      private$tasks <- tasks
      private$message_type <- message_type
      private$start_spinner()
    },

    post = function(state, finished_in = NULL) {

      # silent queues never post
      if(private$message_type == "none") return(invisible(state))

      # verbose queues interrupt the spinner to report task completions
      if(private$message_type == "verbose") {
        done <- which(state == "done")
        completions <- setdiff(done, private$done)
        if(length(completions) > 0) {
          private$done <- done
          private$stop_spinner()
          private$update_tasks(completions)
          private$start_spinner()
        }
      }

      # verbose & minimal queues display a spinner
      private$update_spinner(state)

      # verbose & minimal queues report completion summaries
      if(!is.null(finished_in)) {
        private$stop_spinner()
        private$update_final(state, finished_in)
      }

      invisible(state)
    }
  ),

  private = list(

    tasks = NULL,
    spinner = NULL,
    message_type = NULL,

    done = numeric(0),

    start_spinner = function() {
      private$spinner <- cli::make_spinner(
        which = "dots2",
        template = "{spin} Queue"
      )
    },

    update_spinner = function(state) {
      msg <- paste(
        "{spin} Queue progress:",
        sum(state == "waiting"),
        "waiting,",
        sum(state == "running"),
        "running,",
        sum(state == "done"),
        "done"
      )
      private$spinner$spin(msg)
    },

    stop_spinner = function() {
      private$spinner$finish()
    },

    update_tasks = function(ids) {
      for(id in ids) {
        task_id <- private$tasks$get_task(id)$get_task_id()
        runtime <- private$tasks$get_task(id)$get_task_runtime()
        msg <- paste(
          "Done:",
          task_id,
          "finished in",
          private$display_time(runtime)
        )
        cli::cli_alert(msg)
      }

    },

    update_final = function(state, finished_in) {
      msg <- paste(
        "Queue complete:",
        sum(state == "done"),
        "tasks done in",
        private$display_time(finished_in)
      )
      cli::cli_alert_success(msg)
    },

    # elapsed is a difftime
    display_time = function(elapsed) {
      format(elapsed, digits = 3)
    }
  )
)


