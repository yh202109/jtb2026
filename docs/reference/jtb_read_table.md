# Read a table from a file or accept one already in memory

The search functions call this on their `data` argument, so anything
documented here is also accepted by
[`jtb_search_keyword()`](https://yh202109.github.io/jtb2026/reference/jtb_search_keyword.md)
and
[`jtb_search_semantic()`](https://yh202109.github.io/jtb2026/reference/jtb_search_semantic.md).

## Usage

``` r
jtb_read_table(data, sheet = 1, ...)
```

## Arguments

- data:

  One of:

  - a `data.frame` (including a tibble or `data.table`), returned as-is;

  - a matrix, converted column-wise to a `data.frame`;

  - a length-one character path to a file. The extension decides the
    reader: `.xlsx`/`.xls`/`.xlsm` use
    [`readxl::read_excel()`](https://readxl.tidyverse.org/reference/read_excel.html),
    `.csv` uses
    [`utils::read.csv()`](https://rdrr.io/r/utils/read.table.html),
    `.tsv`/`.txt` use
    [`utils::read.delim()`](https://rdrr.io/r/utils/read.table.html).

- sheet:

  Worksheet to read when `data` is an Excel path: a sheet name or a
  1-based position. Ignored for every other input.

- ...:

  Further arguments passed to the underlying reader
  ([`readxl::read_excel()`](https://readxl.tidyverse.org/reference/read_excel.html),
  [`utils::read.csv()`](https://rdrr.io/r/utils/read.table.html) or
  [`utils::read.delim()`](https://rdrr.io/r/utils/read.table.html)).

## Value

A `data.frame`.

## Examples

``` r
# A data frame passes straight through.
jtb_read_table(head(site_reports, 3))
#>   report_id   site subject  visit     term
#> 1      R001 Boston  S-1001 Week 2 Headache
#> 2      R002 Boston  S-1002 Week 2   Nausea
#> 3      R003 Boston  S-1003 Week 4  Fatigue
#>                                                                                                   comment
#> 1 Subject reported a dull headache starting two hours after the morning dose; resolved without treatment.
#> 2                                 Subject felt queasy through the afternoon and skipped the evening meal.
#> 3                            Reported feeling unusually tired all week and needing an extra nap each day.
#>   severity   outcome report_date
#> 1     Mild Recovered  2026-01-06
#> 2 Moderate Recovered  2026-01-07
#> 3     Mild   Ongoing  2026-01-21

# A file is read according to its extension.
csv <- tempfile(fileext = ".csv")
utils::write.csv(site_reports, csv, row.names = FALSE)
str(jtb_read_table(csv))
#> 'data.frame':    24 obs. of  9 variables:
#>  $ report_id  : chr  "R001" "R002" "R003" "R004" ...
#>  $ site       : chr  "Boston" "Boston" "Boston" "Boston" ...
#>  $ subject    : chr  "S-1001" "S-1002" "S-1003" "S-1004" ...
#>  $ visit      : chr  "Week 2" "Week 2" "Week 4" "Week 8" ...
#>  $ term       : chr  "Headache" "Nausea" "Fatigue" "Rash" ...
#>  $ comment    : chr  "Subject reported a dull headache starting two hours after the morning dose; resolved without treatment." "Subject felt queasy through the afternoon and skipped the evening meal." "Reported feeling unusually tired all week and needing an extra nap each day." "Small itchy patch on the left forearm, no spreading noted at review." ...
#>  $ severity   : chr  "Mild" "Moderate" "Mild" "Mild" ...
#>  $ outcome    : chr  "Recovered" "Recovered" "Ongoing" "Recovered" ...
#>  $ report_date: chr  "2026-01-06" "2026-01-07" "2026-01-21" "2026-02-18" ...
unlink(csv)
```
