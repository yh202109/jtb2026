#!/usr/bin/env bash
# Regenerate man/ and NAMESPACE from the roxygen comments, and rebuild the
# mock dataset from data-raw/. Commit whatever this changes.

set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Rebuilding data-raw/site_reports.R"
Rscript data-raw/site_reports.R

echo "==> Roxygenising"
Rscript -e 'roxygen2::roxygenise(".")'
echo "OK"
