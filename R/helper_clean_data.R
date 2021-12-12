#' Get state SOI from name.
#'
#' Return the integer number state SOI of a state based on either its two letter abbreviation or
#'     full name.
#'
#' @param state_column Vectors containing the states to calculate taxes for. Generally, this is the
#'     state column from the data set that will be sent to TAXSIM.
#'
#' @return Named integer vector with each number between 1 and 51 representing the state's SOI.
#'     Names are the state's two letter abbreviation.
#'
#' @keywords internal
get_state_soi <- function(state_column) {

  # the SOI crosswalk has two letter abbreviation
  # if full names were entered, we need to change them to the full-state spellings

  # add DC to list of states, since there is an SOI code for it
  # lwoer-case everything to make it easier to match with the user-entered states
  state_abb <- tolower(c(datasets::state.abb, "DC", "No State"))
  state_name <- tolower(c(datasets::state.name, "District of Columbia", "No State"))

  states_listed <- tolower(state_column)

  # states in the original input dataframe, as two letter abbreviation and lower case
  input_state_abb <- ifelse(nchar(states_listed) > 2, state_abb[match(states_listed,state_name)], states_listed)

  # make state abbreviations upper case to match cross walk
  input_state_abb <- toupper(input_state_abb)

  # find SOI from two-letter abbreviation, using cross-walk
  state_soi <- soi_and_states_crosswalk[input_state_abb]

  return(state_soi)

}

#' Clean final TAXSIM data set.
#'
#' Clean the data set received from TAXSIM by renaming columns and removing columns not needed in
#'     the final output.
#'
#' @param from_taxsim The data set received from TAXSIM
#'
#' @return Data frame containing the row's `id_number` and tax calculations. This data frame can be
#'     merged with the original input data frame by `id_number`.
#'
#' @keywords internal
clean_from_taxsim <- function(from_taxsim) {

  # change column names from the TAXSIM names to more descriptive names
  for (col in colnames(from_taxsim)) {
    new_colname_output <- from_taxsim_cols()[[col]]
    names(from_taxsim)[names(from_taxsim) == col] <- new_colname_output
  }

  # year and state will be in the original dataset, so they are not needed
  # find what column number they are and remove that column number
  cols_to_remove <- which(colnames(from_taxsim) %in% c('year', 'state'))

  from_taxsim <- from_taxsim[-cols_to_remove]

  return(from_taxsim)

}

#' Map input column names.
#'
#' Map the input column names required in this package to the input column names required by TAXSIM.
#'
#' @keywords internal
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
#'
#' @keywords internal
from_taxsim_cols <- function() {

  # named vector to rename the columns of the data set received from TAXSIM
  col_names_output <- c(
    # primary output
    'taxsimid' = 'id_number', 'year' = 'year', 'state' = 'state',  'fiitax' = 'federal_taxes',
    'siitax' = 'state_taxes',  'fica' = 'fica_taxes',  'frate' = 'federal_marginal_rate',
    'srate' = 'state_marginal_rate',  'ficar' = 'fica_rate',

    # extended output
    'v10' = 'federal_agi', 'v11' = 'ui_age', 'v12' = 'soc_sec_agi', 'v13' = 'zero_bracket_amount',
    'v14' = 'personal_exemptions', 'v15' = 'exemption_phaseout', 'v16' = 'deducation_phaseout',
    'v17' = 'itemized_deductions', 'v18' = 'federal_taxable_income', 'v19' = 'tax_on_taxable_income',
    'v20' = 'exemption_surtax', 'v21' = 'general_tax_credit', 'v22' = 'child_tax_credit_adjusted',
    'v23' = 'child_tax_credit_refundable', 'v24' = 'child_care_credit', 'v25' = 'eitc',
    'v26' = 'amt_income', 'v27' = 'amt_liability', 'v28' = 'fed_income_tax_before_credit', 'v29' = 'fica',

    # columns are zero if no state is specified
    'v30' = 'state_household_income', 'v31' = 'state_rent_expense',
    'v32' = 'state_agi', 'v33' = 'state_exemption_amount', 'v34' = 'state_std_deduction_amount',
    'v35' = 'state_itemized_deducation', 'v36' = 'state_taxable_income', 'v37' = 'state_property_tax_credit',
    'v38' = 'state_child_care_credit', 'v39' = 'state_eitc', 'v40' = 'state_total_credits',
    'v41' = 'state_bracket_rate', 'v42' = 'self_emp_income', 'v43' = 'medicare_tax_unearned_income',
    'v44' = 'medicare_tax_earned_income', 'v45' = 'cares_recovery_rebate'
  )

  return(col_names_output)

}

#' @keywords internal
non_numeric_col <- function() {

  # filing status and state are the only non-numeric column
  # integer numbers represent the number in taxsim_cols
  c(3, 4)
}

#' @keywords internal
greater_zero_cols <- function() {

  # columns that must have all values greater than zero
  # integer numbers represent the number in taxsim_cols
  c(1, 2, 5, 6, 7, 8, 9, 10, 23, 24)

}

#' Recode filing status.
#'
#' Check to make sure the strings in `filing_status` are correct and recode from a string to an integer.
#'
#' @param filing_status_colname Column, as a vector, containing filing status
#'
#' @return Vector with integers reflecting numeric value of filing status.
#'
#' @keywords internal
recode_filing_status <- function(filing_status_colname) {

  # mapping of strings to integers
  filing_status_mappings <- c(
    'single' = '1',
    'married, jointly' = '2',
    'married, separately' = '6',
    'dependent child' = '8',
    'head of household' = '1'
  )

  # make sure that all values are one of the valid options
  diff_names <- setdiff(unique(filing_status_colname), names(filing_status_mappings))

  if (length(diff_names) > 0) {
    stop(paste0(
      'Invalid filing status. Acceptable values are:  ',
      paste0(names(filing_status_mappings), collapse = "; ")
    ))
  }

  # change strings to integers
  for (i in seq_along(filing_status_mappings)) {

    string_filing_status <- names(filing_status_mappings)[i]
    filing_status_colname[filing_status_colname == string_filing_status] <- as.integer(filing_status_mappings[i])

  }

  filing_status_colname <- as.integer(filing_status_colname)

  return(filing_status_colname)

}
