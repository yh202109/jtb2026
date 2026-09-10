#!/usr/bin/env bash
# Rebuild the package vignettes from vignettes/*.Rmd with
# devtools::build_vignettes().
#
# Note: build_vignettes() is soft-deprecated as of devtools 2.5.0. It still
# works and still warns; if it is ever removed, `R CMD build` renders the same
# vignettes into the tarball and is the drop-in replacement.
#
# Every code block in a vignette executes at build time against the package
# sources, so this is also a check: if an example stops working, the build
# fails rather than leaving stale output on the page.
#
# Output lands in doc/ (and Meta/vignette.rds), which is where devtools puts
# it and where vignette() picks it up during development. Both are gitignored
# and Rbuildignored -- the copies that ship come from R CMD build, which
# renders the .Rmd files again into inst/doc.
#
# Usage:
#   ci/build-vignettes.sh          # build to doc/
#   ci/build-vignettes.sh --clean  # remove doc/ and Meta/ first

set -euo pipefail
cd "$(dirname "$0")/.."

Rscript -e 'for (p in c("devtools", "remotes", "knitr", "rmarkdown")) {
  if (!requireNamespace(p, quietly = TRUE)) {
    stop("Package `", p, "` is required to build the vignettes. ",
         "Run ci/install-deps.R.")
  }
}'

if [[ "${1:-}" == "--clean" ]]; then
  echo "==> Removing doc/ and Meta/"
  rm -rf doc Meta
fi

echo "==> devtools::build_vignettes()"
Rscript -e 'devtools::build_vignettes(pkg = ".")'

BUILT=$(find doc -name '*.html' 2>/dev/null | wc -l | tr -d ' ')
EXPECTED=$(find vignettes -name '*.Rmd' | wc -l | tr -d ' ')
echo "==> Built $BUILT of $EXPECTED vignettes"
if [[ "$BUILT" != "$EXPECTED" ]]; then
  echo "!! Some vignettes were not built."
  echo "!! Check the VignetteBuilder field and the %\\VignetteEngine{} lines."
  exit 1
fi

ls -l doc/*.html
echo "OK: doc/"
