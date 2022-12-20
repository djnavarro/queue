
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
#> → Task done: task_3 (1.02s)
#> → Task done: task_2 (1.6s)
#> → Task done: task_6 (2.45s)
#> → Task done: task_8 (1.49s)
#> → Task done: task_5 (3.27s)
#> → Task done: task_9 (1.16s)
#> → Task done: task_1 (4.2s)
#> → Task done: task_4 (5s)
#> → Task done: task_11 (2.06s)
#> → Task done: task_7 (4.36s)
#> → Task done: task_13 (1.54s)
#> → Task done: task_15 (1.26s)
#> → Task done: task_16 (1.43s)
#> → Task done: task_17 (1.32s)
#> → Task done: task_10 (4.2s)
#> → Task done: task_12 (3.85s)
#> → Task done: task_14 (2.87s)
#> → Task done: task_18 (3.29s)
#> → Task done: task_20 (3.37s)
#> → Task done: task_19 (3.9s)
#> ✔ Queue complete: 20 tasks done (10.75s)
```

The output is stored in a tibble:

``` r
out
#> # A tibble: 20 × 16
#>    task_id worker_id state result     runtime   fun   args   created            
#>    <chr>       <int> <chr> <list>     <drtn>    <lis> <list> <dttm>             
#>  1 task_1     255562 done  <dttm [1]> 4.196353… <fn>  <list> 2022-12-20 22:51:27
#>  2 task_2     255574 done  <dttm [1]> 1.596929… <fn>  <list> 2022-12-20 22:51:27
#>  3 task_3     255586 done  <dttm [1]> 1.023834… <fn>  <list> 2022-12-20 22:51:27
#>  4 task_4     255598 done  <dttm [1]> 4.995022… <fn>  <list> 2022-12-20 22:51:27
#>  5 task_5     255610 done  <dttm [1]> 3.273960… <fn>  <list> 2022-12-20 22:51:27
#>  6 task_6     255622 done  <dttm [1]> 2.452743… <fn>  <list> 2022-12-20 22:51:27
#>  7 task_7     255586 done  <dttm [1]> 4.362836… <fn>  <list> 2022-12-20 22:51:27
#>  8 task_8     255574 done  <dttm [1]> 1.491902… <fn>  <list> 2022-12-20 22:51:27
#>  9 task_9     255622 done  <dttm [1]> 1.162327… <fn>  <list> 2022-12-20 22:51:27
#> 10 task_10    255574 done  <dttm [1]> 4.197296… <fn>  <list> 2022-12-20 22:51:27
#> 11 task_11    255610 done  <dttm [1]> 2.055867… <fn>  <list> 2022-12-20 22:51:27
#> 12 task_12    255622 done  <dttm [1]> 3.846560… <fn>  <list> 2022-12-20 22:51:27
#> 13 task_13    255562 done  <dttm [1]> 1.538861… <fn>  <list> 2022-12-20 22:51:27
#> 14 task_14    255598 done  <dttm [1]> 2.871299… <fn>  <list> 2022-12-20 22:51:27
#> 15 task_15    255610 done  <dttm [1]> 1.260352… <fn>  <list> 2022-12-20 22:51:27
#> 16 task_16    255586 done  <dttm [1]> 1.431690… <fn>  <list> 2022-12-20 22:51:27
#> 17 task_17    255562 done  <dttm [1]> 1.319165… <fn>  <list> 2022-12-20 22:51:27
#> 18 task_18    255610 done  <dttm [1]> 3.287837… <fn>  <list> 2022-12-20 22:51:27
#> 19 task_19    255586 done  <dttm [1]> 3.897338… <fn>  <list> 2022-12-20 22:51:27
#> 20 task_20    255562 done  <dttm [1]> 3.374432… <fn>  <list> 2022-12-20 22:51:27
#> # … with 8 more variables: queued <dttm>, assigned <dttm>, started <dttm>,
#> #   finished <dttm>, code <int>, message <chr>, stdout <list>, stderr <list>
```
