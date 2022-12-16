
<!-- README.md is generated from README.Rmd. Please edit that file -->

# queue

<!-- badges: start -->
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
#> → Task done: task_5 (0.24s)
#> → Task done: task_6 (0.31s)
#> → Task done: task_3 (0.65s)
#> → Task done: task_9 (0.85s)
#> → Task done: task_4 (1.63s)
#> → Task done: task_1 (2.82s)
#> → Task done: task_7 (2.57s)
#> → Task done: task_8 (2.51s)
#> → Task done: task_13 (0.57s)
#> → Task done: task_10 (3.19s)
#> → Task done: task_2 (4.99s)
#> → Task done: task_14 (2.4s)
#> → Task done: task_11 (3.88s)
#> → Task done: task_12 (3.95s)
#> → Task done: task_15 (3.9s)
#> → Task done: task_17 (3.79s)
#> → Task done: task_18 (3.68s)
#> → Task done: task_19 (3.74s)
#> → Task done: task_16 (4.73s)
#> → Task done: task_20 (3.65s)
#> ✔ Queue complete: 20 tasks done (10.53s)
```

The output is stored in a tibble:

``` r
out
#> # A tibble: 20 × 15
#>    task_id state result     runtime        fun    args   created            
#>    <chr>   <chr> <list>     <drtn>         <list> <list> <dttm>             
#>  1 task_1  done  <dttm [1]> 2.8206053 secs <fn>   <NULL> 2022-12-16 21:15:13
#>  2 task_2  done  <dttm [1]> 4.9937327 secs <fn>   <NULL> 2022-12-16 21:15:13
#>  3 task_3  done  <dttm [1]> 0.6513133 secs <fn>   <NULL> 2022-12-16 21:15:13
#>  4 task_4  done  <dttm [1]> 1.6259332 secs <fn>   <NULL> 2022-12-16 21:15:13
#>  5 task_5  done  <dttm [1]> 0.2433972 secs <fn>   <NULL> 2022-12-16 21:15:13
#>  6 task_6  done  <dttm [1]> 0.3065538 secs <fn>   <NULL> 2022-12-16 21:15:13
#>  7 task_7  done  <dttm [1]> 2.5728769 secs <fn>   <NULL> 2022-12-16 21:15:13
#>  8 task_8  done  <dttm [1]> 2.5109060 secs <fn>   <NULL> 2022-12-16 21:15:13
#>  9 task_9  done  <dttm [1]> 0.8459370 secs <fn>   <NULL> 2022-12-16 21:15:13
#> 10 task_10 done  <dttm [1]> 3.1911669 secs <fn>   <NULL> 2022-12-16 21:15:13
#> 11 task_11 done  <dttm [1]> 3.8843801 secs <fn>   <NULL> 2022-12-16 21:15:13
#> 12 task_12 done  <dttm [1]> 3.9457197 secs <fn>   <NULL> 2022-12-16 21:15:13
#> 13 task_13 done  <dttm [1]> 0.5696230 secs <fn>   <NULL> 2022-12-16 21:15:13
#> 14 task_14 done  <dttm [1]> 2.3954489 secs <fn>   <NULL> 2022-12-16 21:15:13
#> 15 task_15 done  <dttm [1]> 3.8951573 secs <fn>   <NULL> 2022-12-16 21:15:13
#> 16 task_16 done  <dttm [1]> 4.7264009 secs <fn>   <NULL> 2022-12-16 21:15:13
#> 17 task_17 done  <dttm [1]> 3.7879162 secs <fn>   <NULL> 2022-12-16 21:15:13
#> 18 task_18 done  <dttm [1]> 3.6754615 secs <fn>   <NULL> 2022-12-16 21:15:13
#> 19 task_19 done  <dttm [1]> 3.7365201 secs <fn>   <NULL> 2022-12-16 21:15:13
#> 20 task_20 done  <dttm [1]> 3.6456223 secs <fn>   <NULL> 2022-12-16 21:15:13
#> # … with 8 more variables: enqueued <dttm>, assigned <dttm>, started <dttm>,
#> #   finished <dttm>, code <int>, message <chr>, stdout <list>, stderr <list>
```
