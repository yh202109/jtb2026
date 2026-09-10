# Split text into normalised search tokens

The tokeniser the semantic search runs on every cell: lower-case, split
on anything that is not a letter or digit, drop stop words and very
short tokens, then stem. Exported so you can see exactly what the
scoring works from.

## Usage

``` r
jtb_tokenize(x, stopwords = jtb_stopwords(), stem = TRUE, min_chars = 2L)
```

## Arguments

- x:

  A character vector.

- stopwords:

  Words to drop. Defaults to
  [`jtb_stopwords()`](https://yh202109.github.io/jtb2026/reference/jtb_stopwords.md);
  pass [`character()`](https://rdrr.io/r/base/character.html) to keep
  everything.

- stem:

  Reduce words to a common root, so `"reported"` and `"reporting"`
  collapse together. Uses
  [`SnowballC::wordStem()`](https://rdrr.io/pkg/SnowballC/man/wordStem.html)
  when that package is installed and a built-in suffix stripper
  otherwise.

- min_chars:

  Drop tokens shorter than this, after stemming.

## Value

A list of character vectors, one per element of `x`.

## Examples

``` r
jtb_tokenize("Subject reported a severe HEADACHE after dosing.")
#> [[1]]
#> [1] "subject" "report"  "sever"   "headach" "dose"   
#> 
jtb_tokenize("Subject reported a severe HEADACHE after dosing.", stem = FALSE)
#> [[1]]
#> [1] "subject"  "reported" "severe"   "headache" "dosing"  
#> 
```
