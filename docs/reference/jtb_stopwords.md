# English stop words used by the semantic search

A small, general-purpose list. Pass your own vector to
`jtb_search_semantic(stopwords = ...)`, or
[`character()`](https://rdrr.io/r/base/character.html) to keep every
word.

## Usage

``` r
jtb_stopwords()
```

## Value

A character vector of lower-case stop words.

## Examples

``` r
head(jtb_stopwords(), 10)
#>  [1] "a"     "about" "above" "after" "again" "all"   "also"  "am"    "an"   
#> [10] "and"  
length(jtb_stopwords())
#> [1] 115
```
