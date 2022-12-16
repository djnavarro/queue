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

test_that("Worker objects can work with tasks", {

  worker <- Worker$new()
  worker_id <- worker$get_worker_id()

  expect_null(worker$get_worker_task())
  expect_equal(worker$get_worker_state(), "idle")

  task <- Task$new(
    fun = function(x, y) {(2 + x) * y},
    args = list(x = 1, y = 2),
    id = "arith"
  )
  worker$try_assign(task)
  expect_equal(worker$get_worker_task(), task)
  expect_equal(task$get_task_state(), "assigned")
  expect_equal(worker$get_worker_state(), "idle")

  worker$try_start()
  expect_equal(task$get_task_state(), "running")
  expect_equal(worker$get_worker_state(), "busy")

  Sys.sleep(.05)
  worker$try_finish()
  Sys.sleep(.05)

  expect_equal(task$get_task_state(), "done")
  expect_equal(worker$get_worker_state(), "idle")
  expect_equal(worker$get_worker_task(), NULL)

  out <- task$retrieve()

  expect_equal(out$task_id, "arith")
  expect_equal(out$worker_id, worker_id)
  expect_equal(out$state, "done")
  expect_equal(out$result, list(6))
  expect_s3_class(out$runtime, "difftime")
  expect_equal(out$fun, list(function(x, y) {(2 + x) * y}))
  expect_equal(out$args, list(list(x = 1, y = 2)))

  expect_s3_class(out$created, "POSIXct")
  expect_equal(out$queued, NA_real_)
  expect_s3_class(out$assigned, "POSIXct")
  expect_s3_class(out$started, "POSIXct")
  expect_s3_class(out$finished, "POSIXct")

  expect_equal(out$code, 200L)
  expect_equal(class(out$message), "character")
  expect_equal(class(out$stdout), "list")
  expect_equal(class(out$stderr), "list")

})
