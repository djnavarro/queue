test_that("TaskLists initialise", {

  tasks <- TaskList$new()

  report <- tasks$report()
  expect_true(inherits(report, "tbl_df"))
  expect_equal(nrow(report), 0)
  expect_equal(ncol(report), 3)
  expect_named(report, c("task_id", "state", "runtime"))

})
