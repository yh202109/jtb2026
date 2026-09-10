# Files in, CSV out

> Excel workbooks, delimited files, and what lands in the output.

``` r

library(jtb2026)
```

Both search functions take their `data` argument straight to
[`jtb_read_table()`](https://yh202109.github.io/jtb2026/reference/jtb_read_table.md),
so anything that reads works in either. Nothing about the search changes
with the input type — a path is simply a table you have not loaded yet.

## What `data` accepts

| `data` | What happens |
|----|----|
| A `data.frame`, tibble or `data.table` | Used as-is |
| A matrix | Converted column-wise to a data frame |
| `"file.xlsx"`, `.xlsm`, `.xls` | [`readxl::read_excel()`](https://readxl.tidyverse.org/reference/read_excel.html), honouring `sheet` |
| `"file.csv"` | [`utils::read.csv()`](https://rdrr.io/r/utils/read.table.html) |
| `"file.tsv"`, `"file.txt"` | [`utils::read.delim()`](https://rdrr.io/r/utils/read.table.html) |
| Anything else | An error naming the extensions that do work |

The package ships the mock table in both formats, so the examples below
are runnable:

``` r

xlsx <- system.file("extdata", "site_reports.xlsx", package = "jtb2026")
csv <- system.file("extdata", "site_reports.csv", package = "jtb2026")

basename(c(xlsx, csv))
#> [1] "site_reports.xlsx" "site_reports.csv"
```

## Searching an Excel workbook

``` r

jtb_search_keyword(xlsx, "hives", columns = "comment")[
  , c("report_id", "site", "comment")]
```

|  | report_id | site | comment |
|:---|:---|:---|:---|
| 15 | R015 | Osaka | Widespread hives across the trunk, antihistamine given by the site nurse. |

Reading Excel needs the `readxl` package, which is a suggested
dependency rather than a hard one — the rest of `jtb2026` works without
it, and asking for an `.xlsx` without it produces an error that says
exactly what to install.

### Choosing a worksheet

`sheet` takes a name or a 1-based position and is passed through to
`readxl`. It is ignored for every other input type, so it is harmless to
leave in a script that later switches to CSV.

``` r

jtb_search_keyword("study.xlsx", "headache", sheet = "Adverse events")
jtb_search_keyword("study.xlsx", "headache", sheet = 2)
```

Further arguments go to the reader too. That is how you skip a banner
row above the real header, a common shape for exported workbooks:

``` r

jtb_search_keyword("study.xlsx", "headache", sheet = 1, skip = 3)

# The same idea for a delimited file, where the argument belongs to read.csv().
jtb_search_keyword("export.csv", "headache", skip = 3, na.strings = c("", "NA"))
```

### Column positions and file input

Positions refer to the columns **as read**, which is worth checking once
when the file has a banner row or a stray index column:

``` r

names(jtb_read_table(csv))[c(5, 6)]
#> [1] "term"    "comment"

jtb_search_keyword(csv, "Nausea", columns = c(5, 6))$report_id
#> [1] "R002" "R009" "R017" "R024"
```

[`jtb_read_table()`](https://yh202109.github.io/jtb2026/reference/jtb_read_table.md)
is exported precisely so you can look at what the search saw before
trusting a positional selection.

## Delimited files

``` r

jtb_search_semantic(csv, "device malfunction",
                    columns = c("term", "comment"), top_n = 3)[
                      , c("report_id", "term", ".score")]
```

|     | report_id | term         |   .score |
|:----|:----------|:-------------|---------:|
| 19  | R019      | Device issue | 0.269293 |
| 7   | R007      | Device issue | 0.252576 |
| 11  | R011      | Device issue | 0.244722 |

A CSV read this way goes through
[`utils::read.csv()`](https://rdrr.io/r/utils/read.table.html), so its
type conversions apply — `report_date` arrives as text rather than a
`Date`, for instance. That makes no difference to searching, which
converts everything to text anyway, but it matters if you plan to do
arithmetic on the result.

``` r

class(jtb_read_table(csv)$report_date)
#> [1] "character"
class(site_reports$report_date)
#> [1] "Date"
```

## Writing the result out

`output_csv` writes the returned rows with
`utils::write.csv(row.names = FALSE)`. What you get in the file is what
you get in R — including the score columns from a semantic search, and
the reporting columns from `add_match_info = TRUE`.

``` r

out <- file.path(tempdir(), "semantic_hits.csv")

hits <- jtb_search_semantic(xlsx, "stomach upset", columns = "comment",
                            top_n = 3, output_csv = out)

names(hits)
#>  [1] "report_id"   "site"        "subject"     "visit"       "term"        "comment"    
#>  [7] "severity"    "outcome"     "report_date" ".score"      ".rank"
utils::read.csv(out)[, c("report_id", "comment", ".score", ".rank")]
```

| report_id | comment | .score | .rank |
|:---|:---|---:|---:|
| R009 | Stomach felt unsettled after each dose and the subject vomited once on Day 9. | 0.533332 | 1 |
| R024 | Reported feeling sick to the stomach for an hour after dosing. | 0.403267 | 2 |
| R017 | Nauseous most mornings this cycle, improving by midday. | 0.129933 | 3 |

The rows are written in the order they are returned, so a semantic
result arrives in the file already ranked — `.rank` 1 is the first data
row.

If the target directory does not exist, the function stops **before**
doing the search rather than working and then failing at the last step:

``` r

jtb_search_keyword(site_reports, "headache",
                   output_csv = file.path(tempdir(), "nope", "hits.csv"))
#> Error:
#> ! Output directory does not exist: /var/folders/7g/h804wdxj7y3dyqr1xw9cl6tr0000gn/T//RtmpwwV1UK/nope
```

## Round trip

Nothing stops you writing the result of one search and searching it
again — a practical way to narrow a large export in two passes without
holding the whole thing in memory twice.

``` r

step1 <- file.path(tempdir(), "boston.csv")

jtb_search_keyword(csv, "Boston", columns = "site", output_csv = step1)
```

| report_id | site | subject | visit | term | comment | severity | outcome | report_date |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| R001 | Boston | S-1001 | Week 2 | Headache | Subject reported a dull headache starting two hours after the morning dose; resolved without treatment. | Mild | Recovered | 2026-01-06 |
| R002 | Boston | S-1002 | Week 2 | Nausea | Subject felt queasy through the afternoon and skipped the evening meal. | Moderate | Recovered | 2026-01-07 |
| R003 | Boston | S-1003 | Week 4 | Fatigue | Reported feeling unusually tired all week and needing an extra nap each day. | Mild | Ongoing | 2026-01-21 |
| R004 | Boston | S-1004 | Week 8 | Rash | Small itchy patch on the left forearm, no spreading noted at review. | Mild | Recovered | 2026-02-18 |

``` r


jtb_search_semantic(step1, "head pain", columns = "comment", top_n = 2)[
  , c("report_id", "site", "comment", ".score")]
```

| report_id | site | comment | .score |
|:---|:---|:---|---:|
| R001 | Boston | Subject reported a dull headache starting two hours after the morning dose; resolved without treatment. | 0.2613 |

## Errors worth recognising

``` r

jtb_search_keyword("no-such-file.csv", "headache")
#> Error:
#> ! File not found: no-such-file.csv
```

``` r

jtb_search_keyword(site_reports, "headache", columns = "commnet")
#> Error:
#> ! Column(s) not found: 'commnet'. Available: 'report_id', 'site', 'subject', 'visit', 'term', 'comment', 'severity', 'outcome', 'report_date'
```

``` r

jtb_search_keyword(site_reports, "headache", columns = 99)
#> Error:
#> ! Column position(s) out of range or not whole numbers: 99. The table has 9 columns.
```

Each one names the problem and, where it can, what the valid options
were.
