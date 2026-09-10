#' English stop words used by the semantic search
#'
#' A small, general-purpose list. Pass your own vector to
#' `jtb_search_semantic(stopwords = ...)`, or `character()` to keep every word.
#'
#' @return A character vector of lower-case stop words.
#' @examples
#' head(jtb_stopwords(), 10)
#' length(jtb_stopwords())
#' @export
jtb_stopwords <- function() {
  c(
    "a", "about", "above", "after", "again", "all", "also", "am", "an", "and",
    "any", "are", "as", "at", "be", "because", "been", "before", "being",
    "below", "between", "both", "but", "by", "can", "did", "do", "does",
    "doing", "down", "during", "each", "few", "for", "from", "further", "had",
    "has", "have", "having", "he", "her", "here", "hers", "him", "his", "how",
    "i", "if", "in", "into", "is", "it", "its", "itself", "just", "me", "more",
    "most", "my", "no", "nor", "not", "now", "of", "off", "on", "once", "only",
    "or", "other", "our", "out", "over", "own", "same", "she", "should", "so",
    "some", "such", "than", "that", "the", "their", "them", "then", "there",
    "these", "they", "this", "those", "through", "to", "too", "under", "until",
    "up", "very", "was", "we", "were", "what", "when", "where", "which",
    "while", "who", "whom", "why", "will", "with", "would", "you", "your"
  )
}

#' Default synonym groups for query expansion
#'
#' A deliberately small starter thesaurus. Each element is a group of terms
#' treated as related: a query word matching any member is expanded to the
#' whole group, at reduced weight. The groups here are general English plus a
#' handful of clinical terms that suit the [site_reports] mock table -- for
#' real work, supply your own domain list, which is merged over these.
#'
#' @return A named list of character vectors. Names are group labels; the
#'   values are the terms in each group.
#' @seealso [jtb_search_semantic()], whose `synonyms` argument takes a list in
#'   this shape.
#' @examples
#' jtb_synonyms()$headache
#'
#' # Add a group of your own; it is merged over the defaults.
#' my_terms <- list(device = c("pump", "injector", "autoinjector", "pen"))
#' jtb_search_semantic(site_reports, "injector trouble",
#'                     columns = "comment", synonyms = my_terms, top_n = 3)
#' @export
jtb_synonyms <- function() {
  list(
    headache = c("headache", "migraine", "cephalalgia", "head", "cranial"),
    pain = c("pain", "ache", "aching", "sore", "soreness", "discomfort",
             "hurt", "hurts", "painful", "tender", "tenderness"),
    nausea = c("nausea", "nauseous", "queasy", "sick", "sickness", "vomit",
               "vomited", "vomiting", "emesis", "throwing", "stomach",
               "abdominal", "gut", "upset", "unsettled", "indigestion"),
    dizziness = c("dizzy", "dizziness", "lightheaded", "vertigo",
                  "faint", "fainting", "syncope", "woozy"),
    fatigue = c("fatigue", "tired", "tiredness", "exhausted", "exhaustion",
                "lethargy", "sleepy", "drowsy", "weary"),
    rash = c("rash", "hives", "urticaria", "itch", "itching", "itchy",
             "eruption", "redness", "erythema"),
    fever = c("fever", "febrile", "pyrexia", "temperature", "chills"),
    breathing = c("breathing", "breath", "dyspnea", "wheeze", "wheezing",
                  "shortness", "winded"),
    severe = c("severe", "serious", "bad", "intense", "strong", "marked",
               "significant"),
    mild = c("mild", "slight", "minor", "light", "small", "minimal"),
    increase = c("increase", "increased", "rise", "rose", "higher", "up",
                 "elevated", "worse", "worsening"),
    decrease = c("decrease", "decreased", "fall", "fell", "lower", "down",
                 "reduced", "better", "improving", "improved"),
    stop = c("stop", "stopped", "discontinue", "discontinued", "withdraw",
             "withdrawn", "halted", "terminated"),
    start = c("start", "started", "begin", "began", "initiate", "initiated",
              "onset"),
    problem = c("problem", "issue", "trouble", "difficulty", "complaint",
                "concern", "event", "error", "failure", "fault"),
    visit = c("visit", "appointment", "session", "encounter", "consultation")
  )
}

#' Split text into normalised search tokens
#'
#' The tokeniser the semantic search runs on every cell: lower-case, split on
#' anything that is not a letter or digit, drop stop words and very short
#' tokens, then stem. Exported so you can see exactly what the scoring works
#' from.
#'
#' @param x A character vector.
#' @param stopwords Words to drop. Defaults to [jtb_stopwords()]; pass
#'   `character()` to keep everything.
#' @param stem Reduce words to a common root, so `"reported"` and
#'   `"reporting"` collapse together. Uses `SnowballC::wordStem()` when that
#'   package is installed and a built-in suffix stripper otherwise.
#' @param min_chars Drop tokens shorter than this, after stemming.
#'
#' @return A list of character vectors, one per element of `x`.
#' @examples
#' jtb_tokenize("Subject reported a severe HEADACHE after dosing.")
#' jtb_tokenize("Subject reported a severe HEADACHE after dosing.", stem = FALSE)
#' @export
jtb_tokenize <- function(x,
                         stopwords = jtb_stopwords(),
                         stem = TRUE,
                         min_chars = 2L) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  x <- tolower(x)
  toks <- strsplit(x, "[^a-z0-9]+", perl = TRUE)
  if (is.null(stopwords)) stopwords <- character()
  lapply(toks, function(tk) {
    tk <- tk[nzchar(tk)]
    if (length(tk) == 0L) return(character())
    tk <- tk[!tk %in% stopwords]
    if (length(tk) == 0L) return(character())
    if (stem) tk <- .jtb_stem(tk)
    tk <- tk[nchar(tk) >= min_chars]
    tk
  })
}

#' Stem a character vector
#'
#' Uses SnowballC when available; otherwise strips a short list of common
#' English suffixes. The fallback is intentionally conservative -- it only
#' shortens words long enough to survive it.
#' @noRd
.jtb_stem <- function(x) {
  if (requireNamespace("SnowballC", quietly = TRUE)) {
    return(SnowballC::wordStem(x, language = "english"))
  }
  .jtb_stem_basic(x)
}

#' @noRd
.jtb_stem_basic <- function(x) {
  # Step 1, plurals, in the spirit of Porter's step 1a. The lookbehind spares
  # words that merely end in "ss" ("illness") or "us" ("status"); "doses" loses
  # only its "s", so it lands on the same stem as "dose".
  x <- sub("^(.{2,})sses$", "\\1ss", x, perl = TRUE)
  x <- sub("^(.+)ies$", "\\1y", x, perl = TRUE)
  x <- sub("^(.{2,})(?<![su])s$", "\\1", x, perl = TRUE)

  # Step 2: at most one derivational suffix per word. Applying these in
  # sequence instead would let stems cascade through several rules and land
  # somewhere neither the query nor the document agrees on.
  rules <- c(
    "^(.{3,})ness$" = "\\1",
    "^(.{4,})ment$" = "\\1",
    "^(.{3,})edly$" = "\\1",
    "^(.{3,})ing$"  = "\\1",
    "^(.{3,})ed$"   = "\\1",
    "^(.{3,})ly$"   = "\\1"
  )
  done <- rep(FALSE, length(x))
  for (i in seq_along(rules)) {
    hit <- !done & grepl(names(rules)[i], x, perl = TRUE)
    if (any(hit)) {
      x[hit] <- sub(names(rules)[i], rules[[i]], x[hit], perl = TRUE)
      done <- done | hit
    }
  }
  x
}

#' Character n-grams of a string
#'
#' Used for the fuzzy half of the semantic score: it is what lets a query
#' survive a typo or an unseen word ending.
#' @noRd
.jtb_char_ngrams <- function(x, n = 3L) {
  x <- tolower(as.character(x))
  x[is.na(x)] <- ""
  x <- gsub("[^a-z0-9]+", " ", x, perl = TRUE)
  x <- trimws(x)
  lapply(x, function(s) {
    if (!nzchar(s)) return(character())
    s <- paste0(" ", s, " ")
    len <- nchar(s)
    if (len < n) return(s)
    substring(s, seq_len(len - n + 1L), seq_len(len - n + 1L) + n - 1L)
  })
}

#' TF-IDF cosine similarity between one query and many documents
#'
#' Only the query's own features are ever visited on the numerator side, so
#' cost stays linear in the number of (document, token) pairs rather than
#' quadratic in the vocabulary.
#'
#' @param doc_tokens List of character vectors, one per document.
#' @param query_tokens Character vector of query tokens (may repeat).
#' @param query_weights Numeric vector parallel to `query_tokens`; synonyms
#'   come in below 1.
#' @return Numeric vector of cosine similarities, one per document, in 0-1.
#' @noRd
.jtb_tfidf_cosine <- function(doc_tokens, query_tokens, query_weights = NULL) {
  n_doc <- length(doc_tokens)
  if (n_doc == 0L) return(numeric(0))
  if (length(query_tokens) == 0L) return(rep(0, n_doc))
  if (is.null(query_weights)) query_weights <- rep(1, length(query_tokens))

  lens <- lengths(doc_tokens)
  if (all(lens == 0L)) return(rep(0, n_doc))

  terms <- unlist(doc_tokens, use.names = FALSE)
  docs <- rep.int(seq_len(n_doc), lens)
  vocab <- unique(terms)
  n_vocab <- length(vocab)
  term_id <- match(terms, vocab)

  # Collapse duplicate (document, term) pairs into counts.
  key <- (as.numeric(docs) - 1) * n_vocab + term_id
  ord <- order(key)
  runs <- rle(key[ord])
  u_key <- runs$values
  count <- runs$lengths
  u_doc <- as.integer((u_key - 1) %/% n_vocab) + 1L
  u_term <- as.integer((u_key - 1) %% n_vocab) + 1L

  df <- tabulate(u_term, nbins = n_vocab)
  idf <- log(1 + n_doc / (1 + df))

  weight <- (1 + log(count)) * idf[u_term]          # sublinear tf, times idf
  sq <- rowsum(weight^2, u_doc, reorder = TRUE)
  norms <- rep(0, n_doc)
  norms[as.integer(rownames(sq))] <- sqrt(as.vector(sq[, 1L]))

  # Query side: collapse repeats, keeping the strongest weight per term.
  q_id <- match(query_tokens, vocab)
  keep <- !is.na(q_id)
  if (!any(keep)) return(rep(0, n_doc))
  q_w <- query_weights[keep]
  agg <- tapply(q_w, q_id[keep],
                function(v) max(v) * (1 + log(length(v))))
  q_id <- as.integer(names(agg))
  q_vec <- as.numeric(agg) * idf[q_id]
  q_norm <- sqrt(sum(q_vec^2))
  if (q_norm == 0) return(rep(0, n_doc))

  sel <- u_term %in% q_id
  if (!any(sel)) return(rep(0, n_doc))
  contrib <- weight[sel] * q_vec[match(u_term[sel], q_id)]
  num_by_doc <- rowsum(contrib, u_doc[sel], reorder = TRUE)
  hit_docs <- as.integer(rownames(num_by_doc))

  score <- rep(0, n_doc)
  denom <- norms[hit_docs] * q_norm
  ok <- denom > 0
  score[hit_docs[ok]] <- as.vector(num_by_doc[, 1L])[ok] / denom[ok]
  pmin(pmax(score, 0), 1)
}

#' Cosine similarity between one vector and the rows of a matrix
#' @noRd
.jtb_cosine_matrix <- function(mat, vec) {
  norms <- sqrt(rowSums(mat^2))
  vnorm <- sqrt(sum(vec^2))
  if (vnorm == 0) return(rep(0, nrow(mat)))
  num <- as.vector(mat %*% vec)
  out <- rep(0, nrow(mat))
  ok <- norms > 0
  out[ok] <- num[ok] / (norms[ok] * vnorm)
  out
}
