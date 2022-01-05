# create functions by hand to test

library(tidyverse)
#library(RCurl)
library(glue)
#library(usincometaxes)

# testing -----------------------------------------

devtools::load_all()

input_data <- data.frame(
  id_number = as.integer(c(1, 2)),
  state = c('North Carolina', 'NY'),
  tax_year = c(2015, 2015),
  filing_status = c('single', 'married, jointly'),
  primary_wages = c(10000, 100000),
  primary_age = c(26, 36)
)

data.frame(
  taxsimid = as.integer(c(1, 2)),
  year = c(2015, 2015),
  mstat = c(1,2),
  page = c(26, 36),
  pwages = c(10000, 100000),
  idtl = 0
) %>%
  write_csv('test_df_short.csv')

full_tax_input <- data.frame(
  id_number = as.integer(1), tax_year = 2019, filing_status = 'married, jointly', state = 'AL', primary_age = 30, spouse_age = 30,
  num_dependents = 3, num_dependents_thirteen = 3, num_dependents_seventeen = 3, num_dependents_eitc = 3,
  primary_wages = 10000, spouse_wages = 10000, dividends = 10, interest = 10, short_term_capital_gains = 10,
  long_term_capital_gains = 10, other_property_income = 10, other_non_property_income = 10, pensions = 10,
  social_security = 10, unemployment = 10, other_transfer_income = 10, rent_paid = 10, property_taxes = 10,
  other_itemized_deductions = 10, child_care_expenses = 500, misc_deductions = 1000, scorp_income = 10,
  qualified_business_income = 10, specialized_service_trade = 10, spouse_qualified_business_income = 10,
  spouse_specialized_service_trade = 10
)

taxes <- taxsim_calculate_taxes(
  .data = full_tax_input,
  return_all_information = FALSE,
  upload_method = 'ftp'
)

