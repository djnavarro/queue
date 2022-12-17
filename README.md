
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
#> → Task done: task_6 (0.05s)
#> → Task done: task_4 (1.36s)
#> → Task done: task_1 (2.32s)
#> → Task done: task_7 (2.36s)
#> → Task done: task_2 (2.78s)
#> → Task done: task_3 (3.06s)
#> → Task done: task_5 (4.51s)
#> → Task done: task_9 (3.26s)
#> → Task done: task_14 (0.21s)
#> → Task done: task_11 (3.07s)
#> → Task done: task_8 (4.76s)
#> → Task done: task_10 (3.85s)
#> → Task done: task_12 (3.49s)
#> → Task done: task_17 (1.18s)
#> → Task done: task_16 (1.98s)
#> → Task done: task_19 (1.34s)
#> → Task done: task_13 (3.5s)
#> → Task done: task_15 (3.57s)
#> → Task done: task_18 (3.42s)
#> → Task done: task_20 (3.46s)
#> ✔ Queue complete: 20 tasks done (10.88s)
```

The output is stored in a tibble:

``` r
out
#> # A tibble: 20 × 16
#>    task_id worker_id state result     runtime   fun   args   created            
#>    <chr>       <int> <chr> <list>     <drtn>    <lis> <list> <dttm>             
#>  1 task_1     635771 done  <dttm [1]> 2.318988… <fn>  <list> 2022-12-17 19:31:05
#>  2 task_2     635783 done  <dttm [1]> 2.777316… <fn>  <list> 2022-12-17 19:31:05
#>  3 task_3     635795 done  <dttm [1]> 3.063051… <fn>  <list> 2022-12-17 19:31:05
#>  4 task_4     635807 done  <dttm [1]> 1.361345… <fn>  <list> 2022-12-17 19:31:05
#>  5 task_5     635819 done  <dttm [1]> 4.505504… <fn>  <list> 2022-12-17 19:31:05
#>  6 task_6     635831 done  <dttm [1]> 0.054956… <fn>  <list> 2022-12-17 19:31:05
#>  7 task_7     635831 done  <dttm [1]> 2.363450… <fn>  <list> 2022-12-17 19:31:05
#>  8 task_8     635807 done  <dttm [1]> 4.756309… <fn>  <list> 2022-12-17 19:31:05
#>  9 task_9     635771 done  <dttm [1]> 3.257435… <fn>  <list> 2022-12-17 19:31:05
#> 10 task_10    635831 done  <dttm [1]> 3.847261… <fn>  <list> 2022-12-17 19:31:05
#> 11 task_11    635783 done  <dttm [1]> 3.066454… <fn>  <list> 2022-12-17 19:31:05
#> 12 task_12    635795 done  <dttm [1]> 3.493597… <fn>  <list> 2022-12-17 19:31:05
#> 13 task_13    635819 done  <dttm [1]> 3.498409… <fn>  <list> 2022-12-17 19:31:05
#> 14 task_14    635771 done  <dttm [1]> 0.213202… <fn>  <list> 2022-12-17 19:31:05
#> 15 task_15    635771 done  <dttm [1]> 3.569851… <fn>  <list> 2022-12-17 19:31:05
#> 16 task_16    635783 done  <dttm [1]> 1.981123… <fn>  <list> 2022-12-17 19:31:05
#> 17 task_17    635807 done  <dttm [1]> 1.180276… <fn>  <list> 2022-12-17 19:31:05
#> 18 task_18    635831 done  <dttm [1]> 3.420555… <fn>  <list> 2022-12-17 19:31:05
#> 19 task_19    635795 done  <dttm [1]> 1.340868… <fn>  <list> 2022-12-17 19:31:05
#> 20 task_20    635807 done  <dttm [1]> 3.464793… <fn>  <list> 2022-12-17 19:31:05
#> # … with 8 more variables: queued <dttm>, assigned <dttm>, started <dttm>,
#> #   finished <dttm>, code <int>, message <chr>, stdout <list>, stderr <list>
```
