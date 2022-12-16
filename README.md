
<!-- README.md is generated from README.Rmd. Please edit that file -->

# queue

<!-- badges: start -->

[![R-CMD-check](https://github.com/djnavarro/queue/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/djnavarro/queue/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/djnavarro/queue/branch/main/graph/badge.svg)](https://app.codecov.io/gh/djnavarro/queue?branch=main)
<!-- badges: end -->

The queue package allows you to create multi-threaded tasks queues

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
#> → Task done: task_6 (2.04s)
#> → Task done: task_5 (2.72s)
#> → Task done: task_8 (0.06s)
#> → Task done: task_3 (3.07s)
#> → Task done: task_2 (4.55s)
#> → Task done: task_1 (5.01s)
#> → Task done: task_4 (5.01s)
#> → Task done: task_7 (3.37s)
#> → Task done: task_10 (2.69s)
#> → Task done: task_13 (1.32s)
#> → Task done: task_15 (0.8s)
#> → Task done: task_9 (5.04s)
#> → Task done: task_12 (3.4s)
#> → Task done: task_14 (3.73s)
#> → Task done: task_11 (5.05s)
#> → Task done: task_17 (3.27s)
#> → Task done: task_19 (1.54s)
#> → Task done: task_18 (2.31s)
#> → Task done: task_16 (4.14s)
#> → Task done: task_20 (2.83s)
#> ✔ Queue complete: 20 tasks done (12.09s)
```

The output is stored in a tibble:

``` r
out
#> # A tibble: 20 × 15
#>    task_id state result     runtime         fun    args   created            
#>    <chr>   <chr> <list>     <drtn>          <list> <list> <dttm>             
#>  1 task_1  done  <dttm [1]> 5.00678563 secs <fn>   <NULL> 2022-12-16 22:57:19
#>  2 task_2  done  <dttm [1]> 4.55219698 secs <fn>   <NULL> 2022-12-16 22:57:19
#>  3 task_3  done  <dttm [1]> 3.07374978 secs <fn>   <NULL> 2022-12-16 22:57:19
#>  4 task_4  done  <dttm [1]> 5.00675082 secs <fn>   <NULL> 2022-12-16 22:57:19
#>  5 task_5  done  <dttm [1]> 2.71826696 secs <fn>   <NULL> 2022-12-16 22:57:19
#>  6 task_6  done  <dttm [1]> 2.04142475 secs <fn>   <NULL> 2022-12-16 22:57:19
#>  7 task_7  done  <dttm [1]> 3.37261081 secs <fn>   <NULL> 2022-12-16 22:57:19
#>  8 task_8  done  <dttm [1]> 0.06101346 secs <fn>   <NULL> 2022-12-16 22:57:19
#>  9 task_9  done  <dttm [1]> 5.03528595 secs <fn>   <NULL> 2022-12-16 22:57:19
#> 10 task_10 done  <dttm [1]> 2.68669820 secs <fn>   <NULL> 2022-12-16 22:57:19
#> 11 task_11 done  <dttm [1]> 5.05019331 secs <fn>   <NULL> 2022-12-16 22:57:19
#> 12 task_12 done  <dttm [1]> 3.40077209 secs <fn>   <NULL> 2022-12-16 22:57:19
#> 13 task_13 done  <dttm [1]> 1.31972241 secs <fn>   <NULL> 2022-12-16 22:57:19
#> 14 task_14 done  <dttm [1]> 3.72968268 secs <fn>   <NULL> 2022-12-16 22:57:19
#> 15 task_15 done  <dttm [1]> 0.79997492 secs <fn>   <NULL> 2022-12-16 22:57:19
#> 16 task_16 done  <dttm [1]> 4.13943505 secs <fn>   <NULL> 2022-12-16 22:57:19
#> 17 task_17 done  <dttm [1]> 3.26678777 secs <fn>   <NULL> 2022-12-16 22:57:19
#> 18 task_18 done  <dttm [1]> 2.30597281 secs <fn>   <NULL> 2022-12-16 22:57:19
#> 19 task_19 done  <dttm [1]> 1.54130697 secs <fn>   <NULL> 2022-12-16 22:57:19
#> 20 task_20 done  <dttm [1]> 2.83111596 secs <fn>   <NULL> 2022-12-16 22:57:19
#> # … with 8 more variables: enqueued <dttm>, assigned <dttm>, started <dttm>,
#> #   finished <dttm>, code <int>, message <chr>, stdout <list>, stderr <list>
```
