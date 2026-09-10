#!/usr/bin/env bash
# Rebuild the vignettes from vignettes/*.Rmd with pkgdown::build_articles().
#
# Every code block in a vignette executes at build time against the package
# sources, so this is also a check: if an example stops working, the build
# fails rather than leaving stale output on the page.
#
# Output lands in docs/articles/, which is gitignored and Rbuildignored. These
# are read-and-review copies. The versions that ship in the package are
# rendered separately by `R CMD build` into inst/doc, which ci/check.sh
# exercises -- so a broken example fails the check as well as this script.
#
# (This replaces devtools::build_vignettes(), which devtools deprecated in
# 2.5.0 for leaving build artefacts in the development directory.)
#
# Usage:
#   ci/build-vignettes.sh          # build to docs/articles/
#   ci/build-vignettes.sh --clean  # discard the previous build first

set -euo pipefail
cd "$(dirname "$0")/.."

Rscript -e 'for (p in c("pkgdown", "knitr", "rmarkdown")) {
  if (!requireNamespace(p, quietly = TRUE)) {
    stop("Package `", p, "` is required to build the vignettes. ",
         "Run ci/install-deps.R.")
  }
}'

if [[ "${1:-}" == "--clean" ]]; then
  echo "==> Removing docs/"
  rm -rf docs
fi

echo "==> pkgdown::build_articles()"
Rscript -e 'pkgdown::build_articles(pkg = ".")'

BUILT=$(find docs/articles -name '*.html' ! -name 'index.html' 2>/dev/null |
          wc -l | tr -d ' ')
EXPECTED=$(find vignettes -name '*.Rmd' | wc -l | tr -d ' ')
echo "==> Built $BUILT of $EXPECTED vignettes"
if [[ "$BUILT" != "$EXPECTED" ]]; then
  echo "!! Some vignettes were not built."
  echo "!! Check that each .Rmd carries a %\\VignetteIndexEntry{} line."
  exit 1
fi

ls -l docs/articles/*.html
echo "OK: docs/articles/"
