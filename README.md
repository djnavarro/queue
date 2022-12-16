
<!-- README.md is generated from README.Rmd. Please edit that file -->

# queue

<!-- badges: start -->

[![R-CMD-check](https://github.com/djnavarro/queue/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/djnavarro/queue/actions/workflows/R-CMD-check.yaml)
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
queue <- TaskQueue$new(workers = 6)
random_wait <- function() {
  Sys.sleep(runif(1, min = 0, max = 5))
  Sys.time()
}
for(i in 1:20) queue$push(random_wait)
out <- queue$run(verbose = TRUE)
#> → Task done: task_6 (1.07s)
#> → Task done: task_7 (1.41s)
#> → Task done: task_8 (0.11s)
#> → Task done: task_4 (2.72s)
#> → Task done: task_5 (3.29s)
#> → Task done: task_9 (0.92s)
#> → Task done: task_12 (0.17s)
#> → Task done: task_2 (3.76s)
#> → Task done: task_1 (4.1s)
#> → Task done: task_10 (1.9s)
#> → Task done: task_3 (4.8s)
#> → Task done: task_14 (1.72s)
#> → Task done: task_16 (0.86s)
#> → Task done: task_13 (2.77s)
#> → Task done: task_19 (1.38s)
#> → Task done: task_17 (2.19s)
#> → Task done: task_11 (4.38s)
#> → Task done: task_15 (4.66s)
#> → Task done: task_18 (4.18s)
#> → Task done: task_20 (4.36s)
#> ✔ Queue complete: 20 tasks done (10.93s)
```

The output is stored in a tibble:

``` r
out
#> # A tibble: 20 × 15
#>    task_id state result     runtime        fun    args   created            
#>    <chr>   <chr> <list>     <drtn>         <list> <list> <dttm>             
#>  1 task_1  done  <dttm [1]> 4.1032739 secs <fn>   <NULL> 2022-12-16 21:32:31
#>  2 task_2  done  <dttm [1]> 3.7589240 secs <fn>   <NULL> 2022-12-16 21:32:31
#>  3 task_3  done  <dttm [1]> 4.7972717 secs <fn>   <NULL> 2022-12-16 21:32:31
#>  4 task_4  done  <dttm [1]> 2.7174783 secs <fn>   <NULL> 2022-12-16 21:32:31
#>  5 task_5  done  <dttm [1]> 3.2928810 secs <fn>   <NULL> 2022-12-16 21:32:31
#>  6 task_6  done  <dttm [1]> 1.0663207 secs <fn>   <NULL> 2022-12-16 21:32:31
#>  7 task_7  done  <dttm [1]> 1.4110322 secs <fn>   <NULL> 2022-12-16 21:32:31
#>  8 task_8  done  <dttm [1]> 0.1143486 secs <fn>   <NULL> 2022-12-16 21:32:31
#>  9 task_9  done  <dttm [1]> 0.9160516 secs <fn>   <NULL> 2022-12-16 21:32:31
#> 10 task_10 done  <dttm [1]> 1.8957493 secs <fn>   <NULL> 2022-12-16 21:32:31
#> 11 task_11 done  <dttm [1]> 4.3754835 secs <fn>   <NULL> 2022-12-16 21:32:31
#> 12 task_12 done  <dttm [1]> 0.1735280 secs <fn>   <NULL> 2022-12-16 21:32:31
#> 13 task_13 done  <dttm [1]> 2.7669959 secs <fn>   <NULL> 2022-12-16 21:32:31
#> 14 task_14 done  <dttm [1]> 1.7240422 secs <fn>   <NULL> 2022-12-16 21:32:31
#> 15 task_15 done  <dttm [1]> 4.6562624 secs <fn>   <NULL> 2022-12-16 21:32:31
#> 16 task_16 done  <dttm [1]> 0.8638632 secs <fn>   <NULL> 2022-12-16 21:32:31
#> 17 task_17 done  <dttm [1]> 2.1852658 secs <fn>   <NULL> 2022-12-16 21:32:31
#> 18 task_18 done  <dttm [1]> 4.1764796 secs <fn>   <NULL> 2022-12-16 21:32:31
#> 19 task_19 done  <dttm [1]> 1.3767705 secs <fn>   <NULL> 2022-12-16 21:32:31
#> 20 task_20 done  <dttm [1]> 4.3623860 secs <fn>   <NULL> 2022-12-16 21:32:31
#> # … with 8 more variables: enqueued <dttm>, assigned <dttm>, started <dttm>,
#> #   finished <dttm>, code <int>, message <chr>, stdout <list>, stderr <list>
```
