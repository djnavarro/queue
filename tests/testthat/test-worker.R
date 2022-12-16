test_that("Worker objects initialize R sessions", {

  worker <- Worker$new()
  expect_s3_class(worker, "Worker")

  session <- worker$get_worker_session()
  expect_s3_class(session, "r_session")

  expect_true(session$is_alive())
  expect_equal(worker$get_worker_state(), "idle")

  expect_equal(worker$get_worker_id(), session$get_pid())

  worker$shutdown_worker(grace = 0)
  expect_true(!session$is_alive())
  expect_equal(worker$get_worker_state(), "finished")



})
