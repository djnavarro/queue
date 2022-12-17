test_that("WorkerPools initialise, shutdown, and refill", {

  # initialise
  workers <- WorkerPool$new(4)
  expect_true(inherits(workers, "WorkerPool"))
  expect_length(workers$get_pool_state(), 4)
  expect_equal(unname(workers$get_pool_state()), rep("idle", 4))

  # shutdown
  workers$shutdown_pool()
  Sys.sleep(.1)
  expect_true(inherits(workers, "WorkerPool"))
  expect_length(workers$get_pool_state(), 4)
  expect_equal(unname(workers$get_pool_state()), rep("finished", 4))

  # refill
  workers$refill_pool()
  Sys.sleep(.1)
  expect_true(inherits(workers, "WorkerPool"))
  expect_length(workers$get_pool_state(), 4)
  expect_equal(unname(workers$get_pool_state()), rep("idle", 4))

})
