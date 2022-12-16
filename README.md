
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

This is a basic example:

``` r
library(queue)
queue <- TaskQueue$new(workers = 6)
random_wait <- function() {
  Sys.sleep(runif(1, min = 0, max = 5))
  Sys.time()
}
for(i in 1:20) queue$push(random_wait)
out <- queue$run(verbose = TRUE)
#> → Task done: task_3 (0.45s)
#> → Task done: task_2 (0.57s)
#> → Task done: task_7 (0.33s)
#> → Task done: task_5 (0.85s)
#> → Task done: task_9 (0.88s)
#> → Task done: task_8 (1.21s)
#> → Task done: task_1 (2.79s)
#> → Task done: task_11 (1.18s)
#> → Task done: task_14 (0.17s)
#> → Task done: task_12 (2.31s)
#> → Task done: task_15 (1.24s)
#> → Task done: task_13 (1.58s)
#> → Task done: task_6 (4.76s)
#> → Task done: task_4 (4.83s)
#> → Task done: task_10 (4.65s)
#> → Task done: task_16 (2.08s)
#> → Task done: task_20 (2.35s)
#> → Task done: task_17 (3.52s)
#> → Task done: task_18 (4.69s)
#> → Task done: task_19 (4.74s)
#> ✔ Queue complete: 20 tasks done (9.62s)
```

The output is stored in a tibble:

``` r
out
#> # A tibble: 20 × 15
#>    task_id state result     runtime        fun    args   created            
#>    <chr>   <chr> <list>     <drtn>         <list> <list> <dttm>             
#>  1 task_1  done  <dttm [1]> 2.7857070 secs <fn>   <NULL> 2022-12-16 18:06:22
#>  2 task_2  done  <dttm [1]> 0.5730121 secs <fn>   <NULL> 2022-12-16 18:06:22
#>  3 task_3  done  <dttm [1]> 0.4548085 secs <fn>   <NULL> 2022-12-16 18:06:22
#>  4 task_4  done  <dttm [1]> 4.8258891 secs <fn>   <NULL> 2022-12-16 18:06:22
#>  5 task_5  done  <dttm [1]> 0.8482270 secs <fn>   <NULL> 2022-12-16 18:06:22
#>  6 task_6  done  <dttm [1]> 4.7621713 secs <fn>   <NULL> 2022-12-16 18:06:22
#>  7 task_7  done  <dttm [1]> 0.3283424 secs <fn>   <NULL> 2022-12-16 18:06:22
#>  8 task_8  done  <dttm [1]> 1.2094641 secs <fn>   <NULL> 2022-12-16 18:06:22
#>  9 task_9  done  <dttm [1]> 0.8765776 secs <fn>   <NULL> 2022-12-16 18:06:22
#> 10 task_10 done  <dttm [1]> 4.6492043 secs <fn>   <NULL> 2022-12-16 18:06:22
#> 11 task_11 done  <dttm [1]> 1.1770709 secs <fn>   <NULL> 2022-12-16 18:06:22
#> 12 task_12 done  <dttm [1]> 2.3055251 secs <fn>   <NULL> 2022-12-16 18:06:22
#> 13 task_13 done  <dttm [1]> 1.5848000 secs <fn>   <NULL> 2022-12-16 18:06:22
#> 14 task_14 done  <dttm [1]> 0.1677492 secs <fn>   <NULL> 2022-12-16 18:06:22
#> 15 task_15 done  <dttm [1]> 1.2391675 secs <fn>   <NULL> 2022-12-16 18:06:22
#> 16 task_16 done  <dttm [1]> 2.0797689 secs <fn>   <NULL> 2022-12-16 18:06:22
#> 17 task_17 done  <dttm [1]> 3.5232008 secs <fn>   <NULL> 2022-12-16 18:06:22
#> 18 task_18 done  <dttm [1]> 4.6923347 secs <fn>   <NULL> 2022-12-16 18:06:22
#> 19 task_19 done  <dttm [1]> 4.7403309 secs <fn>   <NULL> 2022-12-16 18:06:22
#> 20 task_20 done  <dttm [1]> 2.3459470 secs <fn>   <NULL> 2022-12-16 18:06:22
#> # … with 8 more variables: enqueued <dttm>, assigned <dttm>, started <dttm>,
#> #   finished <dttm>, code <int>, message <chr>, stdout <list>, stderr <list>
```
