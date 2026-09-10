#' Read a table from a file or accept one already in memory
#'
#' The search functions call this on their `data` argument, so anything
#' documented here is also accepted by [jtb_search_keyword()] and
#' [jtb_search_semantic()].
#'
#' @param data One of:
#'   * a `data.frame` (including a tibble or `data.table`), returned as-is;
#'   * a matrix, converted column-wise to a `data.frame`;
#'   * a length-one character path to a file. The extension decides the
#'     reader: `.xlsx`/`.xls`/`.xlsm` use `readxl::read_excel()`, `.csv` uses
#'     [utils::read.csv()], `.tsv`/`.txt` use [utils::read.delim()].
#' @param sheet Worksheet to read when `data` is an Excel path: a sheet name
#'   or a 1-based position. Ignored for every other input.
#' @param ... Further arguments passed to the underlying reader
#'   (`readxl::read_excel()`, [utils::read.csv()] or [utils::read.delim()]).
#'
#' @return A `data.frame`.
#'
#' @examples
#' # A data frame passes straight through.
#' jtb_read_table(head(site_reports, 3))
#'
#' # A file is read according to its extension.
#' csv <- tempfile(fileext = ".csv")
#' utils::write.csv(site_reports, csv, row.names = FALSE)
#' str(jtb_read_table(csv))
#' unlink(csv)
#'
#' @export
jtb_read_table <- function(data, sheet = 1, ...) {
  if (is.data.frame(data)) {
    return(as.data.frame(data, stringsAsFactors = FALSE))
  }
  if (is.matrix(data)) {
    return(as.data.frame(data, stringsAsFactors = FALSE))
  }
  if (!is.character(data) || length(data) != 1L || is.na(data)) {
    stop(
      "`data` must be a data frame, a matrix, or a single file path, not ",
      class(data)[1], ".",
      call. = FALSE
    )
  }
  if (!file.exists(data)) {
    stop("File not found: ", data, call. = FALSE)
  }

  ext <- tolower(tools::file_ext(data))
  out <- switch(
    ext,
    xlsx = ,
    xlsm = ,
    xls = .jtb_read_excel(data, sheet = sheet, ...),
    csv = utils::read.csv(data, stringsAsFactors = FALSE, ...),
    tsv = ,
    txt = utils::read.delim(data, stringsAsFactors = FALSE, ...),
    stop(
      "Don't know how to read a '", ext, "' file. Supported extensions: ",
      "xlsx, xlsm, xls, csv, tsv, txt. Read it yourself and pass the ",
      "data frame instead.",
      call. = FALSE
    )
  )
  as.data.frame(out, stringsAsFactors = FALSE)
}

.jtb_read_excel <- function(path, sheet = 1, ...) {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop(
      "Reading Excel files needs the 'readxl' package. ",
      'Install it with install.packages("readxl"), or read the workbook ',
      "yourself and pass the resulting data frame.",
      call. = FALSE
    )
  }
  readxl::read_excel(path, sheet = sheet, ...)
}

#' Resolve a column selection to column indices
#'
#' Accepts the same `columns` argument as the search functions: column names,
#' 1-based positions, a logical mask, or `NULL` for "every column".
#'
#' @param data A data frame.
#' @param columns Column names, 1-based positions, a logical vector as long as
#'   `ncol(data)`, or `NULL`.
#' @return An integer vector of column positions.
#' @noRd
.jtb_resolve_columns <- function(data, columns = NULL) {
  n <- ncol(data)
  if (n == 0L) {
    stop("`data` has no columns to search.", call. = FALSE)
  }
  if (is.null(columns)) {
    return(seq_len(n))
  }
  if (is.logical(columns)) {
    if (length(columns) != n) {
      stop(
        "A logical `columns` must have one entry per column (", n, "), got ",
        length(columns), ".",
        call. = FALSE
      )
    }
    idx <- which(columns)
  } else if (is.numeric(columns)) {
    bad <- columns[is.na(columns) | columns < 1 | columns > n |
                     columns != round(columns)]
    if (length(bad)) {
      stop(
        "Column position(s) out of range or not whole numbers: ",
        paste(bad, collapse = ", "),
        ". The table has ", n, " columns.",
        call. = FALSE
      )
    }
    idx <- as.integer(columns)
  } else if (is.character(columns)) {
    idx <- match(columns, names(data))
    if (anyNA(idx)) {
      stop(
        "Column(s) not found: ",
        paste(sQuote(columns[is.na(idx)]), collapse = ", "),
        ". Available: ", paste(sQuote(names(data)), collapse = ", "),
        call. = FALSE
      )
    }
  } else {
    stop(
      "`columns` must be column names, 1-based positions, a logical mask, ",
      "or NULL.",
      call. = FALSE
    )
  }
  if (length(idx) == 0L) {
    stop("`columns` selected no columns.", call. = FALSE)
  }
  unique(idx)
}

#' Coerce selected columns to character
#' @noRd
.jtb_as_character <- function(data, idx) {
  out <- lapply(data[idx], function(col) {
    if (is.factor(col)) col <- as.character(col)
    if (is.list(col)) col <- vapply(col, function(x) paste(x, collapse = " "), "")
    col <- as.character(col)
    col[is.na(col)] <- ""
    col
  })
  names(out) <- names(data)[idx]
  out
}

#' Write a result to CSV if a path was given
#' @noRd
.jtb_write_csv <- function(result, output_csv) {
  if (is.null(output_csv)) {
    return(invisible(NULL))
  }
  if (!is.character(output_csv) || length(output_csv) != 1L ||
        is.na(output_csv)) {
    stop("`output_csv` must be a single file path or NULL.", call. = FALSE)
  }
  dir <- dirname(output_csv)
  if (!dir.exists(dir)) {
    stop("Output directory does not exist: ", dir, call. = FALSE)
  }
  utils::write.csv(result, output_csv, row.names = FALSE)
  invisible(output_csv)
}
