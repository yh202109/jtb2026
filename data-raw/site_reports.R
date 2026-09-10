# Builds the `site_reports` mock table shipped with the package.
# Run with: Rscript data-raw/site_reports.R
#
# Everything here is invented. The rows are chosen so that the two search
# functions behave visibly differently on them: several rows describe the same
# idea in different words (nausea / queasy / stomach), one contains a near-miss
# spelling, and a few share a keyword while meaning different things.

site_reports <- data.frame(
  report_id = sprintf("R%03d", 1:24),
  site = c(
    "Boston", "Boston", "Boston", "Boston", "Denver", "Denver", "Denver",
    "Denver", "Lisbon", "Lisbon", "Lisbon", "Lisbon", "Osaka", "Osaka",
    "Osaka", "Osaka", "Toronto", "Toronto", "Toronto", "Toronto",
    "Nairobi", "Nairobi", "Nairobi", "Nairobi"
  ),
  subject = c(
    "S-1001", "S-1002", "S-1003", "S-1004", "S-2001", "S-2002", "S-2003",
    "S-2004", "S-3001", "S-3002", "S-3003", "S-3004", "S-4001", "S-4002",
    "S-4003", "S-4004", "S-5001", "S-5002", "S-5003", "S-5004",
    "S-6001", "S-6002", "S-6003", "S-6004"
  ),
  visit = c(
    "Week 2", "Week 2", "Week 4", "Week 8", "Week 2", "Week 4", "Week 4",
    "Week 12", "Week 1", "Week 2", "Week 6", "Week 8", "Week 2", "Week 4",
    "Week 6", "Week 12", "Week 1", "Week 4", "Week 8", "Week 8",
    "Week 2", "Week 4", "Week 6", "Week 12"
  ),
  term = c(
    "Headache", "Nausea", "Fatigue", "Rash", "Headache", "Dizziness",
    "Device issue", "Injection site reaction", "Nausea", "Pyrexia",
    "Device issue", "Fatigue", "Dizziness", "Headache", "Rash",
    "Protocol deviation", "Nausea", "Dyspnoea", "Device issue", "Fatigue",
    "Headache", "Injection site reaction", "Protocol deviation", "Nausea"
  ),
  comment = c(
    "Subject reported a dull headache starting two hours after the morning dose; resolved without treatment.",
    "Subject felt queasy through the afternoon and skipped the evening meal.",
    "Reported feeling unusually tired all week and needing an extra nap each day.",
    "Small itchy patch on the left forearm, no spreading noted at review.",
    "Persistent head pain over three days, described as pressure behind the eyes.",
    "Felt lightheaded on standing at the clinic; blood pressure within range.",
    "The injector pen jammed midway and the dose could not be completed.",
    "Redness and mild swelling around the injection site, faded within 48 hours.",
    "Stomach felt unsettled after each dose and the subject vomited once on Day 9.",
    "Temperature of 38.4C recorded at the visit, chills reported the night before.",
    "Autoinjector battery died before the scheduled dose; a replacement was shipped.",
    "Low energy since the last visit, difficulty completing the daily walk.",
    "Room seemed to spin briefly when getting out of bed, lasted under a minute.",
    "Mild headche noted in the diary, no medication taken.",
    "Widespread hives across the trunk, antihistamine given by the site nurse.",
    "Dose was administered 40 minutes outside the protocol window.",
    "Nauseous most mornings this cycle, improving by midday.",
    "Short of breath climbing one flight of stairs, resolved after resting.",
    "Pump display froze and no dose confirmation was shown to the subject.",
    "Exhausted after routine activity, sleeping longer than usual.",
    "Sharp pain across the forehead, subject took paracetamol with relief.",
    "Tender bruise at the injection site that lasted about four days.",
    "Study visit occurred eight days late because of travel disruption.",
    "Reported feeling sick to the stomach for an hour after dosing."
  ),
  severity = c(
    "Mild", "Moderate", "Mild", "Mild", "Moderate", "Mild", "Moderate",
    "Mild", "Moderate", "Moderate", "Moderate", "Mild", "Mild", "Mild",
    "Severe", "Mild", "Moderate", "Moderate", "Moderate", "Moderate",
    "Moderate", "Mild", "Mild", "Mild"
  ),
  outcome = c(
    "Recovered", "Recovered", "Ongoing", "Recovered", "Recovered",
    "Recovered", "Resolved with replacement", "Recovered", "Recovered",
    "Recovered", "Resolved with replacement", "Ongoing", "Recovered",
    "Recovered", "Recovered", "Not applicable", "Ongoing", "Recovered",
    "Resolved with replacement", "Ongoing", "Recovered", "Recovered",
    "Not applicable", "Recovered"
  ),
  report_date = as.Date("2026-01-06") + c(
    0, 1, 15, 43, 3, 17, 18, 74, 2, 9, 38, 52, 5, 19, 33, 79,
    1, 20, 47, 51, 6, 21, 35, 77
  ),
  stringsAsFactors = FALSE
)

# Run from the package root.
root <- "."
if (!file.exists(file.path(root, "DESCRIPTION"))) {
  stop("Run this script from the package root.")
}
dir.create(file.path(root, "data"), showWarnings = FALSE)
dir.create(file.path(root, "inst", "extdata"), showWarnings = FALSE,
           recursive = TRUE)

save(site_reports,
     file = file.path(root, "data", "site_reports.rda"),
     version = 3, compress = "bzip2")

# An Excel copy for the file-input examples, when writexl is available.
if (requireNamespace("writexl", quietly = TRUE)) {
  writexl::write_xlsx(
    site_reports,
    file.path(root, "inst", "extdata", "site_reports.xlsx")
  )
}

utils::write.csv(
  site_reports,
  file.path(root, "inst", "extdata", "site_reports.csv"),
  row.names = FALSE
)
