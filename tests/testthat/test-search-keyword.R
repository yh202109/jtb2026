test_that("matching rows come back in their original order", {
  hits <- jtb_search_keyword(site_reports, "headache")
  expect_equal(hits$report_id, c("R001", "R005", "R014", "R021"))
  expect_equal(rownames(hits), c("1", "5", "14", "21"))
  expect_equal(names(hits), names(site_reports))
})

test_that("columns restrict where the keyword is looked for", {
  by_name <- jtb_search_keyword(site_reports, "Nausea", columns = "term")
  by_pos <- jtb_search_keyword(site_reports, "Nausea", columns = 5)
  expect_identical(by_name, by_pos)
  expect_true(all(by_name$term == "Nausea"))
  expect_equal(nrow(jtb_search_keyword(site_reports, "Nausea",
                                       columns = "comment")), 0L)
})

test_that("case sensitivity is under the caller's control", {
  expect_equal(nrow(jtb_search_keyword(site_reports, "HEADACHE")), 4L)
  expect_equal(
    nrow(jtb_search_keyword(site_reports, "HEADACHE", ignore_case = FALSE)),
    0L
  )
})

test_that("whole_word anchors on word boundaries", {
  loose <- jtb_search_keyword(site_reports, "ache", columns = "comment")
  strict <- jtb_search_keyword(site_reports, "ache", columns = "comment",
                               whole_word = TRUE)
  expect_gt(nrow(loose), nrow(strict))
  expect_equal(nrow(strict), 0L)
})

test_that("keywords are literal unless regex = TRUE", {
  df <- data.frame(x = c("dose (2 mg)", "dose 2 mg", "c++ tooling"),
                   stringsAsFactors = FALSE)
  expect_equal(nrow(jtb_search_keyword(df, "dose (2 mg)")), 1L)
  expect_equal(nrow(jtb_search_keyword(df, "c++")), 1L)
  expect_equal(nrow(jtb_search_keyword(df, "dose [(]?[0-9]", regex = TRUE)), 2L)
})

test_that("several keywords combine by any or all", {
  any_hit <- jtb_search_keyword(site_reports, c("nausea", "fatigue"),
                                columns = "term")
  all_hit <- jtb_search_keyword(site_reports, c("nausea", "fatigue"),
                                columns = "term", match = "all")
  expect_equal(nrow(any_hit), 7L)   # 4 nausea rows + 3 fatigue rows
  expect_equal(nrow(all_hit), 0L)

  both <- jtb_search_keyword(site_reports, c("Boston", "Headache"),
                             match = "all")
  expect_equal(both$report_id, "R001")
})

test_that("add_match_info reports where the hit was", {
  hits <- jtb_search_keyword(site_reports, "headache", add_match_info = TRUE)
  expect_true(all(c(".matched_columns", ".matched_keywords") %in% names(hits)))
  expect_equal(hits$.matched_columns[1], "term, comment")
  expect_equal(hits$.matched_columns[hits$report_id == "R005"], "term")
  expect_true(all(hits$.matched_keywords == "headache"))
})

test_that("no matches gives an empty frame, not an error", {
  none <- jtb_search_keyword(site_reports, "unobtainium")
  expect_equal(nrow(none), 0L)
  expect_equal(names(none), names(site_reports))
  expect_equal(attr(none, "jtb_search")$n_matched, 0L)
})

test_that("output_csv writes exactly what is returned", {
  out <- withr::local_tempfile(fileext = ".csv")
  hits <- jtb_search_keyword(site_reports, "headache", output_csv = out)
  expect_true(file.exists(out))
  written <- utils::read.csv(out, stringsAsFactors = FALSE)
  expect_equal(nrow(written), nrow(hits))
  expect_equal(written$report_id, hits$report_id)
  expect_equal(names(written), names(hits))
})

test_that("a bad output path fails before anything is written", {
  expect_error(
    jtb_search_keyword(site_reports, "headache",
                       output_csv = file.path(tempdir(), "no", "dir", "x.csv")),
    "Output directory does not exist"
  )
})

test_that("the search attribute records the call", {
  info <- attr(
    jtb_search_keyword(site_reports, "headache", columns = c("term", "comment")),
    "jtb_search"
  )
  expect_equal(info$type, "keyword")
  expect_equal(info$keyword, "headache")
  expect_equal(info$columns, c("term", "comment"))
  expect_equal(info$n_input, 24L)
  expect_equal(info$n_matched, 4L)
})

test_that("empty or malformed keywords are rejected", {
  expect_error(jtb_search_keyword(site_reports, character()), "non-empty")
  expect_error(jtb_search_keyword(site_reports, NA_character_), "non-empty")
  expect_error(jtb_search_keyword(site_reports, ""), "empty strings")
  expect_error(jtb_search_keyword(site_reports, 42), "character vector")
})

test_that("Excel input is searched like any other table", {
  skip_if_not_installed("readxl")
  xlsx <- system.file("extdata", "site_reports.xlsx", package = "jtb2026")
  skip_if(xlsx == "", "example workbook not installed")
  hits <- jtb_search_keyword(xlsx, "hives", columns = "comment")
  expect_equal(hits$report_id, "R015")
})
