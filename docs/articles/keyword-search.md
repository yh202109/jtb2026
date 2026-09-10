# Keyword search

> Exhaustive, literal matching over the columns you choose.

``` r

library(jtb2026)
```

[`jtb_search_keyword()`](https://yh202109.github.io/jtb2026/reference/jtb_search_keyword.md)
returns every row whose selected columns contain the term. Nothing is
scored and nothing is reordered — the result is a subset of the input,
in the input’s order, with the input’s row names. That makes it the
right tool when you need completeness and traceability.

``` r

hits <- jtb_search_keyword(site_reports, "headache", columns = "comment")
hits[, c("report_id", "comment")]
```

| report_id | comment |
|:---|:---|
| R001 | Subject reported a dull headache starting two hours after the morning dose; resolved without treatment. |

One row. Three other rows in this table are also headaches — their coded
`term` says so — but their comments say “head pain”, “headche” and
“Sharp pain across the forehead”. A literal search cannot know that any
of those is the same thing, and it is not pretending otherwise. That gap
is what
[`vignette("semantic-search")`](https://yh202109.github.io/jtb2026/articles/semantic-search.md)
is for.

## Case

Matching ignores case by default. Turn that off when the casing carries
meaning, such as a coded term or an identifier.

``` r

nrow(jtb_search_keyword(site_reports, "HEADACHE"))
#> [1] 4
nrow(jtb_search_keyword(site_reports, "HEADACHE", ignore_case = FALSE))
#> [1] 0
```

## Whole words

By default a keyword matches anywhere inside a value, so `"ache"`
matches `"headache"`. `whole_word = TRUE` requires word boundaries on
both sides.

``` r

jtb_search_keyword(site_reports, "ache", columns = "comment")$report_id
#> [1] "R001"

nrow(jtb_search_keyword(site_reports, "ache", columns = "comment",
                        whole_word = TRUE))
#> [1] 0
```

This matters most for short keywords and for identifiers that are
prefixes of one another.

## Keywords are literal, not patterns

Punctuation in a keyword is searched for, not interpreted. There is no
need to escape anything.

``` r

doses <- data.frame(
  id = c("D1", "D2", "D3"),
  note = c("dose (2 mg) given", "dose 2 mg given", "wrote the c++ parser"),
  stringsAsFactors = FALSE
)

jtb_search_keyword(doses, "dose (2 mg)")
```

| id  | note              |
|:----|:------------------|
| D1  | dose (2 mg) given |

``` r

jtb_search_keyword(doses, "c++")
```

|     | id  | note                 |
|:----|:----|:---------------------|
| 3   | D3  | wrote the c++ parser |

Set `regex = TRUE` when you do want a pattern. The keyword is then
passed through as a PCRE regular expression, and `whole_word` is ignored
— write the anchors yourself.

``` r

jtb_search_keyword(doses, "dose [(]?[0-9]+ mg", regex = TRUE)
```

| id  | note              |
|:----|:------------------|
| D1  | dose (2 mg) given |
| D2  | dose 2 mg given   |

``` r


# Anything ending in a unit of mass.
jtb_search_keyword(doses, "\\d+ (mg|kg)\\b", regex = TRUE)$id
#> [1] "D1" "D2"
```

## Several keywords at once

Pass a character vector. `match = "any"`, the default, keeps rows
matching at least one keyword; `match = "all"` keeps rows matching every
one.

``` r

jtb_search_keyword(site_reports, c("nausea", "fatigue"),
                   columns = "term")[, c("report_id", "term")]
```

|     | report_id | term    |
|:----|:----------|:--------|
| 2   | R002      | Nausea  |
| 3   | R003      | Fatigue |
| 9   | R009      | Nausea  |
| 12  | R012      | Fatigue |
| 17  | R017      | Nausea  |
| 20  | R020      | Fatigue |
| 24  | R024      | Nausea  |

Under `match = "all"` the keywords may land in *different* columns of
the same row, which is what makes it useful for narrowing:

``` r

jtb_search_keyword(site_reports, c("Boston", "Headache"),
                   match = "all")[, c("report_id", "site", "term")]
```

| report_id | site   | term     |
|:----------|:-------|:---------|
| R001      | Boston | Headache |

Asking for two keywords that never co-occur returns an empty table
rather than an error:

``` r

nrow(jtb_search_keyword(site_reports, c("nausea", "fatigue"),
                        columns = "term", match = "all"))
#> [1] 0
```

## Knowing where the match was

With `add_match_info = TRUE` the result gains two reporting columns:
`.matched_columns` and `.matched_keywords`. Useful when you searched
several columns and want to know whether a hit came from the coded term
or from someone’s free text.

``` r

jtb_search_keyword(site_reports, "headache", add_match_info = TRUE)[
  , c("report_id", "term", ".matched_columns")]
```

|     | report_id | term     | .matched_columns |
|:----|:----------|:---------|:-----------------|
| 1   | R001      | Headache | term, comment    |
| 5   | R005      | Headache | term             |
| 14  | R014      | Headache | term             |
| 21  | R021      | Headache | term             |

Only `R001` matched in both places. The other three matched the coded
term alone, because their comments say “head pain”, “headche” and “Sharp
pain across the forehead” — three ways of writing a headache, none of
them the word.

## Nothing found

A search with no matches returns a zero-row data frame with the original
columns. Downstream code can carry on without a special case.

``` r

none <- jtb_search_keyword(site_reports, "unobtainium")
nrow(none)
#> [1] 0
names(none)
#> [1] "report_id"   "site"        "subject"     "visit"       "term"        "comment"    
#> [7] "severity"    "outcome"     "report_date"
```

## What the call did

Every result carries a `jtb_search` attribute recording how it was
produced. Handy for logging, and for writing down in a report what was
actually run.

``` r

str(attr(hits, "jtb_search"))
#> List of 9
#>  $ type       : chr "keyword"
#>  $ keyword    : chr "headache"
#>  $ columns    : chr "comment"
#>  $ n_input    : int 24
#>  $ n_matched  : int 1
#>  $ ignore_case: logi TRUE
#>  $ whole_word : logi FALSE
#>  $ regex      : logi FALSE
#>  $ match      : chr "any"
```

## Missing values

Empty cells are treated as empty text. An `NA` is never searchable as
the literal string `"NA"`, so a missing value cannot be mistaken for a
match.

``` r

partial <- data.frame(
  a = c("headache", NA),
  b = c(NA, "nausea"),
  stringsAsFactors = FALSE
)

nrow(jtb_search_keyword(partial, "headache"))
#> [1] 1
nrow(jtb_search_keyword(partial, "NA", ignore_case = FALSE))
#> [1] 0
```

## Writing the result out

`output_csv` writes exactly what is returned, including the reporting
columns when you asked for them. The directory has to exist; the
function stops before searching if it does not, rather than doing the
work and then failing.

``` r

out <- file.path(tempdir(), "keyword_hits.csv")

result <- jtb_search_keyword(site_reports, "headache",
                             columns = c("term", "comment"),
                             add_match_info = TRUE,
                             output_csv = out)

utils::read.csv(out)[, c("report_id", "term", ".matched_columns")]
```

| report_id | term     | .matched_columns |
|:----------|:---------|:-----------------|
| R001      | Headache | term, comment    |
| R005      | Headache | term             |
| R014      | Headache | term             |
| R021      | Headache | term             |

See
[`vignette("files-and-output")`](https://yh202109.github.io/jtb2026/articles/files-and-output.md)
for reading Excel workbooks and delimited files, and
[`?jtb_search_keyword`](https://yh202109.github.io/jtb2026/reference/jtb_search_keyword.md)
for the complete argument list.
