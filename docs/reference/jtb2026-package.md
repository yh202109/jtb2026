# jtb2026: keyword and semantic search over tabular data

The package answers one question: *which rows of this table mention the
thing I am looking for?* It accepts an Excel workbook, a delimited file
or an in-memory data frame, searches the columns you name, and hands
back the matching rows – optionally writing them to a CSV file on the
way out.

## Main functions

- [`jtb_search_keyword()`](https://yh202109.github.io/jtb2026/reference/jtb_search_keyword.md):

  Literal or regular-expression matching. Returns every row that
  contains the term, in the original row order.

- [`jtb_search_semantic()`](https://yh202109.github.io/jtb2026/reference/jtb_search_semantic.md):

  Similarity *ranking*. Returns rows scored by TF-IDF cosine similarity
  with synonym expansion and fuzzy character n-gram matching, or by your
  own embedding function.

- [`jtb_read_table()`](https://yh202109.github.io/jtb2026/reference/jtb_read_table.md):

  The shared reader, exported so you can inspect what the search
  functions saw.

## Mock data

[site_reports](https://yh202109.github.io/jtb2026/reference/site_reports.md)
is a 24-row table of fictional study-site comments, used throughout the
documentation site in `doc/`.

## See also

Useful links:

- <https://github.com/yh202109/jtb2026>

- Report bugs at <https://github.com/yh202109/jtb2026/issues>

## Author

**Maintainer**: yh202109 <yh202109@google.com>

Authors:

- yh202109 <yh202109@google.com>
