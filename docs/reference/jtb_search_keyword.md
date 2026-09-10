# Find rows containing a keyword

Returns the subset of rows whose selected columns contain `keyword`. The
search is literal by default – `"c++"` finds `"c++"`, not a regex error.
Row order is preserved; nothing is scored or reordered. For ranking by
meaning rather than by literal text, see
[`jtb_search_semantic()`](https://yh202109.github.io/jtb2026/reference/jtb_search_semantic.md).

## Usage

``` r
jtb_search_keyword(
  data,
  keyword,
  columns = NULL,
  output_csv = NULL,
  ignore_case = TRUE,
  whole_word = FALSE,
  regex = FALSE,
  match = c("any", "all"),
  add_match_info = FALSE,
  sheet = 1,
  ...
)
```

## Arguments

- data:

  An Excel path, a delimited-file path, or a data frame. See
  [`jtb_read_table()`](https://yh202109.github.io/jtb2026/reference/jtb_read_table.md)
  for the full list of accepted inputs.

- keyword:

  The word or short phrase to look for. A character vector of length
  greater than one is combined according to `match`.

- columns:

  Columns to search, given as names (`c("term", "comment")`), as 1-based
  positions (`c(2, 5)`), or as a logical mask. `NULL`, the default,
  searches every column.

- output_csv:

  Optional path. When given, the returned rows are also written there
  with [`utils::write.csv()`](https://rdrr.io/r/utils/write.table.html)
  (`row.names = FALSE`).

- ignore_case:

  Match regardless of case. `TRUE` by default.

- whole_word:

  Require the keyword to sit on word boundaries, so `"ache"` no longer
  matches `"headache"`. `FALSE` by default.

- regex:

  Treat `keyword` as a regular expression instead of literal text.
  `FALSE` by default; when `TRUE`, `whole_word` is ignored and the
  pattern is used as written.

- match:

  With several keywords, `"any"` (the default) keeps rows matching at
  least one, `"all"` keeps rows matching every one. Under `"all"` the
  keywords may match in different columns of the same row.

- add_match_info:

  Append two reporting columns to the result: `.matched_columns` (the
  matching column names, comma separated) and `.matched_keywords`.
  `FALSE` by default.

- sheet:

  Worksheet to read when `data` is a path to an Excel workbook.

- ...:

  Passed on to
  [`jtb_read_table()`](https://yh202109.github.io/jtb2026/reference/jtb_read_table.md).

## Value

A `data.frame` of matching rows, in their original order, with the
original row names so you can trace a row back to its position in the
input. Zero matches give a zero-row data frame with the same columns,
not an error. The result carries a `"jtb_search"` attribute recording
the keyword, the columns searched and the number of rows matched.

## See also

[`jtb_search_semantic()`](https://yh202109.github.io/jtb2026/reference/jtb_search_semantic.md)
for similarity ranking.

## Examples

``` r
# Every row mentioning "headache", anywhere in the table.
jtb_search_keyword(site_reports, "headache")
#>    report_id    site subject  visit     term
#> 1       R001  Boston  S-1001 Week 2 Headache
#> 5       R005  Denver  S-2001 Week 2 Headache
#> 14      R014   Osaka  S-4002 Week 4 Headache
#> 21      R021 Nairobi  S-6001 Week 2 Headache
#>                                                                                                    comment
#> 1  Subject reported a dull headache starting two hours after the morning dose; resolved without treatment.
#> 5                             Persistent head pain over three days, described as pressure behind the eyes.
#> 14                                                   Mild headche noted in the diary, no medication taken.
#> 21                                   Sharp pain across the forehead, subject took paracetamol with relief.
#>    severity   outcome report_date
#> 1      Mild Recovered  2026-01-06
#> 5  Moderate Recovered  2026-01-09
#> 14     Mild Recovered  2026-01-25
#> 21 Moderate Recovered  2026-01-12

# Restrict to two columns, by name or by position.
jtb_search_keyword(site_reports, "headache", columns = c("term", "comment"))
#>    report_id    site subject  visit     term
#> 1       R001  Boston  S-1001 Week 2 Headache
#> 5       R005  Denver  S-2001 Week 2 Headache
#> 14      R014   Osaka  S-4002 Week 4 Headache
#> 21      R021 Nairobi  S-6001 Week 2 Headache
#>                                                                                                    comment
#> 1  Subject reported a dull headache starting two hours after the morning dose; resolved without treatment.
#> 5                             Persistent head pain over three days, described as pressure behind the eyes.
#> 14                                                   Mild headche noted in the diary, no medication taken.
#> 21                                   Sharp pain across the forehead, subject took paracetamol with relief.
#>    severity   outcome report_date
#> 1      Mild Recovered  2026-01-06
#> 5  Moderate Recovered  2026-01-09
#> 14     Mild Recovered  2026-01-25
#> 21 Moderate Recovered  2026-01-12
jtb_search_keyword(site_reports, "headache", columns = c(5, 6))
#>    report_id    site subject  visit     term
#> 1       R001  Boston  S-1001 Week 2 Headache
#> 5       R005  Denver  S-2001 Week 2 Headache
#> 14      R014   Osaka  S-4002 Week 4 Headache
#> 21      R021 Nairobi  S-6001 Week 2 Headache
#>                                                                                                    comment
#> 1  Subject reported a dull headache starting two hours after the morning dose; resolved without treatment.
#> 5                             Persistent head pain over three days, described as pressure behind the eyes.
#> 14                                                   Mild headche noted in the diary, no medication taken.
#> 21                                   Sharp pain across the forehead, subject took paracetamol with relief.
#>    severity   outcome report_date
#> 1      Mild Recovered  2026-01-06
#> 5  Moderate Recovered  2026-01-09
#> 14     Mild Recovered  2026-01-25
#> 21 Moderate Recovered  2026-01-12

# Whole words only: "ache" no longer matches "headache".
nrow(jtb_search_keyword(site_reports, "ache", columns = "comment"))
#> [1] 1
nrow(jtb_search_keyword(site_reports, "ache", columns = "comment",
                        whole_word = TRUE))
#> [1] 0

# Several keywords, and a CSV copy of the result.
out <- tempfile(fileext = ".csv")
hits <- jtb_search_keyword(site_reports, c("nausea", "dizzy"),
                           columns = "comment", output_csv = out)
nrow(hits)
#> [1] 0
unlink(out)
```
