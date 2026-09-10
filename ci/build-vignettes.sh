#!/usr/bin/env bash
# Rebuild the package vignettes from vignettes/*.Rmd.
#
# Every code block in a vignette executes at build time against the installed
# package, so this is also a check: if an example stops working, the build
# fails rather than leaving stale output on the page.
#
# Usage:
#   ci/build-vignettes.sh          # build the tarball, extract the HTML to check/vignettes
#   ci/build-vignettes.sh --local  # render in place, leaving .html next to the .Rmd

set -euo pipefail
cd "$(dirname "$0")/.."

OUT_DIR=${CHECK_DIR:-check}

Rscript -e 'for (p in c("knitr", "rmarkdown")) {
  if (!requireNamespace(p, quietly = TRUE)) {
    stop("Package `", p, "` is required to build the vignettes. ",
         "Run ci/install-deps.R.")
  }
}'

echo "==> Installing the package into a temporary library"
LIB=$(mktemp -d)
trap 'rm -rf "$LIB"' EXIT
R CMD INSTALL --no-multiarch --library="$LIB" . >/dev/null
export R_LIBS="$LIB:${R_LIBS:-}"

if [[ "${1:-}" == "--local" ]]; then
  # Render each vignette where it sits. The .html files are gitignored;
  # this is the quick loop while writing.
  for rmd in vignettes/*.Rmd; do
    echo "==> Rendering $rmd"
    Rscript -e "rmarkdown::render('$rmd', quiet = TRUE)"
  done
  echo "OK: vignettes/*.html"
  exit 0
fi

echo "==> Building the package with vignettes"
mkdir -p "$OUT_DIR"
R CMD build .
TARBALL=$(ls -t ./*.tar.gz | head -n 1)
mv "$TARBALL" "$OUT_DIR/"
TARBALL="$OUT_DIR/$(basename "$TARBALL")"

echo "==> Extracting the built vignettes from $TARBALL"
rm -rf "$OUT_DIR/vignettes" "$OUT_DIR/extract"
mkdir -p "$OUT_DIR/extract"
tar -xzf "$TARBALL" -C "$OUT_DIR/extract"
SRC=$(dirname "$(find "$OUT_DIR/extract" -type d -name doc -path '*/inst/*' | head -n 1)")/doc
if [[ ! -d "$SRC" ]]; then
  echo "!! The tarball contains no inst/doc; no vignettes were built."
  exit 1
fi
mv "$SRC" "$OUT_DIR/vignettes"
rm -rf "$OUT_DIR/extract"

BUILT=$(find "$OUT_DIR/vignettes" -name '*.html' | wc -l | tr -d ' ')
EXPECTED=$(find vignettes -name '*.Rmd' | wc -l | tr -d ' ')
echo "==> Built $BUILT of $EXPECTED vignettes"
if [[ "$BUILT" != "$EXPECTED" ]]; then
  echo "!! Some vignettes did not make it into the tarball."
  echo "!! Check the VignetteBuilder field and the %\\VignetteEngine{} lines."
  exit 1
fi
ls -l "$OUT_DIR"/vignettes/*.html
echo "OK"
