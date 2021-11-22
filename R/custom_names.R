#' Map input column names.
#'
#' Map the input column names required in this package to the input column names required by TAXSIM.
taxsim_cols <- function() {

  c(
    'id_number' = 'taxsimid', 'tax_year' = 'year', 'filing_status' = 'mstat', # required
    'state' = 'state', 'primary_age' = 'page', 'spouse_age' = 'sage',
    'num_dependents' = 'depx', 'num_dependents_thirteen' = 'dep13',
    'num_dependents_seventeen' = 'dep17', 'num_dependents_eitc' = 'dep18',
    'primary_wages' = 'pwages', 'spouse_wages' = 'swages', 'dividends' = 'dividends', 'interest' = 'intrec',
    'short_term_capital_gains' = 'stcg', 'long_term_capital_gains' = 'ltcg',
    'other_property_income' = 'otherprop', 'other_non_property_income' = 'nonprop',
    'pensions' = 'pensions', 'social_security' = 'gssi', 'unemployment' = 'ui',
    'other_transfer_income' = 'transfers', 'rent_paid' = 'rentpaid',
    'property_taxes' = 'proptax', 'other_itemized_deductions' = 'otheritem',
    'child_care_expenses' = 'childcare', 'misc_deductions' = 'mortgage',
    'scorp_income' = 'scorp', 'qualified_business_income' = 'pbusinc', 'specialized_service_trade' = 'pprofinc',
    'spouse_qualified_business_income' = 'sbusinc', 'spouse_specialized_service_trade' = 'sprofinc'
    )

}

#' Map output column names.
#'
#' Map the output column names required in this package to the input column names required by TAXSIM.
from_taxsim_cols <- function() {

  # named vector to rename the columns of the data set received from TAXSIM
  col_names_output <- c(
    'taxsimid' = 'id_number', 'year' = 'year', 'state' = 'state',  'fiitax' = 'federal_taxes',
    'siitax' = 'state_taxes',  'fica' = 'fica_taxes',  'frate' = 'federal_marginal_rate',
    'srate' = 'state_marginal_rate',  'ficar' = 'fica_rate'
  )

}

non_numeric_col <- function() {

  # filing status and state are the only non-numeric column
  # integer numbers represent the number in taxsim_cols
  c(3, 4)
}

greater_zero_cols <- function() {

  # columns that must have all values greater than zero
  # integer numbers represent the number in taxsim_cols
  c(1, 2, 5, 6, 7, 8, 9, 10, 23, 24)

}
