test_that("data frames pass through and files are read by extension", {
  expect_identical(jtb_read_table(site_reports), site_reports)

  csv <- withr::local_tempfile(fileext = ".csv")
  utils::write.csv(site_reports, csv, row.names = FALSE)
  from_csv <- jtb_read_table(csv)
  expect_s3_class(from_csv, "data.frame")
  expect_equal(nrow(from_csv), nrow(site_reports))
  expect_equal(names(from_csv), names(site_reports))
})

test_that("a matrix is accepted", {
  m <- matrix(c("alpha", "beta", "gamma", "delta"), nrow = 2)
  expect_s3_class(jtb_read_table(m), "data.frame")
  expect_equal(nrow(jtb_read_table(m)), 2L)
})

test_that("bad input is rejected with a useful message", {
  expect_error(jtb_read_table(1:5), "must be a data frame")
  expect_error(jtb_read_table("no-such-file.csv"), "File not found")
  f <- withr::local_tempfile(fileext = ".docx")
  file.create(f)
  expect_error(jtb_read_table(f), "Don't know how to read")
})

test_that("columns resolve by name, position, mask and NULL", {
  expect_equal(.jtb_resolve_columns(site_reports, NULL),
               seq_len(ncol(site_reports)))
  expect_equal(.jtb_resolve_columns(site_reports, c("term", "comment")),
               c(5L, 6L))
  expect_equal(.jtb_resolve_columns(site_reports, c(5, 6)), c(5L, 6L))
  mask <- rep(FALSE, ncol(site_reports))
  mask[c(5, 6)] <- TRUE
  expect_equal(.jtb_resolve_columns(site_reports, mask), c(5L, 6L))
  expect_equal(.jtb_resolve_columns(site_reports, c(5, 5, 6)), c(5L, 6L))
})

test_that("column errors name the problem", {
  expect_error(.jtb_resolve_columns(site_reports, "nope"), "not found")
  expect_error(.jtb_resolve_columns(site_reports, 99), "out of range")
  expect_error(.jtb_resolve_columns(site_reports, 1.5), "whole numbers")
  expect_error(.jtb_resolve_columns(site_reports, c(TRUE, FALSE)),
               "one entry per column")
  expect_error(.jtb_resolve_columns(site_reports, list(1)), "must be column")
})

test_that("NA cells become empty strings rather than matching", {
  df <- data.frame(a = c("headache", NA), b = c(NA, "nausea"),
                   stringsAsFactors = FALSE)
  expect_equal(nrow(jtb_search_keyword(df, "headache")), 1L)
  # An NA must not be searchable as the literal text "NA". (Case-sensitive,
  # because "NA" is otherwise a substring of "nausea".)
  expect_equal(nrow(jtb_search_keyword(df, "NA", ignore_case = FALSE)), 0L)
})
