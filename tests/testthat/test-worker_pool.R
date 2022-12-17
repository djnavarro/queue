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


test_that("WorkerPools can batch assign/start/finish tasks (workers > tasks)", {

  # 3 waiting tasks, 4 idle workers (tasks are slow)
  tasks <- list(
    Task$new(function() Sys.sleep(.01)),
    Task$new(function() Sys.sleep(.01)),
    Task$new(function() Sys.sleep(.01))
  )
  workers <- WorkerPool$new(4)

  # try assign should leave all three tasks assigned
  workers$try_assign(tasks)
  state <- lapply(tasks, function(x) x$get_task_state())
  expect_equal(unname(unlist(state)), rep("assigned", 3))

  # try start should show three workers running, one idle
  workers$try_start()
  Sys.sleep(.2)
  expect_equal(
    unname(unlist(workers$get_pool_state())),
    c("busy", "busy", "busy", "idle")
  )

  # try finish should show all workers idle, all tasks done
  workers$try_finish()
  Sys.sleep(.2)
  state <- lapply(tasks, function(x) x$get_task_state())
  expect_equal(unname(unlist(state)), rep("done", 3))
  expect_equal(
    unname(unlist(workers$get_pool_state())),
    c("idle", "idle", "idle", "idle")
  )

  workers$shutdown_pool()
})



test_that("WorkerPools can batch assign/start/finish tasks (tasks > workers)", {

  # 5 waiting tasks, 4 idle workers (tasks are slow)
  tasks <- list(
    Task$new(function() Sys.sleep(.01)),
    Task$new(function() Sys.sleep(.01)),
    Task$new(function() Sys.sleep(.01)),
    Task$new(function() Sys.sleep(.01)),
    Task$new(function() Sys.sleep(.01))
  )
  workers <- WorkerPool$new(4)

  # try assign should leave all 4 tasks assigned, 1 waiting/created
  # would be "waiting" in the normal course of events when a TaskQueue
  # manages this, but I'm manually messing with it in the tests
  workers$try_assign(tasks)
  state <- lapply(tasks, function(x) x$get_task_state())
  expect_equal(unname(unlist(state)), c(rep("assigned", 4), "created"))

  # try start should show three workers running, one idle
  workers$try_start()
  Sys.sleep(.2)
  expect_equal(
    unname(unlist(workers$get_pool_state())),
    c("busy", "busy", "busy", "busy")
  )

  # try finish should show all workers idle, 4 tasks done, 1 waiting/created
  workers$try_finish()
  Sys.sleep(.2)
  state <- lapply(tasks, function(x) x$get_task_state())
  expect_equal(unname(unlist(state)), c(rep("done", 4), "created"))
  expect_equal(
    unname(unlist(workers$get_pool_state())),
    c("idle", "idle", "idle", "idle")
  )

})




