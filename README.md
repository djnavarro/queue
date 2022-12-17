
<!-- README.md is generated from README.Rmd. Please edit that file -->

# queue

<!-- badges: start -->

[![R-CMD-check](https://github.com/djnavarro/queue/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/djnavarro/queue/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/djnavarro/queue/branch/main/graph/badge.svg)](https://app.codecov.io/gh/djnavarro/queue?branch=main)
<!-- badges: end -->

The queue package allows you to create multi-threaded task queues

## Installation

You can install the development version of queue like so:

``` r
remotes::install_github("djnavarro/queue")
```

## Example

Here’s a basic example:

``` r
library(queue)
random_wait <- function() {
  Sys.sleep(runif(1, min = 0, max = 5))
  Sys.time()
}
queue <- TaskQueue$new(workers = 6)
for(i in 1:20) queue$push(random_wait)
out <- queue$run(message = "verbose")
#> → Task done: task_4 (0.5s)
#> → Task done: task_2 (1.23s)
#> → Task done: task_8 (0.18s)
#> → Task done: task_6 (2.32s)
#> → Task done: task_7 (2.04s)
#> → Task done: task_1 (2.61s)
#> → Task done: task_9 (1.19s)
#> → Task done: task_11 (0.25s)
#> → Task done: task_5 (3.25s)
#> → Task done: task_15 (0.29s)
#> → Task done: task_13 (1.09s)
#> → Task done: task_10 (2s)
#> → Task done: task_3 (4.65s)
#> → Task done: task_12 (2.95s)
#> → Task done: task_20 (0.3s)
#> → Task done: task_18 (2.09s)
#> → Task done: task_14 (4.77s)
#> → Task done: task_16 (4.55s)
#> → Task done: task_17 (4.62s)
#> → Task done: task_19 (4.2s)
#> ✔ Queue complete: 20 tasks done (8.97s)
```

The output is stored in a tibble:

``` r
out
#> # A tibble: 20 × 16
#>    task_id worker_id state result     runtime   fun   args   created            
#>    <chr>       <int> <chr> <list>     <drtn>    <lis> <list> <dttm>             
#>  1 task_1     655413 done  <dttm [1]> 2.610021… <fn>  <list> 2022-12-17 21:23:40
#>  2 task_2     655425 done  <dttm [1]> 1.229150… <fn>  <list> 2022-12-17 21:23:40
#>  3 task_3     655437 done  <dttm [1]> 4.650622… <fn>  <list> 2022-12-17 21:23:40
#>  4 task_4     655449 done  <dttm [1]> 0.497227… <fn>  <list> 2022-12-17 21:23:40
#>  5 task_5     655461 done  <dttm [1]> 3.246130… <fn>  <list> 2022-12-17 21:23:40
#>  6 task_6     655474 done  <dttm [1]> 2.318947… <fn>  <list> 2022-12-17 21:23:40
#>  7 task_7     655449 done  <dttm [1]> 2.043578… <fn>  <list> 2022-12-17 21:23:40
#>  8 task_8     655425 done  <dttm [1]> 0.176116… <fn>  <list> 2022-12-17 21:23:40
#>  9 task_9     655425 done  <dttm [1]> 1.193250… <fn>  <list> 2022-12-17 21:23:40
#> 10 task_10    655474 done  <dttm [1]> 2.004132… <fn>  <list> 2022-12-17 21:23:40
#> 11 task_11    655449 done  <dttm [1]> 0.247079… <fn>  <list> 2022-12-17 21:23:40
#> 12 task_12    655413 done  <dttm [1]> 2.951664… <fn>  <list> 2022-12-17 21:23:40
#> 13 task_13    655425 done  <dttm [1]> 1.090405… <fn>  <list> 2022-12-17 21:23:40
#> 14 task_14    655449 done  <dttm [1]> 4.771457… <fn>  <list> 2022-12-17 21:23:40
#> 15 task_15    655461 done  <dttm [1]> 0.288183… <fn>  <list> 2022-12-17 21:23:40
#> 16 task_16    655461 done  <dttm [1]> 4.551815… <fn>  <list> 2022-12-17 21:23:40
#> 17 task_17    655425 done  <dttm [1]> 4.623109… <fn>  <list> 2022-12-17 21:23:40
#> 18 task_18    655474 done  <dttm [1]> 2.090163… <fn>  <list> 2022-12-17 21:23:40
#> 19 task_19    655437 done  <dttm [1]> 4.203654… <fn>  <list> 2022-12-17 21:23:40
#> 20 task_20    655413 done  <dttm [1]> 0.295464… <fn>  <list> 2022-12-17 21:23:40
#> # … with 8 more variables: queued <dttm>, assigned <dttm>, started <dttm>,
#> #   finished <dttm>, code <int>, message <chr>, stdout <list>, stderr <list>
```
