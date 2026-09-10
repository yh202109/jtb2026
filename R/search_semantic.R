#' Rank rows by how closely they match a query in meaning
#'
#' Where [jtb_search_keyword()] asks "does this row contain the word?", this
#' function asks "how close is this row to the idea?" and returns rows sorted
#' by score. A search for `"stomach upset"` can surface a row reading
#' *"subject felt nauseous after the morning dose"* even though the two share
#' no words.
#'
#' @section How the score is computed:
#' By default there is no neural network involved -- the score is a blend of
#' two classical similarities, which keeps the function dependency-free,
#' offline and deterministic:
#'
#' \enumerate{
#'   \item **Token similarity** (weight `weights["token"]`). Both the query
#'     and each row are tokenised by [jtb_tokenize()] -- lower-cased, stripped
#'     of stop words, stemmed -- then compared by TF-IDF cosine similarity.
#'     Rare words therefore count for more than common ones. Before the
#'     comparison the query is expanded through `synonyms`: a query word in a
#'     synonym group brings in the rest of that group at `synonym_weight`,
#'     which is what carries `"stomach upset"` across to `"nauseous"`.
#'   \item **Fuzzy similarity** (weight `weights["ngram"]`). The same cosine,
#'     computed over character 3-grams instead of words. This is what tolerates
#'     typos, plurals and word endings the stemmer misses.
#' }
#'
#' The two are combined as a weighted average and reported in `.score`, on a
#' 0-1 scale. Scores are comparable within one call, not across calls or
#' across tables -- IDF depends on the corpus being searched.
#'
#' For genuine embedding-model semantics, pass `embed_fun`: any function
#' taking a character vector and returning a numeric matrix with one row per
#' input. When it is supplied, the two similarities above are skipped and the
#' score is the cosine similarity between the query embedding and each row's,
#' rescaled from `[-1, 1]` to `[0, 1]`.
#'
#' @param data An Excel path, a delimited-file path, or a data frame. See
#'   [jtb_read_table()].
#' @param query The word, phrase or sentence to search for.
#' @param columns Columns to search, as names, 1-based positions, or a logical
#'   mask. `NULL`, the default, searches every column. Text columns are the
#'   useful ones; the values of each selected column are pasted together to
#'   form the text of a row.
#' @param output_csv Optional path. When given, the returned rows -- including
#'   the score columns -- are also written there with [utils::write.csv()].
#' @param top_n Keep at most this many rows, best first. `NULL` keeps every
#'   row above `min_score`. Defaults to 10.
#' @param min_score Drop rows scoring below this. Defaults to 0.05, which
#'   removes rows with no meaningful overlap; use 0 to keep everything.
#' @param synonyms A named list of character vectors, in the shape of
#'   [jtb_synonyms()], merged over the defaults by group name. `NULL` disables
#'   synonym expansion entirely.
#' @param synonym_weight Weight given to a term pulled in by a synonym group,
#'   relative to a term the user actually typed. Defaults to 0.6.
#' @param weights Named numeric vector giving the blend of the two
#'   similarities, `c(token = 0.75, ngram = 0.25)` by default. Rescaled to sum
#'   to 1. Ignored when `embed_fun` is supplied.
#' @param stopwords Words to ignore, defaulting to [jtb_stopwords()].
#' @param stem Stem tokens before comparing. `TRUE` by default.
#' @param embed_fun Optional embedding function; see the section above.
#' @param add_score Attach the `.score` and `.rank` columns to the result.
#'   `TRUE` by default; set `FALSE` to get the input columns untouched.
#' @param sheet Worksheet to read when `data` is a path to an Excel workbook.
#' @param ... Passed on to [jtb_read_table()].
#'
#' @return A `data.frame` of matching rows ordered by descending score, with
#'   the original row names preserved and, unless `add_score = FALSE`, two
#'   extra columns: `.score` (0-1) and `.rank` (1 is the best match). Ties are
#'   broken by original row order. The result carries a `"jtb_search"`
#'   attribute recording the query, the expanded query terms, the columns
#'   searched and the score settings.
#'
#' @seealso [jtb_search_keyword()] for exact matching, [jtb_tokenize()] and
#'   [jtb_synonyms()] for the pieces the score is built from.
#'
#' @examples
#' # "stomach upset" never appears in the table; the nausea rows still win.
#' jtb_search_semantic(site_reports, "stomach upset",
#'                     columns = "comment", top_n = 3)
#'
#' # Search several columns at once, and keep only strong matches.
#' jtb_search_semantic(site_reports, "device malfunction",
#'                     columns = c("term", "comment"),
#'                     top_n = NULL, min_score = 0.2)
#'
#' # Fuzzy matching absorbs the typo.
#' jtb_search_semantic(site_reports, "headche", columns = "comment", top_n = 3)
#'
#' # Compare with the keyword search, which finds nothing for either query.
#' nrow(jtb_search_keyword(site_reports, "stomach upset", columns = "comment"))
#'
#' @export
jtb_search_semantic <- function(data,
                                query,
                                columns = NULL,
                                output_csv = NULL,
                                top_n = 10L,
                                min_score = 0.05,
                                synonyms = jtb_synonyms(),
                                synonym_weight = 0.6,
                                weights = c(token = 0.75, ngram = 0.25),
                                stopwords = jtb_stopwords(),
                                stem = TRUE,
                                embed_fun = NULL,
                                add_score = TRUE,
                                sheet = 1,
                                ...) {
  if (!is.character(query) || length(query) != 1L || is.na(query) ||
        !nzchar(trimws(query))) {
    stop("`query` must be a single non-empty string.", call. = FALSE)
  }
  if (!is.null(top_n)) {
    if (!is.numeric(top_n) || length(top_n) != 1L || is.na(top_n) ||
          top_n < 1) {
      stop("`top_n` must be a single positive number, or NULL.", call. = FALSE)
    }
  }
  if (!is.numeric(min_score) || length(min_score) != 1L || is.na(min_score)) {
    stop("`min_score` must be a single number.", call. = FALSE)
  }

  df <- jtb_read_table(data, sheet = sheet, ...)
  idx <- .jtb_resolve_columns(df, columns)
  cols <- .jtb_as_character(df, idx)
  docs <- do.call(paste, c(cols, list(sep = " ")))
  n <- length(docs)

  if (!is.null(embed_fun)) {
    expanded <- NULL
    score <- .jtb_embed_score(docs, query, embed_fun)
  } else {
    w <- .jtb_check_weights(weights)
    expanded <- .jtb_expand_query(
      query, synonyms = synonyms, synonym_weight = synonym_weight,
      stopwords = stopwords, stem = stem
    )
    doc_tokens <- jtb_tokenize(docs, stopwords = stopwords, stem = stem)
    token_score <- .jtb_tfidf_cosine(doc_tokens, expanded$term, expanded$weight)

    ngram_score <- if (w[["ngram"]] > 0) {
      .jtb_tfidf_cosine(.jtb_char_ngrams(docs), .jtb_char_ngrams(query)[[1L]])
    } else {
      rep(0, n)
    }
    score <- w[["token"]] * token_score + w[["ngram"]] * ngram_score
  }

  ord <- order(-score, seq_len(n))
  keep <- ord[score[ord] >= min_score]
  if (!is.null(top_n) && length(keep) > top_n) {
    keep <- keep[seq_len(as.integer(top_n))]
  }

  result <- df[keep, , drop = FALSE]
  if (add_score) {
    result$.score <- round(score[keep], 6L)
    result$.rank <- if (length(keep)) seq_along(keep) else integer(0)
  }

  attr(result, "jtb_search") <- list(
    type = if (is.null(embed_fun)) "semantic" else "semantic (embedding)",
    query = query,
    query_terms = if (is.null(expanded)) NULL else expanded$term,
    columns = names(df)[idx],
    n_input = n,
    n_matched = nrow(result),
    top_n = top_n,
    min_score = min_score,
    weights = if (is.null(embed_fun)) .jtb_check_weights(weights) else NULL
  )

  .jtb_write_csv(result, output_csv)
  result
}

#' Expand a query into weighted terms
#'
#' Typed words keep weight 1; words reached through a synonym group come in at
#' `synonym_weight`. A word appearing in several groups pulls in all of them.
#' @noRd
.jtb_expand_query <- function(query,
                              synonyms = jtb_synonyms(),
                              synonym_weight = 0.6,
                              stopwords = jtb_stopwords(),
                              stem = TRUE) {
  base_terms <- jtb_tokenize(query, stopwords = stopwords, stem = stem)[[1L]]
  raw_terms <- jtb_tokenize(query, stopwords = stopwords, stem = FALSE)[[1L]]
  terms <- base_terms
  weight <- rep(1, length(terms))

  syn <- .jtb_merge_synonyms(synonyms)
  if (length(syn) && length(raw_terms)) {
    # Match on unstemmed query words against unstemmed group members, then
    # stem whatever the group contributes so it lines up with the documents.
    for (group in syn) {
      if (!any(raw_terms %in% group)) next
      extra <- setdiff(group, raw_terms)
      if (!length(extra)) next
      extra <- unlist(jtb_tokenize(extra, stopwords = character(), stem = stem),
                      use.names = FALSE)
      extra <- setdiff(unique(extra), terms)
      if (!length(extra)) next
      terms <- c(terms, extra)
      weight <- c(weight, rep(synonym_weight, length(extra)))
    }
  }
  list(term = terms, weight = weight)
}

#' @noRd
.jtb_merge_synonyms <- function(synonyms) {
  if (is.null(synonyms)) return(list())
  if (!is.list(synonyms)) {
    stop("`synonyms` must be a named list of character vectors, or NULL.",
         call. = FALSE)
  }
  if (!length(synonyms)) return(list())
  if (is.null(names(synonyms)) || any(!nzchar(names(synonyms)))) {
    stop("Every element of `synonyms` needs a group name.", call. = FALSE)
  }
  synonyms <- lapply(synonyms, function(g) tolower(as.character(g)))
  defaults <- jtb_synonyms()
  merged <- utils::modifyList(defaults, synonyms)
  merged[lengths(merged) > 0L]
}

#' @noRd
.jtb_check_weights <- function(weights) {
  if (!is.numeric(weights) || is.null(names(weights)) ||
        !all(c("token", "ngram") %in% names(weights))) {
    stop('`weights` must be a named numeric vector with "token" and "ngram" ',
         "entries.", call. = FALSE)
  }
  w <- c(token = weights[["token"]], ngram = weights[["ngram"]])
  if (anyNA(w) || any(w < 0) || sum(w) <= 0) {
    stop("`weights` must be non-negative and not all zero.", call. = FALSE)
  }
  w / sum(w)
}

#' @noRd
.jtb_embed_score <- function(docs, query, embed_fun) {
  if (!is.function(embed_fun)) {
    stop("`embed_fun` must be a function of one character vector.",
         call. = FALSE)
  }
  emb <- embed_fun(c(query, docs))
  if (!is.matrix(emb) || nrow(emb) != length(docs) + 1L) {
    stop(
      "`embed_fun` must return a matrix with one row per input string; got ",
      if (is.matrix(emb)) paste0(nrow(emb), " rows for ", length(docs) + 1L,
                                 " strings") else class(emb)[1],
      ".",
      call. = FALSE
    )
  }
  sim <- .jtb_cosine_matrix(emb[-1L, , drop = FALSE], emb[1L, ])
  (sim + 1) / 2
}
