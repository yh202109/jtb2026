#' Find rows containing a keyword
#'
#' Returns the subset of rows whose selected columns contain `keyword`. The
#' search is literal by default -- `"c++"` finds `"c++"`, not a regex error.
#' Row order is preserved; nothing is scored or reordered. For ranking by
#' meaning rather than by literal text, see [jtb_search_semantic()].
#'
#' @param data An Excel path, a delimited-file path, or a data frame. See
#'   [jtb_read_table()] for the full list of accepted inputs.
#' @param keyword The word or short phrase to look for. A character vector of
#'   length greater than one is combined according to `match`.
#' @param columns Columns to search, given as names (`c("term", "comment")`),
#'   as 1-based positions (`c(2, 5)`), or as a logical mask. `NULL`, the
#'   default, searches every column.
#' @param output_csv Optional path. When given, the returned rows are also
#'   written there with [utils::write.csv()] (`row.names = FALSE`).
#' @param ignore_case Match regardless of case. `TRUE` by default.
#' @param whole_word Require the keyword to sit on word boundaries, so
#'   `"ache"` no longer matches `"headache"`. `FALSE` by default.
#' @param regex Treat `keyword` as a regular expression instead of literal
#'   text. `FALSE` by default; when `TRUE`, `whole_word` is ignored and the
#'   pattern is used as written.
#' @param match With several keywords, `"any"` (the default) keeps rows
#'   matching at least one, `"all"` keeps rows matching every one. Under
#'   `"all"` the keywords may match in different columns of the same row.
#' @param add_match_info Append two reporting columns to the result:
#'   `.matched_columns` (the matching column names, comma separated) and
#'   `.matched_keywords`. `FALSE` by default.
#' @param sheet Worksheet to read when `data` is a path to an Excel workbook.
#' @param ... Passed on to [jtb_read_table()].
#'
#' @return A `data.frame` of matching rows, in their original order, with the
#'   original row names so you can trace a row back to its position in the
#'   input. Zero matches give a zero-row data frame with the same columns, not
#'   an error. The result carries a `"jtb_search"` attribute recording the
#'   keyword, the columns searched and the number of rows matched.
#'
#' @seealso [jtb_search_semantic()] for similarity ranking.
#'
#' @examples
#' # Every row mentioning "headache", anywhere in the table.
#' jtb_search_keyword(site_reports, "headache")
#'
#' # Restrict to two columns, by name or by position.
#' jtb_search_keyword(site_reports, "headache", columns = c("term", "comment"))
#' jtb_search_keyword(site_reports, "headache", columns = c(5, 6))
#'
#' # Whole words only: "ache" no longer matches "headache".
#' nrow(jtb_search_keyword(site_reports, "ache", columns = "comment"))
#' nrow(jtb_search_keyword(site_reports, "ache", columns = "comment",
#'                         whole_word = TRUE))
#'
#' # Several keywords, and a CSV copy of the result.
#' out <- tempfile(fileext = ".csv")
#' hits <- jtb_search_keyword(site_reports, c("nausea", "dizzy"),
#'                            columns = "comment", output_csv = out)
#' nrow(hits)
#' unlink(out)
#'
#' @export
jtb_search_keyword <- function(data,
                               keyword,
                               columns = NULL,
                               output_csv = NULL,
                               ignore_case = TRUE,
                               whole_word = FALSE,
                               regex = FALSE,
                               match = c("any", "all"),
                               add_match_info = FALSE,
                               sheet = 1,
                               ...) {
  match <- base::match.arg(match)
  if (!is.character(keyword) || length(keyword) == 0L || anyNA(keyword)) {
    stop("`keyword` must be a non-empty character vector without NA.",
         call. = FALSE)
  }
  if (any(!nzchar(keyword))) {
    stop("`keyword` must not contain empty strings.", call. = FALSE)
  }

  df <- jtb_read_table(data, sheet = sheet, ...)
  idx <- .jtb_resolve_columns(df, columns)
  cols <- .jtb_as_character(df, idx)

  patterns <- if (regex) {
    keyword
  } else {
    p <- .jtb_escape_regex(keyword)
    if (whole_word) paste0("\\b", p, "\\b") else p
  }

  n <- nrow(df)
  # hits[[k]] is the per-row logical for keyword k; col_hits accumulates which
  # column each row matched in, for `add_match_info`.
  hits <- vector("list", length(patterns))
  matched_cols <- rep(list(character()), n)
  matched_kw <- rep(list(character()), n)

  for (k in seq_along(patterns)) {
    hit_k <- rep(FALSE, n)
    for (cn in names(cols)) {
      m <- grepl(patterns[k], cols[[cn]], ignore.case = ignore_case,
                 perl = TRUE)
      if (add_match_info && any(m)) {
        for (i in which(m)) matched_cols[[i]] <- c(matched_cols[[i]], cn)
      }
      hit_k <- hit_k | m
    }
    if (add_match_info && any(hit_k)) {
      for (i in which(hit_k)) matched_kw[[i]] <- c(matched_kw[[i]], keyword[k])
    }
    hits[[k]] <- hit_k
  }

  hit_matrix <- do.call(cbind, hits)
  keep <- if (match == "any") {
    apply(hit_matrix, 1L, any)
  } else {
    apply(hit_matrix, 1L, all)
  }

  result <- df[keep, , drop = FALSE]
  if (add_match_info) {
    result$.matched_columns <- vapply(
      matched_cols[keep],
      function(x) paste(unique(x), collapse = ", "), ""
    )
    result$.matched_keywords <- vapply(
      matched_kw[keep],
      function(x) paste(unique(x), collapse = ", "), ""
    )
  }

  attr(result, "jtb_search") <- list(
    type = "keyword",
    keyword = keyword,
    columns = names(df)[idx],
    n_input = n,
    n_matched = nrow(result),
    ignore_case = ignore_case,
    whole_word = whole_word,
    regex = regex,
    match = match
  )

  .jtb_write_csv(result, output_csv)
  result
}

#' Escape regular-expression metacharacters
#' @noRd
.jtb_escape_regex <- function(x) {
  gsub("([.\\\\|()\\[\\]{}^$*+?])", "\\\\\\1", x, perl = TRUE)
}
