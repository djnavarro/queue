test_that("TaskQueue works at start up", {

  queue <- TaskQueue$new(workers = 2)

  expect_true(inherits(queue, "TaskQueue"))
  expect_true(inherits(queue$get_queue_workers(), "WorkerPool"))

  report <- queue$get_queue_report()
  expect_true(inherits(report, "tbl_df"))
  expect_equal(nrow(report), 0)
  expect_equal(ncol(report), 3)
  expect_named(report, c("task_id", "state", "runtime"))

})

test_that("TaskQueue can push tasks", {

  queue <- TaskQueue$new(workers = 2)
  queue$push(function() Sys.sleep(.1))
  queue$push(function() Sys.sleep(.1))
  queue$push(function() Sys.sleep(.1))

  report <- queue$get_queue_report()
  expect_true(inherits(report, "tbl_df"))
  expect_equal(nrow(report), 3)
  expect_equal(ncol(report), 3)
  expect_named(report, c("task_id", "state", "runtime"))
  expect_equal(report$state, c("waiting", "waiting", "waiting"))

})

test_that("TaskQueue can execute tasks", {

  queue <- TaskQueue$new(workers = 2)
  workers <- queue$get_queue_workers()

  queue$push(function() Sys.sleep(.1))
  queue$push(function() Sys.sleep(.1))
  queue$push(function() Sys.sleep(.1))
  out <- queue$run(message = "none", shutdown = TRUE)
  Sys.sleep(.2)

  report <- queue$get_queue_report()
  expect_true(inherits(report, "tbl_df"))
  expect_equal(nrow(report), 3)
  expect_equal(ncol(report), 3)
  expect_named(report, c("task_id", "state", "runtime"))
  expect_equal(report$state, c("done", "done", "done"))

  # check the auto-shutdown
  expect_equal(unname(workers$get_pool_state()), c("finished", "finished"))

})


test_that("TaskQueue output looks right", {

  queue <- TaskQueue$new(workers = 2)
  workers <- queue$get_queue_workers()

  out <- queue$retrieve()
  expect_true(inherits(out, "tbl_df"))
  expect_equal(nrow(out), 0)
  expect_equal(ncol(out), 16)
  expect_named(out, c("task_id", "worker_id", "state", "result", "runtime", "fun",
                      "args", "created", "queued", "assigned", "started", "finished",
                      "code", "message", "stdout", "stderr"))

  queue$push(function() Sys.sleep(.1))
  queue$push(function() Sys.sleep(.1))
  queue$push(function() Sys.sleep(.1))

  out <- queue$retrieve()
  expect_true(inherits(out, "tbl_df"))
  expect_equal(nrow(out), 3)
  expect_equal(ncol(out), 16)
  expect_named(out, c("task_id", "worker_id", "state", "result", "runtime", "fun",
                      "args", "created", "queued", "assigned", "started", "finished",
                      "code", "message", "stdout", "stderr"))

  out <- queue$run(message = "none", shutdown = TRUE)
  Sys.sleep(.2)

  expect_true(inherits(out, "tbl_df"))
  expect_equal(nrow(out), 3)
  expect_equal(ncol(out), 16)
  expect_named(out, c("task_id", "worker_id", "state", "result", "runtime", "fun",
                      "args", "created", "queued", "assigned", "started", "finished",
                      "code", "message", "stdout", "stderr"))

})


test_that("Verbose output produces spinner and task reports", {

  queue <- TaskQueue$new(workers = 2)
  queue$push(function() Sys.sleep(.1))
  queue$push(function() Sys.sleep(.1))
  queue$push(function() Sys.sleep(.1))
  msg <- capture.output(out <- queue$run(message = "verbose"), type = "message")

  # printed something to message corresponding to expected message events
  expect_true(length(grep("{spin}", msg, fixed = TRUE)) > 0) # spinner
  expect_true(length(grep("Task done:", msg, fixed = TRUE)) > 0) # cli_alert prefix
  expect_true(length(grep("Queue complete", msg, fixed = TRUE)) > 0) # final

})


test_that("Tasks that exceed runtime limits are shutdown", {

  # workers 1 and 3 will complete, 2 will be killed without returning
  queue <- TaskQueue$new(workers = 3)
  queue$push(function() {Sys.sleep(.1); TRUE})
  queue$push(function() {Sys.sleep(10); TRUE})
  queue$push(function() {Sys.sleep(.1); TRUE})
  out <- queue$run(timelimit = .5, message = "none")

  expect_true(inherits(out, "tbl_df"))
  expect_equal(out$code, c(200, NA, 200))
  expect_equal(out$state, c("done", "done", "done"))
  expect_equal(out$result, list(TRUE, NULL, TRUE))

})


test_that("Tasks that crash the thread are caught by runtime limits", {

  # workers 1 and 3 will complete, 2 crashes before returning
  queue <- TaskQueue$new(workers = 3)
  queue$push(function() {Sys.sleep(.1); TRUE})
  queue$push(function() {.Call("abort"); TRUE})
  queue$push(function() {Sys.sleep(.1); TRUE})
  out <- queue$run(timelimit = .5, message = "none")

  expect_true(inherits(out, "tbl_df"))
  expect_equal(out$code, c(200, NA, 200))
  expect_equal(out$state, c("done", "done", "done"))
  expect_equal(out$result, list(TRUE, NULL, TRUE))

})


