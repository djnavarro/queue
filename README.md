
<!-- README.md is generated from README.Rmd. Please edit that file -->

# queue

<!-- badges: start -->

[![R-CMD-check](https://github.com/djnavarro/queue/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/djnavarro/queue/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/djnavarro/queue/branch/main/graph/badge.svg)](https://app.codecov.io/gh/djnavarro/queue?branch=main)
<!-- badges: end -->

Sometimes you want to do “everything, everywhere, all at once”. When
that happens it’s awfully convenient if you have easy-to-use tools to
execute your R code in parallel across multiple R sessions. That’s the
goal of the queue package. It provides a clean interface implementing
multi-worker task queues in R that doesn’t ask the user to do very much
work.

## Installation

You can install the development version of queue like so:

``` r
remotes::install_github("djnavarro/queue")
```

## Example

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
#> → Task done: task_1 (0.17s)
#> → Task done: task_2 (0.3s)
#> → Task done: task_3 (0.36s)
#> → Task done: task_4 (0.48s)
#> → Task done: task_5 (0.53s)
#> → Task done: task_6 (0.64s)
#> → Task done: task_7 (0.76s)
#> → Task done: task_8 (0.86s)
#> → Task done: task_9 (0.97s)
#> → Task done: task_10 (1.07s)
#> ✔ Queue complete: 10 tasks done (2.03s)
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
#>  1 task_1     335633 done  <dbl>  0.1723… <fn>  <named list> 2022-12-21 16:43:57
#>  2 task_2     335645 done  <dbl>  0.2955… <fn>  <named list> 2022-12-21 16:43:57
#>  3 task_3     335657 done  <dbl>  0.3587… <fn>  <named list> 2022-12-21 16:43:57
#>  4 task_4     335669 done  <dbl>  0.4754… <fn>  <named list> 2022-12-21 16:43:57
#>  5 task_5     335633 done  <dbl>  0.5304… <fn>  <named list> 2022-12-21 16:43:57
#>  6 task_6     335645 done  <dbl>  0.6419… <fn>  <named list> 2022-12-21 16:43:57
#>  7 task_7     335657 done  <dbl>  0.7579… <fn>  <named list> 2022-12-21 16:43:57
#>  8 task_8     335669 done  <dbl>  0.8647… <fn>  <named list> 2022-12-21 16:43:57
#>  9 task_9     335633 done  <dbl>  0.9653… <fn>  <named list> 2022-12-21 16:43:57
#> 10 task_10    335645 done  <dbl>  1.0666… <fn>  <named list> 2022-12-21 16:43:57
#> # … with 9 more variables: queued <dttm>, assigned <dttm>, started <dttm>,
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
