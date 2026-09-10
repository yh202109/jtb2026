#!/usr/bin/env bash
# Build the package tarball and run R CMD check on it.
#
# Usage: ci/check.sh [--as-cran]
# Run from the package root. Notes and warnings are fatal, so that a check
# that passes locally also passes in CI.

set -euo pipefail
cd "$(dirname "$0")/.."

AS_CRAN=${1:---as-cran}
OUT_DIR=${CHECK_DIR:-check}

echo "==> Regenerating documentation from roxygen comments"
Rscript -e 'roxygen2::roxygenise(".")'

if ! git diff --quiet -- man NAMESPACE 2>/dev/null; then
  echo "!! man/ or NAMESPACE is out of date with the roxygen comments."
  echo "!! Run ci/document.sh and commit the result."
  git --no-pager diff --stat -- man NAMESPACE
  exit 1
fi

echo "==> Building tarball"
mkdir -p "$OUT_DIR"
R CMD build --no-manual .
TARBALL=$(ls -t ./*.tar.gz | head -n 1)
mv "$TARBALL" "$OUT_DIR/"
TARBALL="$OUT_DIR/$(basename "$TARBALL")"

echo "==> Checking $TARBALL"
_R_CHECK_CRAN_INCOMING_=false \
_R_CHECK_FORCE_SUGGESTS_=false \
  R CMD check "$AS_CRAN" --no-manual --output="$OUT_DIR" "$TARBALL"

LOG=$(ls -d "$OUT_DIR"/*.Rcheck/00check.log | head -n 1)
echo "==> Result"
grep -E '(WARNING|NOTE|ERROR)' "$LOG" || true
echo "    $(grep -E '^Status:' "$LOG")"

# Count the check items that ended in WARNING/NOTE. The trailing "Status:"
# summary line matches the same pattern, so drop it before counting.
WARNINGS=$(grep -E '(^| )WARNING$' "$LOG" | grep -vc '^Status:' || true)
NOTES=$(grep -E '(^| )NOTE$' "$LOG" | grep -vc '^Status:' || true)

# `--as-cran` checks whether the PDFs under inst/doc could be made smaller, and
# warns unconditionally when qpdf is not installed to do the measuring. This
# package ships no PDFs at all -- the vignettes are HTML -- so on a machine
# without qpdf that warning describes the toolchain, not the package. Discount
# exactly that one, and only when qpdf really is absent.
if ! command -v qpdf >/dev/null 2>&1 &&
     grep -q 'qpdf.*needed for checks on size reduction' "$LOG"; then
  echo "==> Discounting the missing-qpdf warning (this package ships no PDFs)."
  echo "    Install qpdf to silence it: brew install qpdf / apt-get install qpdf"
  WARNINGS=$((WARNINGS - 1))
fi

if grep -qE '^Status:.*ERROR' "$LOG"; then
  echo "!! Check reported an error."
  exit 1
fi
if [[ "$WARNINGS" -gt 0 ]]; then
  echo "!! Check reported $WARNINGS warning(s)."
  exit 1
fi
if [[ "$NOTES" -gt 0 ]]; then
  echo "!! Check reported $NOTES note(s); treating a note as a failure."
  exit 1
fi
echo "OK"
