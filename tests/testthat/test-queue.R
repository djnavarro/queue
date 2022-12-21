test_that("Queue works at start up", {

  queue <- Queue$new(workers = 2)

  expect_true(inherits(queue, "Queue"))
  expect_true(inherits(queue$get_workers(), "WorkerPool"))
  expect_true(inherits(queue$get_tasks(), "TaskList"))

})

test_that("Queue can push tasks", {

  queue <- Queue$new(workers = 2)
  queue$add(function() Sys.sleep(.1))
  queue$add(function() Sys.sleep(.1))
  queue$add(function() Sys.sleep(.1))

  tasks <- queue$get_tasks()
  expect_equal(tasks$length(), 3)

})

test_that("Queue can execute tasks", {

  queue <- Queue$new(workers = 2)
  workers <- queue$get_workers()

  queue$add(function() Sys.sleep(.1))
  queue$add(function() Sys.sleep(.1))
  queue$add(function() Sys.sleep(.1))
  out <- queue$run(message = "none", shutdown = TRUE)
  Sys.sleep(.2)

  tasks <- queue$get_tasks()
  state <- tasks$get_state()
  expect_equal(state, c("done", "done", "done"))

  # check the auto-shutdown
  expect_equal(unname(workers$get_pool_state()), c("finished", "finished"))

})


test_that("Queue output looks right", {

  queue <- Queue$new(workers = 2)
  workers <- queue$get_workers()

  col_names <- c("task_id", "worker_id", "state", "result", "runtime", "fun",
                 "args", "created", "queued", "assigned", "started", "finished",
                 "code", "message", "stdout", "stderr", "error")

  out <- queue$get_tasks()$retrieve()
  expect_true(inherits(out, "tbl_df"))
  expect_equal(nrow(out), 0)
  expect_equal(ncol(out), 17)
  expect_named(out, col_names)

  queue$add(function() Sys.sleep(.1))
  queue$add(function() Sys.sleep(.1))
  queue$add(function() Sys.sleep(.1))

  out <- queue$get_tasks()$retrieve()
  expect_true(inherits(out, "tbl_df"))
  expect_equal(nrow(out), 3)
  expect_equal(ncol(out), 17)
  expect_named(out, col_names)

  out <- queue$run(message = "none", shutdown = TRUE)
  Sys.sleep(.2)

  expect_true(inherits(out, "tbl_df"))
  expect_equal(nrow(out), 3)
  expect_equal(ncol(out), 17)
  expect_named(out, col_names)

})


test_that("Verbose output produces spinner and task reports", {

  queue <- Queue$new(workers = 2)
  queue$add(function() Sys.sleep(.1))
  queue$add(function() Sys.sleep(.1))
  queue$add(function() Sys.sleep(.1))
  msg <- capture.output(out <- queue$run(message = "verbose"), type = "message")

  # printed something to message corresponding to expected message events
  expect_true(length(grep("{spin}", msg, fixed = TRUE)) > 0) # spinner
  expect_true(length(grep("Task done:", msg, fixed = TRUE)) > 0) # cli_alert prefix
  expect_true(length(grep("Queue complete", msg, fixed = TRUE)) > 0) # final

})


test_that("Tasks that exceed runtime limits are shutdown", {

  # workers 1 and 3 will complete, 2 will be killed without returning
  queue <- Queue$new(workers = 3)
  queue$add(function() {Sys.sleep(.1); TRUE})
  queue$add(function() {Sys.sleep(10); TRUE})
  queue$add(function() {Sys.sleep(.1); TRUE})
  out <- queue$run(timelimit = .5, message = "none")

  expect_true(inherits(out, "tbl_df"))
  expect_equal(out$code, c(200, NA, 200))
  expect_equal(out$state, c("done", "done", "done"))
  expect_equal(out$result, list(TRUE, NULL, TRUE))

})


test_that("Tasks that crash the thread are caught by runtime limits", {

  # workers 1 and 3 will complete, 2 crashes before returning
  queue <- Queue$new(workers = 3)
  queue$add(function() {Sys.sleep(.1); TRUE})
  queue$add(function() {.Call("abort"); TRUE})
  queue$add(function() {Sys.sleep(.1); TRUE})
  out <- queue$run(timelimit = .5, message = "none")

  expect_true(inherits(out, "tbl_df"))
  expect_equal(out$state, c("done", "done", "done"))
  expect_equal(out$result, list(TRUE, NULL, TRUE))

  # these codes are inconsistent across operating systems
  # when crashes happen... commenting this line out for
  # now. the main thing is the result anyway?
  # expect_equal(out$code, c(200, NA, 200))

})


