test_that("Worker objects initialize R sessions", {

  worker <- Worker$new()
  expect_s3_class(worker, "Worker")

  session <- worker$get_worker_session()
  expect_s3_class(session, "r_session")

  expect_true(session$is_alive())
  expect_equal(worker$get_worker_state(), "idle")

  expect_equal(worker$get_worker_id(), session$get_pid())

  worker$shutdown_worker(grace = 0)
  Sys.sleep(.2)

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
  Sys.sleep(.2)

  expect_equal(task$get_task_state(), "running")
  expect_equal(worker$get_worker_state(), "busy")

  worker$try_finish()
  Sys.sleep(.2)

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

test_that("Workers can report running time", {

  worker <- Worker$new()
  task <- Task$new(function() {2 + 2})

  # when rsession exists and no task is running, only task is NA
  expect_s3_class(worker$get_worker_runtime(), "difftime")
  expect_length(worker$get_worker_runtime(), 2)
  expect_named(worker$get_worker_runtime(), c("total", "current"))
  expect_equal(unname(is.na(worker$get_worker_runtime())), c(FALSE, TRUE))

  # when task is running, neither is NA
  worker$try_assign(task)
  worker$try_start()
  Sys.sleep(.2)
  expect_equal(unname(is.na(worker$get_worker_runtime())), c(FALSE, FALSE))

  # when session is finished both are NA
  worker$try_finish()
  worker$shutdown_worker(grace = 0)
  Sys.sleep(.2)
  expect_equal(unname(is.na(worker$get_worker_runtime())), c(TRUE, TRUE))

})


test_that("Worker shutdown tries to rescue tasks", {

  task <- Task$new(function() 2 + 2)

  # assigned but not-running tasks return to waiting
  worker <- Worker$new()
  worker$try_assign(task)
  worker$shutdown_worker(grace = 0)
  expect_equal(worker$get_worker_state(), "finished")
  expect_equal(task$get_task_state(), "waiting")

  # running tasks attempt to finish and move to done
  # this is a case where the function should be ready,
  # but oops we forgot to explicitly call try_finish()
  worker <- Worker$new()
  worker$try_assign(task)
  worker$try_start()
  Sys.sleep(.2)                     # allow worker to finish computing but..
  worker$shutdown_worker(grace = 0) # ...shutdown without try_finish
  expect_equal(worker$get_worker_state(), "finished")   # session is finished
  expect_equal(task$get_task_state(), "done")           # task is done
  out <- task$retrieve()
  expect_equal(out$result, list(4)) # result is stored
  expect_equal(out$code, 200)       # good code stored

  # a task that will crash the R session
  task <- Task$new(function() .Call("abort"))

  # as above, except the worker session has crashed/stalled before return
  # (note: possibly OS differences here? check later)
  worker <- Worker$new()
  worker$try_assign(task)
  worker$try_start()
  expect_equal(task$get_task_state(), "running")      # okay, we're running...
  Sys.sleep(.2)                                       # allow worker time to crash :)
  worker$shutdown_worker(grace = 0)                   # so controller gives up
  expect_equal(worker$get_worker_state(), "finished") # ...worker has stopped
  expect_equal(task$get_task_state(), "done")         # ...task is "done"
  out <- task$retrieve()
  expect_equal(out$result, list(NULL))                # no result was returned

})
