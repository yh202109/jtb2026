# jtb2026

<!-- badges: start -->
[![R-CMD-check](https://github.com/yh202109/jtb2026/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/yh202109/jtb2026/actions/workflows/R-CMD-check.yaml)
[![test](https://github.com/yh202109/jtb2026/actions/workflows/test.yaml/badge.svg)](https://github.com/yh202109/jtb2026/actions/workflows/test.yaml)
[![vignettes](https://github.com/yh202109/jtb2026/actions/workflows/vignettes.yaml/badge.svg)](https://github.com/yh202109/jtb2026/actions/workflows/vignettes.yaml)
<!-- badges: end -->

Find the rows of a table that mention what you are looking for.

Hand `jtb2026` an Excel workbook, a delimited file or a data frame, tell it
which columns to read and what to look for, and it returns the matching rows —
optionally writing them to a CSV on the way out.

Two functions, asking two different questions:

| | `jtb_search_keyword()` | `jtb_search_semantic()` |
| --- | --- | --- |
| Asks | *Does this row contain the word?* | *How close is this row to the idea?* |
| Returns | Every match, in the original row order | The best matches, ranked, with a score |
| Finds `"nauseous"` when you search `"stomach upset"` | No | Yes |
| Reproducible, offline, no model | Yes | Yes |

## Installation

```r
# install.packages("remotes")
remotes::install_github("yh202109/jtb2026", build_vignettes = FALSE)
```

Reading `.xlsx` files needs `readxl`, which is a suggested dependency:

```r
install.packages("readxl")
```

## Usage

```r
library(jtb2026)
```

The package ships `site_reports`, twenty-four invented rows of study-site
comments, used throughout the documentation.

### Keyword search

Every row containing the term, in the original order:

```r
jtb_search_keyword(site_reports, "headache", columns = c("term", "comment"))
```

```
   report_id    site subject   visit     term  comment ...
1       R001  Boston  S-1001  Week 2 Headache  Subject reported a dull headache ...
5       R005  Denver  S-2001  Week 2 Headache  Persistent head pain over three days ...
14      R014   Osaka  S-4002  Week 4 Headache  Mild headche noted in the diary ...
21      R021 Nairobi  S-6001  Week 2 Headache  Sharp pain across the forehead ...
```

`columns` takes names, 1-based positions (`c(5, 6)`) or a logical mask.
Other arguments: `ignore_case`, `whole_word`, `regex`, several keywords at once
with `match = "any" | "all"`, and `add_match_info` to record which column
matched.

### Semantic search

Nobody in the table wrote "stomach upset". All four nausea rows come back
anyway, ranked:

```r
jtb_search_semantic(site_reports, "stomach upset", columns = "comment", top_n = 4)
```

```
   report_id   term comment                                            .score .rank
9       R009 Nausea Stomach felt unsettled after each dose ...        0.531145     1
24      R024 Nausea Reported feeling sick to the stomach ...          0.376922     2
17      R017 Nausea Nauseous most mornings this cycle ...             0.126427     3
2       R002 Nausea Subject felt queasy through the afternoon ...     0.115708     4
```

The score blends TF-IDF cosine similarity over stemmed, synonym-expanded tokens
with a fuzzy character-3-gram similarity — no model, no network, same answer
every time. Supply `synonyms` to teach it your vocabulary, or `embed_fun` to
hand the scoring to a real embedding model.

### Writing results out

Both functions take `output_csv`, and write exactly what they return:

```r
jtb_search_keyword("reports.xlsx", "headache",
                   columns = c("term", "comment"),
                   output_csv = "headache_rows.csv")
```

## Documentation

See git page.

TO install with local vignette, 

```r
remotes::install_github("yh202109/jtb2026", build_vignettes = TRUE)
```

Four vignettes, all of them executed at build time against the package:

```r
vignette("jtb2026")            # get started
vignette("keyword-search")
vignette("semantic-search")
vignette("files-and-output")   # Excel sheets, delimited files, CSV output
```

## Development

```bash
ci/test.sh                     # run the test suite
ci/build-vignettes.sh          # rebuild the documentation
ci/check.sh                    # R CMD check --as-cran
```

See [`ci/README.md`](ci/README.md) for what each script does and which workflow
runs it.

## License

MIT. See [LICENSE.md](LICENSE.md).
