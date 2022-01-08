#############################################################################
#
# This file creates a mock data set that can be used with this package
#
#############################################################################

# add to checks: single returns cannot have age or income

# function to create log-normal distributions
log_norm <- function(n, log_mean, log_sd) {

  round(rlnorm(n = n, meanlog = log(log_mean), sdlog = log(log_sd)), 2)

}

n <- 2000

years <- c(2000, 2020)

filing_statuses <- c('single', 'married, jointly')

file_status <- sample(filing_statuses, size = n, replace = TRUE)

p_age = rnorm(n, mean = , 90)

p_age <- rpois(n = n, lambda = 37)

p_age_young <- sample(25:35, size = n, replace = TRUE)

p_age <- ifelse(p_age < 25, p_age_young, p_age)

s_age <- ifelse(file_status == 'single', 0, round(p_age + rnorm(p_age, 0, 3), 0))

n_kids_sample <- sample(0:5, size = n, replace = TRUE, prob = c(.15, .3, .25, .15, .1, .05))

n_kids <- ifelse(p_age <= 40, n_kids_sample, 0)

p_wages <- log_norm(n, 30000, 2.5)

s_wages <- log_norm(n, 30000, 2.5)

s_wages <- ifelse(file_status == 'single', 0, s_wages)

taxpayer_finances <- data.frame(
  id_number = seq(1, n),
  tax_year = rep(years, each = n / length(years)),
  filing_status = file_status,
  state = 'NC',
  primary_age = p_age,
  spouse_age = s_age,
  num_dependents = n_kids,
  num_dependents_thirteen = n_kids,
  num_dependents_seventeen = n_kids,
  num_dependents_eitc = n_kids,
  primary_wages = p_wages,
  spouse_wages = s_wages,
  dividends = log_norm(n, 2500, 2),
  interest = log_norm(n, 2500, 2),
  short_term_capital_gains = log_norm(n, 1000, 2),
  long_term_capital_gains = log_norm(n, 2000, 2)
)

usethis::use_data(taxpayer_finances, internal = FALSE, overwrite = TRUE)
