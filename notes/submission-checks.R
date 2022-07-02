# checks prior to CRAN submissions
# Checks come from either `devtools::release()` or https://github.com/ThinkR-open/prepare-for-cran
#
# nightly CRAN checks
# https://cloud.r-project.org/web/checks/check_results_usincometaxes.html

devtools::spell_check()
devtools::check_rhub()
devtools::check_win_devel()
