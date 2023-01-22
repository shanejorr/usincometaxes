# Submission

Removed the interface parameter from the `taxsim_calculate_taxes()` function. Previously, users could 
calculate taxes by either sending their data to the TAXSIM server or conduct the calculations locally 
with a WebAssembly version of the program that runs on the TAXSIM server. The program on the TAXSIM 
server changes frequently, causing errors to this package and requiring frequent updates. The WebAssembly
version is stable, which will lead to fewer errors and less maintenance.

Check NEWS.md for specifics.

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

## revdepcheck results

We checked 0 reverse dependencies, comparing R CMD check results across CRAN and dev versions of this package.

 * We saw 0 new problems
 * We failed to check 0 packages
