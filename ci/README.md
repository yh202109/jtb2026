# ci/

The scripts CI runs. They are plain shell and R, take no arguments from the
workflow, and work the same on a laptop as on a runner — so a red build can be
reproduced locally by running the same script.

| Script | What it does |
| --- | --- |
| `install-deps.R` | Installs `Imports` and `Suggests` from `DESCRIPTION`, plus `roxygen2`. |
| `document.sh` | Rebuilds `data/site_reports.rda` from `data-raw/`, then regenerates `man/` and `NAMESPACE`. |
| `test.sh` | Installs the package into a temporary library and runs the testthat suite. Fast; use it while developing. |
| `build-vignettes.sh` | Rebuilds the vignettes and extracts the rendered HTML to `check/vignettes/`. `--local` renders in place instead, next to the `.Rmd` files. |
| `check.sh` | `R CMD build` + `R CMD check --as-cran`. Fails on any note, warning or error, and fails if `man/` is stale. Builds the vignettes on the way through. |

Run them from anywhere; each one `cd`s to the package root.

```bash
ci/test.sh                     # quickest useful signal
ci/build-vignettes.sh          # rebuild the documentation
ci/build-vignettes.sh --local  # ... leaving the HTML next to the .Rmd files
ci/check.sh                    # what the R-CMD-check workflow runs
```

The vignettes are plain `.Rmd` files built by the standard `knitr::rmarkdown`
engine, so `knitr` and `rmarkdown` are the only extra packages needed — no
external toolchain.

## Workflows

`.github/workflows/` holds three:

- **test.yaml** — runs `ci/test.sh` on every push to any branch. The
  two-minute signal.
- **R-CMD-check.yaml** — runs `ci/check.sh` on Linux, macOS and Windows, on
  every push and pull request to `main`. Uploads the `check/` directory as an
  artifact when a job fails, so you can read `00check.log` without rerunning.
- **vignettes.yaml** — runs `ci/build-vignettes.sh` whenever the vignettes or
  anything they document changes, and uploads the rendered HTML as an artifact
  so a reviewer can read the built pages straight from the run.

## Why the documentation rebuild is part of CI

Every code block in `vignettes/*.Rmd` executes at build time against the
freshly built package. Nothing in the documentation is a transcript pasted in
by hand, so a function whose behaviour changes cannot leave stale output
behind — the build either reproduces the new output or fails.

`R CMD build` renders the vignettes as part of making the tarball, so a broken
example fails `R-CMD-check` too, not just the vignettes job.
