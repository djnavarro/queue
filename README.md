
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
#> → Task done: task_1 in 0.193 secs
#> → Task done: task_2 in 0.255 secs
#> → Task done: task_3 in 0.369 secs
#> → Task done: task_4 in 0.489 secs
#> → Task done: task_5 in 0.579 secs
#> → Task done: task_6 in 0.696 secs
#> → Task done: task_7 in 0.756 secs
#> → Task done: task_8 in 0.859 secs
#> → Task done: task_9 in 0.96 secs
#> → Task done: task_10 in 1.06 secs
#> ✔ Queue complete: 10 tasks done in 2.04 secs
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
#>  1 task_1     460280 done  <dbl>  0.1927… <fn>  <named list> 2022-12-22 10:45:28
#>  2 task_2     460292 done  <dbl>  0.2552… <fn>  <named list> 2022-12-22 10:45:28
#>  3 task_3     460304 done  <dbl>  0.3691… <fn>  <named list> 2022-12-22 10:45:28
#>  4 task_4     460316 done  <dbl>  0.4885… <fn>  <named list> 2022-12-22 10:45:28
#>  5 task_5     460280 done  <dbl>  0.5792… <fn>  <named list> 2022-12-22 10:45:28
#>  6 task_6     460292 done  <dbl>  0.6962… <fn>  <named list> 2022-12-22 10:45:28
#>  7 task_7     460304 done  <dbl>  0.7555… <fn>  <named list> 2022-12-22 10:45:28
#>  8 task_8     460316 done  <dbl>  0.8593… <fn>  <named list> 2022-12-22 10:45:28
#>  9 task_9     460280 done  <dbl>  0.9601… <fn>  <named list> 2022-12-22 10:45:28
#> 10 task_10    460292 done  <dbl>  1.0560… <fn>  <named list> 2022-12-22 10:45:28
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
