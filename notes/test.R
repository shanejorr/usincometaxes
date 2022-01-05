# create functions by hand to test

library(tidyverse)
library(vroom)
#library(RCurl)
library(glue)
#library(usincometaxes)

# testing -----------------------------------------

devtools::load_all()

full_test_input <- data.frame(
  id_number = 1, tax_year = 2019, filing_status = 'married, jointly', state = 'AL', primary_age = 30, spouse_age = 30,
  num_dependents = 3, num_dependents_thirteen = 3, num_dependents_seventeen = 3, num_dependents_eitc = 3,
  primary_wages = 10000, spouse_wages = 10000, dividends = 10, interest = 10, short_term_capital_gains = 10,
  long_term_capital_gains = 10, other_property_income = 10, other_non_property_income = 10, pensions = 10,
  social_security = 10, unemployment = 10, other_transfer_income = 10, rent_paid = 10, property_taxes = 10,
  other_itemized_deductions = 10, child_care_expenses = 500, misc_deductions = 1000, scorp_income = 10,
  qualified_business_income = 10, specialized_service_trade = 10, spouse_qualified_business_income = 10,
  spouse_specialized_service_trade = 10
)

full_test_output_hand <- tibble::tibble(
  id_number = 1, federal_taxes = -9187.58, state_taxes = 326.05, fica_taxes = 3065.65, federal_marginal_rate = -15,
  state_marginal_rate = 5.04, fica_rate = 15.3, federal_agi = 20127.18, ui_agi = 10, soc_sec_agi = 0,
  zero_bracket_amount = 24400, personal_exemptions = 0, exemption_phaseout = 0, deduction_phaseout = 0,
  itemized_deductions = 0, federal_taxable_income = 0, tax_on_taxable_income = 0, exemption_surtax = 0,
  general_tax_credit =0, child_tax_credit_adjusted = 0, child_tax_credit_refundable = 2630.58, child_care_credit = 0,
  eitc = 6557, amt_income = 20127.18, amt_liability = 0, fed_income_tax_before_credit = 0, fica = 3065.65,
  state_household_income = 20130.01, state_rent_expense = 10, state_agi = 20120.01, state_exemption_amount = 4499.1,
  state_std_deduction_amount = 7500, state_itemized_deducation = 2555.65, state_taxable_income = 8120.91,
  state_property_tax_credit = 0, state_child_care_credit = 0, state_eitc = 0, state_total_credits = 0,
  state_bracket_rate = 5, self_emp_income = 20036.94, medicare_tax_unearned_income = 0,
  medicare_tax_earned_income = 0, cares_recovery_rebate = 0
)

full_test_output_taxsim <- usincometaxes::taxsim_calculate_taxes(
  .data = full_test_input,
  return_all_information = TRUE,
  upload_method = 'ssh'
)

testthat::expect_equal(full_test_output_taxsim, full_test_output_hand)

