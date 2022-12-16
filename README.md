
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
random_wait <- function() {
  Sys.sleep(runif(1, min = 0, max = 5))
  Sys.time()
}
queue <- TaskQueue$new(workers = 6)
for(i in 1:20) queue$push(random_wait)
out <- queue$run(message = "verbose")
#> → Task done: task_3 (0.13s)
#> → Task done: task_5 (0.37s)
#> → Task done: task_2 (1.28s)
#> → Task done: task_1 (2.07s)
#> → Task done: task_7 (2.17s)
#> → Task done: task_4 (2.99s)
#> → Task done: task_6 (3.11s)
#> → Task done: task_8 (3.36s)
#> → Task done: task_14 (0.45s)
#> → Task done: task_10 (2.46s)
#> → Task done: task_12 (2.11s)
#> → Task done: task_13 (1.99s)
#> → Task done: task_9 (4.46s)
#> → Task done: task_15 (1.55s)
#> → Task done: task_11 (4.81s)
#> → Task done: task_20 (1.6s)
#> → Task done: task_18 (2.3s)
#> → Task done: task_16 (3.44s)
#> → Task done: task_17 (3.94s)
#> → Task done: task_19 (3.71s)
#> ✔ Queue complete: 20 tasks done (9.56s)
```

The output is stored in a tibble:

``` r
out
#> # A tibble: 20 × 15
#>    task_id state result     runtime        fun    args   created            
#>    <chr>   <chr> <list>     <drtn>         <list> <list> <dttm>             
#>  1 task_1  done  <dttm [1]> 2.0711689 secs <fn>   <NULL> 2022-12-16 22:35:35
#>  2 task_2  done  <dttm [1]> 1.2755511 secs <fn>   <NULL> 2022-12-16 22:35:35
#>  3 task_3  done  <dttm [1]> 0.1344159 secs <fn>   <NULL> 2022-12-16 22:35:35
#>  4 task_4  done  <dttm [1]> 2.9904590 secs <fn>   <NULL> 2022-12-16 22:35:35
#>  5 task_5  done  <dttm [1]> 0.3722873 secs <fn>   <NULL> 2022-12-16 22:35:35
#>  6 task_6  done  <dttm [1]> 3.1123674 secs <fn>   <NULL> 2022-12-16 22:35:35
#>  7 task_7  done  <dttm [1]> 2.1650698 secs <fn>   <NULL> 2022-12-16 22:35:35
#>  8 task_8  done  <dttm [1]> 3.3554914 secs <fn>   <NULL> 2022-12-16 22:35:35
#>  9 task_9  done  <dttm [1]> 4.4619942 secs <fn>   <NULL> 2022-12-16 22:35:35
#> 10 task_10 done  <dttm [1]> 2.4574857 secs <fn>   <NULL> 2022-12-16 22:35:35
#> 11 task_11 done  <dttm [1]> 4.8144801 secs <fn>   <NULL> 2022-12-16 22:35:35
#> 12 task_12 done  <dttm [1]> 2.1112382 secs <fn>   <NULL> 2022-12-16 22:35:35
#> 13 task_13 done  <dttm [1]> 1.9892695 secs <fn>   <NULL> 2022-12-16 22:35:35
#> 14 task_14 done  <dttm [1]> 0.4500039 secs <fn>   <NULL> 2022-12-16 22:35:35
#> 15 task_15 done  <dttm [1]> 1.5530598 secs <fn>   <NULL> 2022-12-16 22:35:35
#> 16 task_16 done  <dttm [1]> 3.4375207 secs <fn>   <NULL> 2022-12-16 22:35:35
#> 17 task_17 done  <dttm [1]> 3.9445057 secs <fn>   <NULL> 2022-12-16 22:35:35
#> 18 task_18 done  <dttm [1]> 2.3006504 secs <fn>   <NULL> 2022-12-16 22:35:35
#> 19 task_19 done  <dttm [1]> 3.7057896 secs <fn>   <NULL> 2022-12-16 22:35:35
#> 20 task_20 done  <dttm [1]> 1.6024036 secs <fn>   <NULL> 2022-12-16 22:35:35
#> # … with 8 more variables: enqueued <dttm>, assigned <dttm>, started <dttm>,
#> #   finished <dttm>, code <int>, message <chr>, stdout <list>, stderr <list>
```
