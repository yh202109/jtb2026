# Default synonym groups for query expansion

A deliberately small starter thesaurus. Each element is a group of terms
treated as related: a query word matching any member is expanded to the
whole group, at reduced weight. The groups here are general English plus
a handful of clinical terms that suit the
[site_reports](https://yh202109.github.io/jtb2026/reference/site_reports.md)
mock table – for real work, supply your own domain list, which is merged
over these.

## Usage

``` r
jtb_synonyms()
```

## Value

A named list of character vectors. Names are group labels; the values
are the terms in each group.

## See also

[`jtb_search_semantic()`](https://yh202109.github.io/jtb2026/reference/jtb_search_semantic.md),
whose `synonyms` argument takes a list in this shape.

## Examples

``` r
jtb_synonyms()$headache
#> [1] "headache"    "migraine"    "cephalalgia" "head"        "cranial"    

# Add a group of your own; it is merged over the defaults.
my_terms <- list(device = c("pump", "injector", "autoinjector", "pen"))
jtb_search_semantic(site_reports, "injector trouble",
                    columns = "comment", synonyms = my_terms, top_n = 3)
#>    report_id    site subject  visit         term
#> 7       R007  Denver  S-2003 Week 4 Device issue
#> 11      R011  Lisbon  S-3003 Week 6 Device issue
#> 19      R019 Toronto  S-5003 Week 8 Device issue
#>                                                                            comment
#> 7              The injector pen jammed midway and the dose could not be completed.
#> 11 Autoinjector battery died before the scheduled dose; a replacement was shipped.
#> 19           Pump display froze and no dose confirmation was shown to the subject.
#>    severity                   outcome report_date   .score .rank
#> 7  Moderate Resolved with replacement  2026-01-24 0.373197     1
#> 11 Moderate Resolved with replacement  2026-02-13 0.161635     2
#> 19 Moderate Resolved with replacement  2026-02-22 0.127480     3
```
