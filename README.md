
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
for(i in 1:20) queue$add(random_wait)
out <- queue$run(message = "verbose")
#> → Task done: task_2 (0.15s)
#> → Task done: task_5 (0.15s)
#> → Task done: task_7 (0.23s)
#> → Task done: task_4 (1.03s)
#> → Task done: task_6 (1.26s)
#> → Task done: task_11 (1.13s)
#> → Task done: task_3 (2.8s)
#> → Task done: task_1 (2.92s)
#> → Task done: task_9 (2.81s)
#> → Task done: task_12 (1.04s)
#> → Task done: task_10 (3.33s)
#> → Task done: task_16 (0.97s)
#> → Task done: task_8 (4.67s)
#> → Task done: task_18 (2.27s)
#> → Task done: task_15 (3.71s)
#> → Task done: task_14 (4.06s)
#> → Task done: task_13 (4.8s)
#> → Task done: task_20 (1.74s)
#> → Task done: task_19 (4.16s)
#> → Task done: task_17 (4.79s)
#> ✔ Queue complete: 20 tasks done (9.17s)
```

The output is stored in a tibble:

``` r
out
#> # A tibble: 20 × 17
#>    task_id worker_id state result     runtime   fun   args   created            
#>    <chr>       <int> <chr> <list>     <drtn>    <lis> <list> <dttm>             
#>  1 task_1     298331 done  <dttm [1]> 2.921892… <fn>  <list> 2022-12-21 12:09:17
#>  2 task_2     298343 done  <dttm [1]> 0.154564… <fn>  <list> 2022-12-21 12:09:17
#>  3 task_3     298355 done  <dttm [1]> 2.801716… <fn>  <list> 2022-12-21 12:09:17
#>  4 task_4     298367 done  <dttm [1]> 1.026389… <fn>  <list> 2022-12-21 12:09:17
#>  5 task_5     298379 done  <dttm [1]> 0.154445… <fn>  <list> 2022-12-21 12:09:17
#>  6 task_6     298391 done  <dttm [1]> 1.258186… <fn>  <list> 2022-12-21 12:09:17
#>  7 task_7     298343 done  <dttm [1]> 0.228369… <fn>  <list> 2022-12-21 12:09:17
#>  8 task_8     298379 done  <dttm [1]> 4.667863… <fn>  <list> 2022-12-21 12:09:17
#>  9 task_9     298343 done  <dttm [1]> 2.814760… <fn>  <list> 2022-12-21 12:09:17
#> 10 task_10    298367 done  <dttm [1]> 3.327445… <fn>  <list> 2022-12-21 12:09:17
#> 11 task_11    298391 done  <dttm [1]> 1.132713… <fn>  <list> 2022-12-21 12:09:17
#> 12 task_12    298391 done  <dttm [1]> 1.041694… <fn>  <list> 2022-12-21 12:09:17
#> 13 task_13    298355 done  <dttm [1]> 4.796654… <fn>  <list> 2022-12-21 12:09:17
#> 14 task_14    298331 done  <dttm [1]> 4.058190… <fn>  <list> 2022-12-21 12:09:17
#> 15 task_15    298343 done  <dttm [1]> 3.705963… <fn>  <list> 2022-12-21 12:09:17
#> 16 task_16    298391 done  <dttm [1]> 0.972990… <fn>  <list> 2022-12-21 12:09:17
#> 17 task_17    298367 done  <dttm [1]> 4.794048… <fn>  <list> 2022-12-21 12:09:17
#> 18 task_18    298391 done  <dttm [1]> 2.266615… <fn>  <list> 2022-12-21 12:09:17
#> 19 task_19    298379 done  <dttm [1]> 4.160249… <fn>  <list> 2022-12-21 12:09:17
#> 20 task_20    298391 done  <dttm [1]> 1.740901… <fn>  <list> 2022-12-21 12:09:17
#> # … with 9 more variables: queued <dttm>, assigned <dttm>, started <dttm>,
#> #   finished <dttm>, code <int>, message <chr>, stdout <list>, stderr <list>,
#> #   error <list>
```
