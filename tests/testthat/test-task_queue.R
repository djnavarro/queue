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
