#!/usr/bin/env bash
# Run the testthat suite against the sources, without building a tarball.
# Much faster than ci/check.sh; use it while developing.

set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Installing the package into a temporary library"
LIB=$(mktemp -d)
trap 'rm -rf "$LIB"' EXIT
R CMD INSTALL --no-multiarch --library="$LIB" . >/dev/null

echo "==> Running tests"
R_LIBS="$LIB:${R_LIBS:-}" Rscript -e '
  res <- testthat::test_local(".", reporter = "summary", stop_on_failure = TRUE)
  invisible(res)
'
echo "OK"
