
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
#> → Task done: task_6 (1.56s)
#> → Task done: task_3 (1.67s)
#> → Task done: task_8 (0.27s)
#> → Task done: task_4 (2.42s)
#> → Task done: task_10 (0.11s)
#> → Task done: task_5 (2.59s)
#> → Task done: task_11 (0.17s)
#> → Task done: task_2 (2.86s)
#> → Task done: task_12 (1.86s)
#> → Task done: task_1 (4.56s)
#> → Task done: task_14 (2.13s)
#> → Task done: task_13 (2.4s)
#> → Task done: task_7 (3.7s)
#> → Task done: task_9 (3.32s)
#> → Task done: task_19 (0.43s)
#> → Task done: task_18 (1.12s)
#> → Task done: task_17 (1.76s)
#> → Task done: task_16 (3.97s)
#> → Task done: task_15 (4.36s)
#> → Task done: task_20 (3.55s)
#> ✔ Queue complete: 20 tasks done (8.94s)
```

The output is stored in a tibble:

``` r
out
#> # A tibble: 20 × 15
#>    task_id state result     runtime        fun    args   created            
#>    <chr>   <chr> <list>     <drtn>         <list> <list> <dttm>             
#>  1 task_1  done  <dttm [1]> 4.5631678 secs <fn>   <NULL> 2022-12-16 23:54:21
#>  2 task_2  done  <dttm [1]> 2.8644190 secs <fn>   <NULL> 2022-12-16 23:54:21
#>  3 task_3  done  <dttm [1]> 1.6725762 secs <fn>   <NULL> 2022-12-16 23:54:21
#>  4 task_4  done  <dttm [1]> 2.4215531 secs <fn>   <NULL> 2022-12-16 23:54:21
#>  5 task_5  done  <dttm [1]> 2.5928771 secs <fn>   <NULL> 2022-12-16 23:54:21
#>  6 task_6  done  <dttm [1]> 1.5559967 secs <fn>   <NULL> 2022-12-16 23:54:21
#>  7 task_7  done  <dttm [1]> 3.7028220 secs <fn>   <NULL> 2022-12-16 23:54:21
#>  8 task_8  done  <dttm [1]> 0.2667127 secs <fn>   <NULL> 2022-12-16 23:54:21
#>  9 task_9  done  <dttm [1]> 3.3203418 secs <fn>   <NULL> 2022-12-16 23:54:21
#> 10 task_10 done  <dttm [1]> 0.1115730 secs <fn>   <NULL> 2022-12-16 23:54:21
#> 11 task_11 done  <dttm [1]> 0.1661649 secs <fn>   <NULL> 2022-12-16 23:54:21
#> 12 task_12 done  <dttm [1]> 1.8570998 secs <fn>   <NULL> 2022-12-16 23:54:21
#> 13 task_13 done  <dttm [1]> 2.3971710 secs <fn>   <NULL> 2022-12-16 23:54:21
#> 14 task_14 done  <dttm [1]> 2.1271043 secs <fn>   <NULL> 2022-12-16 23:54:21
#> 15 task_15 done  <dttm [1]> 4.3593125 secs <fn>   <NULL> 2022-12-16 23:54:21
#> 16 task_16 done  <dttm [1]> 3.9651949 secs <fn>   <NULL> 2022-12-16 23:54:21
#> 17 task_17 done  <dttm [1]> 1.7646353 secs <fn>   <NULL> 2022-12-16 23:54:21
#> 18 task_18 done  <dttm [1]> 1.1221511 secs <fn>   <NULL> 2022-12-16 23:54:21
#> 19 task_19 done  <dttm [1]> 0.4276683 secs <fn>   <NULL> 2022-12-16 23:54:21
#> 20 task_20 done  <dttm [1]> 3.5490470 secs <fn>   <NULL> 2022-12-16 23:54:21
#> # … with 8 more variables: queued <dttm>, assigned <dttm>, started <dttm>,
#> #   finished <dttm>, code <int>, message <chr>, stdout <list>, stderr <list>
```
