# QueueMessenger is an R6 class that handles the public messaging
# behaviour of a Queue. It's not exported but it's partly documented
# here for the sake of my future sanity

#' @noRd
QueueMessenger <- R6::R6Class(
  classname = "QueueMessenger",

  public = list(

    #' @description Intialise the QueueMessenger
    #' @param tasks The `TaskList` object for the associated `Queue`
    #' @param message_type A character string specifying the type of messages
    #' to display: "none" means the `QueueMessenger` will do nothing and all
    #' calls to the `post()` method will return immediately, "minimal" means
    #' that a spinner will appear in the console and update the user with
    #' counts of the number of waiting, running, and finished tasks, and
    #' "verbose" means that (in addition to the spinner), every time a task
    #' completes a message will be printed for that task.
    initialize = function(tasks, message_type) {
      private$tasks <- tasks
      private$message_type <- message_type
      private$start_spinner()
    },

    #' @description This is the method used to generate messages
    #' @param state State vector for the `TaskList`. This is technically not
    #' needed because the `QueueMessenger` could look it up on its own, but in
    #' context this is included as an argument because the only time `post()` is
    #' called is in the private `schedule()` method in `Queue`, and at that point
    #' the scheduler has literally just asked the `TaskList` to retrieve the state
    #' @param finished_in A difftime. Used to indicate that the `Queue` is
    #' finishing (triggering the display of the completion message), and as a
    #' measure of the completion time.
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

    # storage
    tasks = NULL,
    spinner = NULL,
    message_type = NULL,

    # keeps track of the tasks known to have been done
    # at the time the last time the QueueMessenger posted
    done = numeric(0),

    # initialises a spinner object
    start_spinner = function() {
      private$spinner <- cli::make_spinner(
        which = "dots2",
        template = "{spin} Queue"
      )
    },

    # prints a nice message to the spinner
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

    # stops the spinner
    stop_spinner = function() {
      private$spinner$finish()
    },

    # prints completion messages for a set of tasks
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

    # prints completion messages for the queue
    update_final = function(state, finished_in) {
      msg <- paste(
        "Queue complete:",
        sum(state == "done"),
        "tasks done in",
        private$display_time(finished_in)
      )
      cli::cli_alert_success(msg)
    },

    # formats a difftime for display
    display_time = function(elapsed) {
      format(elapsed, digits = 3)
    }
  )
)


