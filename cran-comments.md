Resolved errors that were caused by failed tests.

# R CMD check test environment

## Github Actions Checks

- macOS-latest (release)
- windows-latest (release)
- ubuntu-latest (release)
- ubuntu-latest (devel)
- ubuntu-latest (oldrel1)

0 errors | 0 warnings | 0 notes

## win-builder (devel) check results

```
Found the following files/directories:
  ''NULL''
* checking for detritus in the temp directory ... NOTE

Found the following files/directories:
  'lastMiKTeXException'
* DONE

Status: 2 NOTEs
```

Both notes are bugs in R-Hub.

First note is documented in <https://github.com/r-hub/rhub/issues/560>

Second note is documented in <https://github.com/r-hub/rhub/issues/503>

# Downstream dependencies

## revdepcheck results

We checked 0 reverse dependencies, comparing R CMD check results across CRAN and dev versions of this package.

 * We saw 0 new problems
 * We failed to check 0 packages
