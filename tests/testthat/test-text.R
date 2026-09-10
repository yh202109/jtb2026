test_that("tokenising lower-cases, splits and drops stop words", {
  tk <- jtb_tokenize("Subject reported a severe HEADACHE after dosing.",
                     stem = FALSE)[[1L]]
  expect_false(any(c("a", "after") %in% tk))
  expect_true(all(c("subject", "reported", "severe", "headache") %in% tk))
})

test_that("stemming collapses word endings", {
  tk <- jtb_tokenize(c("reported", "reporting", "reports"))
  expect_equal(length(unique(unlist(tk))), 1L)
})

test_that("the fallback stemmer keeps short and irregular words intact", {
  expect_equal(.jtb_stem_basic("is"), "is")
  expect_equal(.jtb_stem_basic("status"), "status")   # not a plural
  expect_equal(.jtb_stem_basic("illness"), "ill")     # "-ness", not "-s"
  expect_equal(.jtb_stem_basic("studies"), "study")
  expect_equal(.jtb_stem_basic("hives"), "hive")

  # A word and its plural must land on the same stem, which is what the
  # one-rule-per-word design buys: "doses" may not cascade past "dose".
  expect_equal(.jtb_stem_basic("doses"), .jtb_stem_basic("dose"))
  expect_equal(.jtb_stem_basic(c("report", "reports", "reported", "reporting")),
               rep("report", 4L))
})

test_that("empty and NA input tokenise to empty vectors", {
  tk <- jtb_tokenize(c("", NA, "   ", "!!!"))
  expect_true(all(lengths(tk) == 0L))
})

test_that("stopwords and min_chars are honoured", {
  expect_true("the" %in% jtb_tokenize("the dose", stopwords = character(),
                                      stem = FALSE)[[1L]])
  expect_false("ab" %in% jtb_tokenize("ab cdef", min_chars = 3L,
                                      stem = FALSE)[[1L]])
})

test_that("character n-grams are padded and sized", {
  ng <- .jtb_char_ngrams("dose", n = 3L)[[1L]]
  expect_equal(ng, c(" do", "dos", "ose", "se "))
  expect_equal(length(.jtb_char_ngrams("")[[1L]]), 0L)
})

test_that("cosine similarity behaves at its boundaries", {
  docs <- list(c("headache", "severe"), c("nausea"), character())
  same <- .jtb_tfidf_cosine(docs, c("headache", "severe"))
  expect_gt(same[1], same[2])
  expect_equal(same[3], 0)
  expect_true(all(same >= 0 & same <= 1))

  expect_equal(.jtb_tfidf_cosine(list(), "x"), numeric(0))
  expect_equal(.jtb_tfidf_cosine(docs, character()), rep(0, 3))
  expect_equal(.jtb_tfidf_cosine(docs, "absent"), rep(0, 3))
})

test_that("rarer terms carry more weight than common ones", {
  docs <- list(c("common", "rare"), c("common"), c("common"), c("common"))
  rare_hit <- .jtb_tfidf_cosine(docs, "rare")[1]
  common_hit <- .jtb_tfidf_cosine(docs, "common")[1]
  expect_gt(rare_hit, common_hit)
})

test_that("synonym expansion adds terms at reduced weight", {
  ex <- .jtb_expand_query("headache")
  expect_true("migrain" %in% ex$term || "migraine" %in% ex$term)
  expect_equal(ex$weight[1], 1)
  expect_true(all(ex$weight[-1] < 1))

  plain <- .jtb_expand_query("headache", synonyms = NULL)
  expect_equal(length(plain$term), 1L)
})

test_that("weights are rescaled to sum to one", {
  expect_equal(unname(.jtb_check_weights(c(token = 3, ngram = 1))),
               c(0.75, 0.25))
})

test_that("regex metacharacters are escaped", {
  expect_equal(.jtb_escape_regex("c++"), "c\\+\\+")
  expect_equal(.jtb_escape_regex("dose (2 mg)"), "dose \\(2 mg\\)")
  expect_equal(.jtb_escape_regex("a.b"), "a\\.b")
})
