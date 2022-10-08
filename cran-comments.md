# Submission

Package is failing [CRAN Checks](https://cran-archive.r-project.org/web/checks/2022/2022-09-12_check_results_usincometaxes.html) due to a change in the TAXSIM API. This submission ensures all checks are passed. Check NEWS.md for specifics.

# R CMD check test environment

## Github Actions Checks

- macOS-latest (release)
- windows-latest (release)
- ubuntu-latest (release)
- ubuntu-latest (devel)
- ubuntu-latest (oldrel1)

0 errors | 0 warnings | 0 notes

## win-builder (devel) check results

0 errors | 0 warnings | 1 notes

* checking for detritus in the temp directory ... NOTE
Found the following files/directories:
  'lastMiKTeXException'

As noted in [R-hub issue #503](https://github.com/r-hub/rhub/issues/503), this could be due to a bug/crash in MiKTeX and can likely be ignored.

# Downstream dependencies

There are no downstream dependencies, as checked by `revdepcheck::revdep_check()`.
