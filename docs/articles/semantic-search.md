# Semantic search

> Ranking rows by how close they are to an idea.

``` r

library(jtb2026)
```

[`jtb_search_semantic()`](https://yh202109.github.io/jtb2026/reference/jtb_search_semantic.md)
asks a different question from the keyword search: not *does this row
contain the word*, but *how close is this row to the idea*. It returns
rows sorted best-first with a `.score` column, so the result is a
shortlist to read rather than a set to trust wholesale.

``` r

jtb_search_semantic(site_reports, "stomach upset",
                    columns = "comment", top_n = 4)[
                      , c("report_id", "comment", ".score")]
```

|  | report_id | comment | .score |
|:---|:---|:---|---:|
| 9 | R009 | Stomach felt unsettled after each dose and the subject vomited once on Day 9. | 0.533332 |
| 24 | R024 | Reported feeling sick to the stomach for an hour after dosing. | 0.403267 |
| 17 | R017 | Nauseous most mornings this cycle, improving by midday. | 0.129933 |
| 2 | R002 | Subject felt queasy through the afternoon and skipped the evening meal. | 0.115708 |

None of those rows contains the phrase “stomach upset”. Two do not even
contain the word “stomach”.

## How the score is computed

There is no neural network here by default. The score is a blend of two
classical similarities, which is what keeps the function offline, fast
and deterministic — the same call gives the same answer next year.

### 1. Token similarity (75% of the score)

The query and every row are put through
[`jtb_tokenize()`](https://yh202109.github.io/jtb2026/reference/jtb_tokenize.md):
lower-cased, split on punctuation, stripped of stop words, then stemmed
so word endings stop mattering.

``` r

jtb_tokenize("Subject reported a severe HEADACHE after dosing.")
#> [[1]]
#> [1] "subject" "report"  "sever"   "headach" "dose"
```

Compare that with the unstemmed version to see what the stemmer is
doing:

``` r

jtb_tokenize("Subject reported a severe HEADACHE after dosing.", stem = FALSE)
#> [[1]]
#> [1] "subject"  "reported" "severe"   "headache" "dosing"
```

Which stemmer runs depends on your library:
[`SnowballC::wordStem()`](https://rdrr.io/pkg/SnowballC/man/wordStem.html)
when that package is installed, and a small built-in suffix stripper
otherwise. The two do not always agree, so scores can shift slightly
between machines that differ on it — the *ranking* is stable, the third
decimal place is not. Install `SnowballC` on every machine that needs
identical numbers.

The tokens are then compared by **TF-IDF cosine similarity**. The IDF
half is what makes this better than counting shared words: a term that
appears in nearly every row carries almost no weight, while a rare term
carries a lot. In this table “subject” is nearly worthless and
“autoinjector” is decisive.

Before the comparison, the query is expanded through a thesaurus. A
query word belonging to a synonym group brings in the rest of that group
at `synonym_weight` (0.6 by default, so a synonym counts for rather less
than a word you actually typed). That expansion is what carries
“stomach” across to “queasy”:

``` r

jtb_synonyms()$nausea
#>  [1] "nausea"      "nauseous"    "queasy"      "sick"        "sickness"    "vomit"      
#>  [7] "vomited"     "vomiting"    "emesis"      "throwing"    "stomach"     "abdominal"  
#> [13] "gut"         "upset"       "unsettled"   "indigestion"
```

### 2. Fuzzy similarity (25% of the score)

The same cosine, computed over character 3-grams instead of words. This
is the half that survives a typo, an unusual plural or a word ending the
stemmer did not anticipate.

Row `R014` in the mock table misspells its own subject: *“Mild headche
noted in the diary”*. A correctly spelled query still reaches it.

``` r

fuzzy <- jtb_search_semantic(site_reports, "headache", columns = "comment",
                             top_n = NULL, min_score = 0.01)
fuzzy[, c("report_id", "comment", ".score")]
```

|  | report_id | comment | .score |
|:---|:---|:---|---:|
| 1 | R001 | Subject reported a dull headache starting two hours after the morning dose; resolved without treatment. | 0.282779 |
| 5 | R005 | Persistent head pain over three days, described as pressure behind the eyes. | 0.160636 |
| 14 | R014 | Mild headche noted in the diary, no medication taken. | 0.041742 |
| 9 | R009 | Stomach felt unsettled after each dose and the subject vomited once on Day 9. | 0.016366 |
| 6 | R006 | Felt lightheaded on standing at the clinic; blood pressure within range. | 0.014323 |
| 21 | R021 | Sharp pain across the forehead, subject took paracetamol with relief. | 0.013979 |
| 24 | R024 | Reported feeling sick to the stomach for an hour after dosing. | 0.011957 |
| 11 | R011 | Autoinjector battery died before the scheduled dose; a replacement was shipped. | 0.011303 |

Turn the fuzzy half off and the misspelled row disappears:

``` r

jtb_search_semantic(site_reports, "headache", columns = "comment",
                    weights = c(token = 1, ngram = 0),
                    top_n = NULL, min_score = 0.01)$report_id
#> [1] "R001" "R005"
```

### Reading the score

`.score` runs from 0 to 1 and is **comparable within one call only**.
IDF depends on the table being searched, so a 0.4 here and a 0.4 against
a different table do not mean the same thing. Use the ranking, and use
`min_score` as a cut-off you tune by looking at results — not as an
absolute quality bar.

## Controlling how much comes back

`top_n` caps the number of rows; `min_score` drops weak ones. Both
apply, and `top_n = NULL` means “no cap”.

``` r

# The default: at most the ten best rows, each scoring at least 0.05.
nrow(jtb_search_semantic(site_reports, "tired", columns = "comment"))
#> [1] 2

# Everything, scored, in rank order.
all_rows <- jtb_search_semantic(site_reports, "tired", columns = "comment",
                                top_n = NULL, min_score = 0)
nrow(all_rows)
#> [1] 24
head(all_rows$.score, 8)
#> [1] 0.301402 0.159492 0.011527 0.011511 0.010826 0.003735 0.003682 0.003365

# Only strong matches, however many that is.
jtb_search_semantic(site_reports, "tired", columns = "comment",
                    top_n = NULL, min_score = 0.2)[, c("report_id", "comment")]
```

|  | report_id | comment |
|:---|:---|:---|
| 3 | R003 | Reported feeling unusually tired all week and needing an extra nap each day. |

`add_score = FALSE` leaves the input columns untouched if you want the
rows without the two extra columns.

## Teaching it your vocabulary

The built-in thesaurus is a small starter set. It will not know your
domain, and the honest failure mode is a query that returns nothing:

``` r

nrow(jtb_search_semantic(site_reports, "skin irritation", columns = "comment"))
#> [1] 0
```

Neither “skin” nor “irritation” appears in the table, and neither is in
a default synonym group, so there is nothing to match on. Supply a group
and the same query works:

``` r

skin_terms <- list(
  skin = c("skin", "irritation", "irritated", "rash", "hives", "urticaria",
           "itchy", "itching", "patch", "redness", "swelling")
)

jtb_search_semantic(site_reports, "skin irritation", columns = "comment",
                    synonyms = skin_terms, top_n = 4)[
                      , c("report_id", "term", "comment", ".score")]
```

|  | report_id | term | comment | .score |
|:---|:---|:---|:---|---:|
| 8 | R008 | Injection site reaction | Redness and mild swelling around the injection site, faded within 48 hours. | 0.257906 |
| 4 | R004 | Rash | Small itchy patch on the left forearm, no spreading noted at review. | 0.245312 |
| 15 | R015 | Rash | Widespread hives across the trunk, antihistamine given by the site nurse. | 0.124061 |

Your list is merged over the defaults **by group name**, so adding a
group keeps everything else working, and reusing a default name replaces
that group:

``` r

# The nausea group is still in force alongside the new skin group.
jtb_search_semantic(site_reports, "stomach upset", columns = "comment",
                    synonyms = skin_terms, top_n = 2)$report_id
#> [1] "R009" "R024"
```

Pass `synonyms = NULL` to switch expansion off entirely. It is worth
doing once on a real query, to see how much of the answer the thesaurus
is responsible for:

``` r

with_thesaurus <- jtb_search_semantic(site_reports, "exhausted and sleepy",
                                      columns = "comment", top_n = 3)
without <- jtb_search_semantic(site_reports, "exhausted and sleepy",
                               columns = "comment", top_n = 3,
                               synonyms = NULL)

with_thesaurus[, c("report_id", "comment", ".score")]
```

|  | report_id | comment | .score |
|:---|:---|:---|---:|
| 20 | R020 | Exhausted after routine activity, sleeping longer than usual. | 0.379814 |
| 3 | R003 | Reported feeling unusually tired all week and needing an extra nap each day. | 0.164126 |

``` r

without[, c("report_id", "comment", ".score")]
```

|  | report_id | comment | .score |
|:---|:---|:---|---:|
| 20 | R020 | Exhausted after routine activity, sleeping longer than usual. | 0.423448 |

Only one row literally says “exhausted”; the thesaurus is what brings in
the row that says “unusually tired”.

## Other knobs

``` r

jtb_search_semantic(
  site_reports, "device problem",
  columns = c("term", "comment"),
  weights = c(token = 0.9, ngram = 0.1),  # trust words more than spelling
  synonym_weight = 0.8,                   # synonyms nearly as good as typed words
  stopwords = character(),                # keep "no", "not", "off" ...
  stem = FALSE                            # exact word forms only
)
```

`stopwords = character()` is worth remembering. The default list
contains `"no"` and `"not"`, so out of the box *“no rash reported”* and
*“rash reported”* look alike. Pass an empty stop-word list when negation
matters, and the negations survive into the comparison.

## Using a real embedding model

For genuine model-based semantics, pass `embed_fun`: any function that
takes a character vector and returns a numeric matrix with one row per
string. When it is supplied the two similarities above are skipped and
the score becomes the cosine similarity between the query’s embedding
and each row’s, rescaled to 0–1.

The shape of the contract is easiest to see with a toy embedding — one
dimension per letter:

``` r

letter_counts <- function(x) {
  t(vapply(strsplit(tolower(x), ""), function(ch) {
    tabulate(match(ch, letters), nbins = 26L)
  }, numeric(26)))
}

jtb_search_semantic(site_reports, "headache", columns = "comment",
                    embed_fun = letter_counts, top_n = 3)[
                      , c("report_id", "comment", ".score")]
```

|  | report_id | comment | .score |
|:---|:---|:---|---:|
| 11 | R011 | Autoinjector battery died before the scheduled dose; a replacement was shipped. | 0.853826 |
| 21 | R021 | Sharp pain across the forehead, subject took paracetamol with relief. | 0.839422 |
| 9 | R009 | Stomach felt unsettled after each dose and the subject vomited once on Day 9. | 0.837213 |

Those results are nonsense, which is the point: the function does
exactly what your embedding tells it to, and a bad embedding gives bad
rankings. A real one looks the same from the package’s side:

``` r

# Sketch: replace with whichever embedding service or local model you use.
embed <- function(x) {
  vecs <- lapply(x, function(txt) my_embedding_api(txt))  # numeric vectors
  do.call(rbind, vecs)
}

jtb_search_semantic("reports.xlsx", "device malfunction",
                    columns = "comment", embed_fun = embed, top_n = 20)
```

Two things to keep in mind. The function is called **once** with the
query followed by every row, so an API-backed embedding should batch
internally and you should cache it if you search the same table
repeatedly. And the result stops being reproducible: it is now only as
stable as the model behind it.

## What it will not do

- It does not understand negation, sarcasm or quantity. “No headache”
  and “severe headache” score similarly.
- It has no idea what your abbreviations mean unless you put them in
  `synonyms`.
- Ranking is not retrieval. If you need *every* row that mentions a term
  — for a count, an audit, a regulatory listing — use
  [`jtb_search_keyword()`](https://yh202109.github.io/jtb2026/reference/jtb_search_keyword.md),
  which is exhaustive by construction.

A good working pattern is to rank first to learn the vocabulary, then
keyword-search that vocabulary for the complete set.
[`vignette("jtb2026")`](https://yh202109.github.io/jtb2026/articles/jtb2026.md)
shows it end to end.
