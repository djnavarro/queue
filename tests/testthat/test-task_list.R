test_that("TaskLists initialise", {

  tasks <- TaskList$new()
  expect_true(inherits(tasks, "TaskList"))

})
