# jtb2026 0.1.0

First release.

* `jtb_search_keyword()` returns the rows whose selected columns contain a
  keyword. Literal by default, with `regex`, `whole_word`, `ignore_case`,
  multiple keywords under `match = "any" | "all"`, and `add_match_info` to
  record which column matched.
* `jtb_search_semantic()` ranks rows by similarity to a query, blending TF-IDF
  cosine similarity over stemmed, synonym-expanded tokens with a fuzzy
  character-3-gram similarity. `embed_fun` hands the scoring to an embedding
  model instead.
* `jtb_read_table()` reads Excel workbooks, delimited files, matrices and data
  frames; both searches take their `data` argument straight to it.
* `jtb_tokenize()`, `jtb_stopwords()` and `jtb_synonyms()` expose the pieces
  the semantic score is built from.
* `site_reports`, a 24-row mock table used by the examples and vignettes.
* Both searches take `output_csv` and write exactly what they return.
