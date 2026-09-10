#' Mock study-site reports
#'
#' Twenty-four invented rows of free-text site comments, used by the examples
#' and by the documentation site in `doc/`. The wording is chosen to make the
#' difference between the two searches visible: several rows describe nausea
#' without using the word, one row misspells *headache*, and "device issue"
#' rows talk about pens, pumps and autoinjectors rather than devices.
#'
#' Nothing in this table comes from a real study, a real site or a real
#' person.
#'
#' @format A `data.frame` with 24 rows and 9 columns:
#' \describe{
#'   \item{report_id}{Report identifier, `R001` to `R024`.}
#'   \item{site}{Study site name.}
#'   \item{subject}{Subject identifier.}
#'   \item{visit}{Scheduled visit label.}
#'   \item{term}{Coded event term.}
#'   \item{comment}{Free-text note -- the interesting column to search.}
#'   \item{severity}{`Mild`, `Moderate` or `Severe`.}
#'   \item{outcome}{Reported outcome.}
#'   \item{report_date}{Date of the report.}
#' }
#'
#' @source Invented for this package; see `data-raw/site_reports.R`.
#'
#' @examples
#' str(site_reports)
#' table(site_reports$term)
"site_reports"
