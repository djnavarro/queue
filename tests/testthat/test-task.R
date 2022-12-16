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

})

