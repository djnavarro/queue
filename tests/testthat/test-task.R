test_that("Task objects initialize", {

  task <- Task$new(fun = function() {2 + 2})
  expect_s3_class(task, "Task")

  task <- Task$new(
    fun = function(x, y) {(2 + x) * y},
    args = list(x = 1, y = 2),
    id = "arith"
  )
  expect_s3_class(task, "Task")
})

test_that("Task constituents are retrieved", {

  fun <- function(x, y) {(2 + x) * y}
  args <- list(x = 1, y = 2)
  id <- "arith"
  task <- Task$new(fun, args, id)

  expect_equal(task$get_task_args(), args)
  expect_equal(task$get_task_fun(), fun)
  expect_equal(task$get_task_id(), id)
  expect_equal(task$get_task_state(), "created")
  expect_equal(task$get_task_runtime(), NA_real_)
})

test_that("Task event registration functions work", {

  fun <- function(x, y) {(2 + x) * y}
  args <- list(x = 1, y = 2)
  id <- "arith"
  task <- Task$new(fun, args, id)
  expect_equal(task$get_task_state(), "created")

  task$register_task_queued()
  expect_equal(task$get_task_state(), "waiting")

  task$register_task_assigned(worker_id = 666)
  expect_equal(task$get_task_state(), "assigned")

  task$register_task_finished(results = "fake")
  expect_equal(task$get_task_state(), "done")

})

test_that("Task retrieve returns tibble", {

  task <- Task$new(fun = function() {2 + 2})
  cols <- c("task_id", "worker_id", "state", "result", "runtime", "fun",
            "args", "created", "enqueued", "assigned", "started", "finished",
            "code", "message", "stdout", "stderr")

  expect_s3_class(task$retrieve(), "tbl_df")
  expect_named(task$retrieve(), cols)
})

