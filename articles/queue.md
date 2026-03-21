# queue

Sometimes you want to do “everything, everywhere, all at once”. When
that happens it’s awfully convenient if you have easy-to-use tools to
execute your R code in parallel across multiple R sessions. That’s the
goal of the queue package. It provides a clean interface implementing
multi-worker task queues in R that doesn’t ask the user to do very much
work.

## Another parallel computing tool

Anyone familiar with the R ecosystem knows that there are already many
good tools for this purpose. The queue package isn’t intended to be a
replacement for sophisticated distributed computing tools like
[futureverse](https://www.futureverse.org/) (not even close!). Nor is it
intended as a replacement for session management tools like
[callr](https://callr.r-lib.org/), upon on which queue is built. If you
find yourself needing flexible, highly performant tools, I recommend
both of those options thoroughly.

The reason queue exists is that, well, sometimes it’s nice to have an
adorably simple alternative. Not everyone in the R community has the
time and expertise to learn how to use fancy, but most of us have a
laptop, and that laptop has a bunch of cores that we sometimes forget to
use. With that in mind, queue is a deliberately simple tool with a
minimum of features.

Also – and I’ll be honest, this is the real reason it exists – I wanted
an excuse to make sure I really understood callr and
[R6](https://r6.r-lib.org/) and this felt like as good a side project as
any.

## Basic usage

The queue package adopts an encapsulated object-oriented programming
style, and uses R6 classes to manage task queues. The primary class in
the package is `Queue`. When a new task queue is created it also
initialises a new `WorkerPool`, a collection of R sessions in which
tasks will be executed. You can set the number of workers during
initialisation:

``` r
library(queue)
queue <- Queue$new(workers = 4)
```

Tasks are then pushed to the queue by calling it’s `add()` method. A
task is a function and a list of arguments. In the example below,
`wait()` is a function that sleeps for a specified length of time and
then returns its input. We’ll queue up 10 jobs that pause for different
lengths of time:

``` r
wait <- function(x) {
  Sys.sleep(x)
  x
}
for(i in 1:10) {
  queue$add(wait, list(x = i/10))
}
```

We execute the tasks by calling the `run()` method:

``` r
out <- queue$run(message = "verbose")
#> → Done: task_1 finished in 0.163 secs
#> → Done: task_2 finished in 0.288 secs
#> → Done: task_3 finished in 0.347 secs
#> → Done: task_4 finished in 0.452 secs
#> → Done: task_5 finished in 0.558 secs
#> → Done: task_6 finished in 0.645 secs
#> → Done: task_7 finished in 0.745 secs
#> → Done: task_8 finished in 0.85 secs
#> → Done: task_9 finished in 0.95 secs
#> → Done: task_10 finished in 1.05 secs
#> ✔ Queue complete: 10 tasks done in 2 secs
```

The output is stored in a tibble that contains a fairly detailed
representation of everything that happened during the execution of the
queue, including time stamps, any messages printed to the R console
during the execution of each function, and so on:

``` r
out
#> # A tibble: 10 × 17
#>    task_id worker_id state result runtime fun   args         created            
#>    <chr>       <int> <chr> <list> <drtn>  <lis> <list>       <dttm>             
#>  1 task_1       7497 done  <dbl>  0.1634… <fn>  <named list> 2026-03-21 10:27:53
#>  2 task_2       7515 done  <dbl>  0.2877… <fn>  <named list> 2026-03-21 10:27:53
#>  3 task_3       7533 done  <dbl>  0.3474… <fn>  <named list> 2026-03-21 10:27:53
#>  4 task_4       7551 done  <dbl>  0.4520… <fn>  <named list> 2026-03-21 10:27:53
#>  5 task_5       7497 done  <dbl>  0.5582… <fn>  <named list> 2026-03-21 10:27:53
#>  6 task_6       7515 done  <dbl>  0.6453… <fn>  <named list> 2026-03-21 10:27:53
#>  7 task_7       7533 done  <dbl>  0.7446… <fn>  <named list> 2026-03-21 10:27:53
#>  8 task_8       7551 done  <dbl>  0.8498… <fn>  <named list> 2026-03-21 10:27:53
#>  9 task_9       7497 done  <dbl>  0.9504… <fn>  <named list> 2026-03-21 10:27:53
#> 10 task_10      7515 done  <dbl>  1.0513… <fn>  <named list> 2026-03-21 10:27:53
#> # ℹ 9 more variables: queued <dttm>, assigned <dttm>, started <dttm>,
#> #   finished <dttm>, code <int>, message <chr>, stdout <list>, stderr <list>,
#> #   error <list>
```

The results of the function call are always stored in a list column
called `result` because in general there’s no guarantee that an
arbitrary collection of tasks will return results that are consistent
with each other, but in this case they are, so we can check the results
like this:

``` r
unlist(out$result)
#>  [1] 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0
```

By default, all the worker sessions are shutdown when the queue
completes, so the user doesn’t have to take care of that, but you can
override this and reuse a single `WorkerPool` across more than one
`Queue` if you want. See the classs documentation for details.

## Implementation detail

From the user point of view `Queue` objects are the most useful part of
the package, but internally most of the work is devolved to other
classes. Specifically, the package is built on top of two abstractions:
`Task` objects provide the storage class: they hold a function, its
arguments, its output, and a variety of other metadata. The `Worker`
class provides the representation of an external R session and the
ability to execute and manage a `Task` using that session. Internally,
the `Worker` class relies on
[callr::r_session](https://callr.r-lib.org/articles/r-session.html).

To allow a `Queue` to execute multiple jobs in parallel, there are two
additional classes provided by the queue package: a `TaskList` object is
a container that holds multiple `Task` objects and has some methods for
working with them, and similarly a `WorkerPool` is a container for
multiple `Worker` objects with tools for working with those. A `Queue`
is associated with a `WorkerPool` and a `TaskList`, and has methods that
will return each of these, should you ever have a need to play around
with the internal data structures.

## Crash resistance

The queue package isn’t very sophisticated in detecting sessions that
have crashed, but it does have some. For simplicity, let’s define a
function that is guaranteed to crash the R session as soon as it is
called:

``` r
crash <- function(x) .Call("abort")
```

Now let’s define a queue that has only two workers, but has no less than
three tasks that are guaranteed to crash the worker the moment the tasks
are started:

``` r
queue <- Queue$new(workers = 2)
queue$add(wait, list(x = .1))
queue$add(crash)
queue$add(crash)
queue$add(crash)
queue$add(wait, list(x = .1))
```

The queue allocates task in a first-in first-out order, so the three
“crash tasks” are guaranteed to be allocated before the final “wait
task”. Let’s take a look at what happens when the queue runs:

``` r
queue$run()
#> ✔ Queue complete: 5 tasks done in 0.364 secs
#> # A tibble: 5 × 17
#>   task_id worker_id state result runtime  fun   args         created            
#>   <chr>       <int> <chr> <list> <drtn>   <lis> <list>       <dttm>             
#> 1 task_1       7578 done  <dbl>  0.16684… <fn>  <named list> 2026-03-21 10:27:56
#> 2 task_2       7596 done  <NULL> 0.11196… <fn>  <list [0]>   2026-03-21 10:27:56
#> 3 task_3       7596 done  <NULL> 0.08076… <fn>  <list [0]>   2026-03-21 10:27:56
#> 4 task_4       7578 done  <NULL> 0.11052… <fn>  <list [0]>   2026-03-21 10:27:56
#> 5 task_5       7596 done  <dbl>  0.16120… <fn>  <named list> 2026-03-21 10:27:56
#> # ℹ 9 more variables: queued <dttm>, assigned <dttm>, started <dttm>,
#> #   finished <dttm>, code <int>, message <chr>, stdout <list>, stderr <list>,
#> #   error <list>
```

It’s a little slower than we’d hope, but it does finish both valid tasks
and returns nothing for the tasks that crashed their R sessions. What
has happened in the background is that the `Queue` runs a simple
scheduler that asks the `WorkerPool` to check if any of the R sessions
have crashed, and initialises new `Worker` objects to replace them if
that happens.

There is not even a *pretense* that any of this has been optimised, but
it does work.
