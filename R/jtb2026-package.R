#' jtb2026: keyword and semantic search over tabular data
#'
#' The package answers one question: *which rows of this table mention the
#' thing I am looking for?* It accepts an Excel workbook, a delimited file or
#' an in-memory data frame, searches the columns you name, and hands back the
#' matching rows -- optionally writing them to a CSV file on the way out.
#'
#' @section Main functions:
#' \describe{
#'   \item{[jtb_search_keyword()]}{Literal or regular-expression matching.
#'     Returns every row that contains the term, in the original row order.}
#'   \item{[jtb_search_semantic()]}{Similarity *ranking*. Returns rows scored
#'     by TF-IDF cosine similarity with synonym expansion and fuzzy character
#'     n-gram matching, or by your own embedding function.}
#'   \item{[jtb_read_table()]}{The shared reader, exported so you can inspect
#'     what the search functions saw.}
#' }
#'
#' @section Mock data:
#' [site_reports] is a 24-row table of fictional study-site comments, used
#' throughout the documentation site in `doc/`.
#'
#' @keywords internal
"_PACKAGE"
