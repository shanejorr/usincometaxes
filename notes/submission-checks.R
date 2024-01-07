# checks prior to CRAN submissions
# Checks come from either `devtools::release()` or https://github.com/ThinkR-open/prepare-for-cran
#
# nightly CRAN checks
# https://cloud.r-project.org/web/checks/check_results_usincometaxes.html

devtools::spell_check()
devtools::check_rhub()

devtools::check_win_devel()
devtools::check_win_release()
devtools::check_win_oldrelease()

# Check for CRAN specific requirements using rhub and save it in the results
# objects
results <- rhub::check_for_cran()

# Get the summary of your results
results$cran_summary()

devtools::release()
