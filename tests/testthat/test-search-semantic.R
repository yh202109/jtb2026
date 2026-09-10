test_that("rows come back ranked, with score columns", {
  hits <- jtb_search_semantic(site_reports, "stomach upset",
                              columns = "comment", top_n = 4)
  expect_true(all(c(".score", ".rank") %in% names(hits)))
  expect_equal(hits$.rank, seq_len(nrow(hits)))
  expect_false(is.unsorted(rev(hits$.score)))
  expect_true(all(hits$.score >= 0 & hits$.score <= 1))
})

test_that("meaning is matched where the literal word is absent", {
  # "stomach upset" appears nowhere in the table; every nausea row should.
  expect_equal(nrow(jtb_search_keyword(site_reports, "stomach upset",
                                       columns = "comment")), 0L)
  hits <- jtb_search_semantic(site_reports, "stomach upset",
                              columns = "comment", top_n = 4)
  expect_setequal(hits$report_id, c("R002", "R009", "R017", "R024"))
  expect_true(all(hits$term == "Nausea"))
})

test_that("synonym expansion is what carries the meaning across", {
  with_syn <- jtb_search_semantic(site_reports, "exhausted and sleepy",
                                  columns = "comment", top_n = 3)
  without <- jtb_search_semantic(site_reports, "exhausted and sleepy",
                                 columns = "comment", top_n = 3,
                                 synonyms = NULL)
  expect_true("R003" %in% with_syn$report_id)
  expect_false("R003" %in% without$report_id)
})

test_that("a caller's synonym groups are merged over the defaults", {
  hits <- jtb_search_semantic(
    site_reports, "skin irritation", columns = "comment", top_n = 5,
    synonyms = list(skin = c("skin", "irritation", "rash", "hives", "itchy",
                             "patch"))
  )
  expect_true(all(c("R004", "R015") %in% hits$report_id))

  # The default groups still work alongside the new one.
  still <- jtb_search_semantic(site_reports, "stomach upset",
                               columns = "comment", top_n = 2,
                               synonyms = list(skin = c("skin", "rash")))
  expect_true(all(still$term == "Nausea"))
})

test_that("character n-grams absorb a misspelling in the data", {
  # R014 writes "headche" in its comment. A correctly spelled query still
  # reaches it, because the fuzzy half of the score compares 3-grams.
  fuzzy <- jtb_search_semantic(site_reports, "headache", columns = "comment",
                               top_n = NULL, min_score = 0.01)
  expect_true("R014" %in% fuzzy$report_id)

  # Turn the fuzzy half off and only the correctly spelled rows survive.
  strict <- jtb_search_semantic(site_reports, "headache", columns = "comment",
                                weights = c(token = 1, ngram = 0),
                                top_n = NULL, min_score = 0.01)
  expect_false("R014" %in% strict$report_id)
  expect_setequal(strict$report_id, c("R001", "R005"))
})

test_that("top_n and min_score trim the result", {
  expect_equal(nrow(jtb_search_semantic(site_reports, "headache",
                                        columns = "comment", top_n = 2)), 2L)
  all_rows <- jtb_search_semantic(site_reports, "headache",
                                  columns = "comment",
                                  top_n = NULL, min_score = 0)
  expect_equal(nrow(all_rows), nrow(site_reports))
  strong <- jtb_search_semantic(site_reports, "headache", columns = "comment",
                                top_n = NULL, min_score = 0.3)
  expect_true(all(strong$.score >= 0.3))
})

test_that("add_score = FALSE leaves the input columns alone", {
  hits <- jtb_search_semantic(site_reports, "headache", columns = "comment",
                              top_n = 3, add_score = FALSE)
  expect_equal(names(hits), names(site_reports))
})

test_that("an embedding function takes over the scoring", {
  # A toy embedding: one dimension per letter of the alphabet.
  embed <- function(x) {
    t(vapply(strsplit(tolower(x), ""), function(ch) {
      tabulate(match(ch, letters), nbins = 26L)
    }, numeric(26)))
  }
  hits <- jtb_search_semantic(site_reports, "headache", columns = "comment",
                              embed_fun = embed, top_n = 5)
  expect_equal(nrow(hits), 5L)
  expect_true(all(hits$.score >= 0 & hits$.score <= 1))
  expect_equal(attr(hits, "jtb_search")$type, "semantic (embedding)")

  expect_error(
    jtb_search_semantic(site_reports, "headache", embed_fun = function(x) 1:3),
    "one row per input string"
  )
  expect_error(
    jtb_search_semantic(site_reports, "headache", embed_fun = "nope"),
    "must be a function"
  )
})

test_that("output_csv includes the score columns", {
  out <- withr::local_tempfile(fileext = ".csv")
  hits <- jtb_search_semantic(site_reports, "stomach upset",
                              columns = "comment", top_n = 3,
                              output_csv = out)
  written <- utils::read.csv(out, stringsAsFactors = FALSE)
  expect_equal(written$.rank, hits$.rank)
  expect_equal(written$report_id, hits$report_id)
})

test_that("arguments are validated", {
  expect_error(jtb_search_semantic(site_reports, c("a", "b")), "single")
  expect_error(jtb_search_semantic(site_reports, "  "), "non-empty")
  expect_error(jtb_search_semantic(site_reports, "x", top_n = 0), "positive")
  expect_error(jtb_search_semantic(site_reports, "x", min_score = NA), "number")
  expect_error(jtb_search_semantic(site_reports, "x", synonyms = "pain"),
               "named list")
  expect_error(jtb_search_semantic(site_reports, "x",
                                   synonyms = list(c("a", "b"))),
               "group name")
  expect_error(jtb_search_semantic(site_reports, "x", weights = c(a = 1)),
               "token")
  expect_error(jtb_search_semantic(site_reports, "x",
                                   weights = c(token = 0, ngram = 0)),
               "not all zero")
})

test_that("a query with nothing to match on scores zero everywhere", {
  hits <- jtb_search_semantic(site_reports, "qqqq", columns = "comment",
                              top_n = NULL, min_score = 0)
  expect_equal(nrow(hits), nrow(site_reports))
  expect_true(all(hits$.score < 0.05))
})
