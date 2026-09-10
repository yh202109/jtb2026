#!/usr/bin/env Rscript
# Install everything the package needs to be checked and documented.
#
# The workflows in .github/workflows call this so that a local run of
# `ci/check.sh` installs exactly the same set of packages that CI does.

options(
  repos = c(CRAN = Sys.getenv("CRAN_REPO", "https://cloud.r-project.org")),
  warn = 2  # a failed install must not scroll past as a warning
)

needed <- c(
  # Imports and Suggests, read straight from DESCRIPTION.
  local({
    desc <- read.dcf("DESCRIPTION")
    fields <- intersect(c("Imports", "Suggests"), colnames(desc))
    deps <- unlist(strsplit(paste(desc[1, fields], collapse = ","), ","))
    deps <- trimws(gsub("\\(.*\\)", "", deps))
    deps[nzchar(deps) & deps != "R"]
  }),
  # Tooling that is not a package dependency.
  "roxygen2"
)

base_pkgs <- rownames(installed.packages(priority = "base"))
needed <- setdiff(unique(needed), base_pkgs)
missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing)) {
  message("Installing: ", paste(missing, collapse = ", "))
  install.packages(missing)
} else {
  message("All dependencies already present.")
}

still_missing <- missing[
  !vapply(missing, requireNamespace, logical(1), quietly = TRUE)
]
if (length(still_missing)) {
  stop("Failed to install: ", paste(still_missing, collapse = ", "))
}
