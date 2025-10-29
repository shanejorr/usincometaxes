## Resubmission

This is a minor update (v0.7.2) that updates the TAXSIM WebAssembly files to the latest version and includes documentation improvements.

Changes:
- Updated `taxsim.wasm` and `taxsim.js` to latest version from taxsim.app
- Added 10 new output columns from updated WASM version
- Fixed documentation gaps (added `mortgage` input field, fixed `ggsi` typo)
- Added internal SSH testing infrastructure for development

# R CMD check test environment

## Local macOS

- macOS Darwin 24.6.0, R 4.4.2

0 errors ✓ | 0 warnings ✓ | 3 notes x

Notes:
- Hidden .claude directory (excluded in .Rbuildignore)
- Unable to verify current time (system issue, not package-related)
- README.html at top level (excluded in .Rbuildignore)

## Github Actions

- macOS-latest (release)
- windows-latest (release)
- ubuntu-latest (release)
- ubuntu-latest (devel)
- ubuntu-latest (oldrel-1)

Expected: 0 errors | 0 warnings | 0 notes

## win-builder

Test initiated via `devtools::check_win_devel()` and `check_win_release()`.

Previous submission notes (NULL and lastMiKTeXException) are known R-Hub bugs:
- <https://github.com/r-hub/rhub/issues/560>
- <https://github.com/r-hub/rhub/issues/503>

# Downstream dependencies

## revdepcheck results

We checked 0 reverse dependencies, comparing R CMD check results across CRAN and dev versions of this package.

 * We saw 0 new problems
 * We failed to check 0 packages
