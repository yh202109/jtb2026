# Rank rows by how closely they match a query in meaning

Where
[`jtb_search_keyword()`](https://yh202109.github.io/jtb2026/reference/jtb_search_keyword.md)
asks "does this row contain the word?", this function asks "how close is
this row to the idea?" and returns rows sorted by score. A search for
`"stomach upset"` can surface a row reading *"subject felt nauseous
after the morning dose"* even though the two share no words.

## Usage

``` r
jtb_search_semantic(
  data,
  query,
  columns = NULL,
  output_csv = NULL,
  top_n = 10L,
  min_score = 0.05,
  synonyms = jtb_synonyms(),
  synonym_weight = 0.6,
  weights = c(token = 0.75, ngram = 0.25),
  stopwords = jtb_stopwords(),
  stem = TRUE,
  embed_fun = NULL,
  add_score = TRUE,
  sheet = 1,
  ...
)
```

## Arguments

- data:

  An Excel path, a delimited-file path, or a data frame. See
  [`jtb_read_table()`](https://yh202109.github.io/jtb2026/reference/jtb_read_table.md).

- query:

  The word, phrase or sentence to search for.

- columns:

  Columns to search, as names, 1-based positions, or a logical mask.
  `NULL`, the default, searches every column. Text columns are the
  useful ones; the values of each selected column are pasted together to
  form the text of a row.

- output_csv:

  Optional path. When given, the returned rows – including the score
  columns – are also written there with
  [`utils::write.csv()`](https://rdrr.io/r/utils/write.table.html).

- top_n:

  Keep at most this many rows, best first. `NULL` keeps every row above
  `min_score`. Defaults to 10.

- min_score:

  Drop rows scoring below this. Defaults to 0.05, which removes rows
  with no meaningful overlap; use 0 to keep everything.

- synonyms:

  A named list of character vectors, in the shape of
  [`jtb_synonyms()`](https://yh202109.github.io/jtb2026/reference/jtb_synonyms.md),
  merged over the defaults by group name. `NULL` disables synonym
  expansion entirely.

- synonym_weight:

  Weight given to a term pulled in by a synonym group, relative to a
  term the user actually typed. Defaults to 0.6.

- weights:

  Named numeric vector giving the blend of the two similarities,
  `c(token = 0.75, ngram = 0.25)` by default. Rescaled to sum to 1.
  Ignored when `embed_fun` is supplied.

- stopwords:

  Words to ignore, defaulting to
  [`jtb_stopwords()`](https://yh202109.github.io/jtb2026/reference/jtb_stopwords.md).

- stem:

  Stem tokens before comparing. `TRUE` by default.

- embed_fun:

  Optional embedding function; see the section above.

- add_score:

  Attach the `.score` and `.rank` columns to the result. `TRUE` by
  default; set `FALSE` to get the input columns untouched.

- sheet:

  Worksheet to read when `data` is a path to an Excel workbook.

- ...:

  Passed on to
  [`jtb_read_table()`](https://yh202109.github.io/jtb2026/reference/jtb_read_table.md).

## Value

A `data.frame` of matching rows ordered by descending score, with the
original row names preserved and, unless `add_score = FALSE`, two extra
columns: `.score` (0-1) and `.rank` (1 is the best match). Ties are
broken by original row order. The result carries a `"jtb_search"`
attribute recording the query, the expanded query terms, the columns
searched and the score settings.

## How the score is computed

By default there is no neural network involved – the score is a blend of
two classical similarities, which keeps the function dependency-free,
offline and deterministic:

1.  **Token similarity** (weight `weights["token"]`). Both the query and
    each row are tokenised by
    [`jtb_tokenize()`](https://yh202109.github.io/jtb2026/reference/jtb_tokenize.md)
    – lower-cased, stripped of stop words, stemmed – then compared by
    TF-IDF cosine similarity. Rare words therefore count for more than
    common ones. Before the comparison the query is expanded through
    `synonyms`: a query word in a synonym group brings in the rest of
    that group at `synonym_weight`, which is what carries
    `"stomach upset"` across to `"nauseous"`.

2.  **Fuzzy similarity** (weight `weights["ngram"]`). The same cosine,
    computed over character 3-grams instead of words. This is what
    tolerates typos, plurals and word endings the stemmer misses.

The two are combined as a weighted average and reported in `.score`, on
a 0-1 scale. Scores are comparable within one call, not across calls or
across tables – IDF depends on the corpus being searched.

For genuine embedding-model semantics, pass `embed_fun`: any function
taking a character vector and returning a numeric matrix with one row
per input. When it is supplied, the two similarities above are skipped
and the score is the cosine similarity between the query embedding and
each row's, rescaled from `[-1, 1]` to `[0, 1]`.

## See also

[`jtb_search_keyword()`](https://yh202109.github.io/jtb2026/reference/jtb_search_keyword.md)
for exact matching,
[`jtb_tokenize()`](https://yh202109.github.io/jtb2026/reference/jtb_tokenize.md)
and
[`jtb_synonyms()`](https://yh202109.github.io/jtb2026/reference/jtb_synonyms.md)
for the pieces the score is built from.

## Examples

``` r
# "stomach upset" never appears in the table; the nausea rows still win.
jtb_search_semantic(site_reports, "stomach upset",
                    columns = "comment", top_n = 3)
#>    report_id    site subject   visit   term
#> 9       R009  Lisbon  S-3001  Week 1 Nausea
#> 24      R024 Nairobi  S-6004 Week 12 Nausea
#> 17      R017 Toronto  S-5001  Week 1 Nausea
#>                                                                          comment
#> 9  Stomach felt unsettled after each dose and the subject vomited once on Day 9.
#> 24                Reported feeling sick to the stomach for an hour after dosing.
#> 17                       Nauseous most mornings this cycle, improving by midday.
#>    severity   outcome report_date   .score .rank
#> 9  Moderate Recovered  2026-01-08 0.533332     1
#> 24     Mild Recovered  2026-03-24 0.403267     2
#> 17 Moderate   Ongoing  2026-01-07 0.129933     3

# Search several columns at once, and keep only strong matches.
jtb_search_semantic(site_reports, "device malfunction",
                    columns = c("term", "comment"),
                    top_n = NULL, min_score = 0.2)
#>    report_id    site subject  visit         term
#> 19      R019 Toronto  S-5003 Week 8 Device issue
#> 7       R007  Denver  S-2003 Week 4 Device issue
#> 11      R011  Lisbon  S-3003 Week 6 Device issue
#>                                                                            comment
#> 19           Pump display froze and no dose confirmation was shown to the subject.
#> 7              The injector pen jammed midway and the dose could not be completed.
#> 11 Autoinjector battery died before the scheduled dose; a replacement was shipped.
#>    severity                   outcome report_date   .score .rank
#> 19 Moderate Resolved with replacement  2026-02-22 0.269293     1
#> 7  Moderate Resolved with replacement  2026-01-24 0.252576     2
#> 11 Moderate Resolved with replacement  2026-02-13 0.244722     3

# Fuzzy matching absorbs the typo.
jtb_search_semantic(site_reports, "headche", columns = "comment", top_n = 3)
#>    report_id  site subject  visit     term
#> 14      R014 Osaka  S-4002 Week 4 Headache
#>                                                  comment severity   outcome
#> 14 Mild headche noted in the diary, no medication taken.     Mild Recovered
#>    report_date   .score .rank
#> 14  2026-01-25 0.408878     1

# Compare with the keyword search, which finds nothing for either query.
nrow(jtb_search_keyword(site_reports, "stomach upset", columns = "comment"))
#> [1] 0
```
