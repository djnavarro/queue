
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
queue <- Queue$new(workers = 6)
for(i in 1:20) queue$push(random_wait)
out <- queue$run(message = "verbose")
#> → Task done: task_2 (0.19s)
#> → Task done: task_5 (1.01s)
#> → Task done: task_8 (0.63s)
#> → Task done: task_4 (1.9s)
#> → Task done: task_1 (2.14s)
#> → Task done: task_11 (0.11s)
#> → Task done: task_6 (2.55s)
#> → Task done: task_7 (3.12s)
#> → Task done: task_9 (1.78s)
#> → Task done: task_3 (4.32s)
#> → Task done: task_13 (1.94s)
#> → Task done: task_15 (1.18s)
#> → Task done: task_14 (1.96s)
#> → Task done: task_17 (1.07s)
#> → Task done: task_12 (3.38s)
#> → Task done: task_10 (3.94s)
#> → Task done: task_18 (1.67s)
#> → Task done: task_19 (1.43s)
#> → Task done: task_16 (3.43s)
#> → Task done: task_20 (2.7s)
#> ✔ Queue complete: 20 tasks done (8.39s)
```

The output is stored in a tibble:

``` r
out
#> # A tibble: 20 × 16
#>    task_id worker_id state result     runtime   fun   args   created            
#>    <chr>       <int> <chr> <list>     <drtn>    <lis> <list> <dttm>             
#>  1 task_1     196973 done  <dttm [1]> 2.138334… <fn>  <list> 2022-12-20 09:31:32
#>  2 task_2     196987 done  <dttm [1]> 0.191523… <fn>  <list> 2022-12-20 09:31:32
#>  3 task_3     196999 done  <dttm [1]> 4.323249… <fn>  <list> 2022-12-20 09:31:32
#>  4 task_4     197011 done  <dttm [1]> 1.896968… <fn>  <list> 2022-12-20 09:31:32
#>  5 task_5     197023 done  <dttm [1]> 1.009959… <fn>  <list> 2022-12-20 09:31:32
#>  6 task_6     197035 done  <dttm [1]> 2.553204… <fn>  <list> 2022-12-20 09:31:32
#>  7 task_7     196987 done  <dttm [1]> 3.122331… <fn>  <list> 2022-12-20 09:31:32
#>  8 task_8     197023 done  <dttm [1]> 0.632794… <fn>  <list> 2022-12-20 09:31:32
#>  9 task_9     197023 done  <dttm [1]> 1.782042… <fn>  <list> 2022-12-20 09:31:32
#> 10 task_10    197011 done  <dttm [1]> 3.936467… <fn>  <list> 2022-12-20 09:31:32
#> 11 task_11    196973 done  <dttm [1]> 0.114268… <fn>  <list> 2022-12-20 09:31:32
#> 12 task_12    196973 done  <dttm [1]> 3.380205… <fn>  <list> 2022-12-20 09:31:32
#> 13 task_13    197035 done  <dttm [1]> 1.940525… <fn>  <list> 2022-12-20 09:31:32
#> 14 task_14    196987 done  <dttm [1]> 1.957157… <fn>  <list> 2022-12-20 09:31:32
#> 15 task_15    197023 done  <dttm [1]> 1.178380… <fn>  <list> 2022-12-20 09:31:32
#> 16 task_16    196999 done  <dttm [1]> 3.427227… <fn>  <list> 2022-12-20 09:31:32
#> 17 task_17    197035 done  <dttm [1]> 1.071127… <fn>  <list> 2022-12-20 09:31:32
#> 18 task_18    197023 done  <dttm [1]> 1.674359… <fn>  <list> 2022-12-20 09:31:32
#> 19 task_19    196987 done  <dttm [1]> 1.431259… <fn>  <list> 2022-12-20 09:31:32
#> 20 task_20    197035 done  <dttm [1]> 2.698126… <fn>  <list> 2022-12-20 09:31:32
#> # … with 8 more variables: queued <dttm>, assigned <dttm>, started <dttm>,
#> #   finished <dttm>, code <int>, message <chr>, stdout <list>, stderr <list>
```
