#' Get state SOI from state name.
#'
#' Converts state names or state abbreviations to numeric SOI codes, which are required for TAXSIM.
#'
#' @param state_column Vectors containing the states to calculate taxes for. Generally, this is the
#'     state column from the data set that will be sent to TAXSIM.
#'
#' @return Named integer vector with each number between 1 and 51 representing the state's SOI.
#'     Names are the state's two letter abbreviation.
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
#' @param from_taxsim The data set received from TAXSIM.
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
    'taxsimid', 'year', 'mstat', # required
    'state', 'page', 'sage',
    'depx', 'age1', 'age2', 'age3', # dependents
    'pwages', 'swages', 'dividends', 'intrec', 'stcg', 'ltcg', 'otherprop', 'nonprop',
    'pensions', 'gssi', 'ui', 'transfers', 'rentpaid', 'proptax', 'otheritem',
    'childcare', 'mortgage', 'scorp', 'pbusinc', 'pprofinc', 'sbusinc', 'sprofinc',
    'mtr', 'idtl'
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
    'v10' = 'federal_agi', 'v11' = 'ui_agi', 'v12' = 'soc_sec_agi', 'v13' = 'zero_bracket_amount',
    'v14' = 'personal_exemptions', 'v15' = 'exemption_phaseout', 'v16' = 'deduction_phaseout',
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
  c(4)
}

#' @keywords internal
greater_zero_cols <- function() {

  # columns that must have all values greater than zero
  # integer numbers represent the number in taxsim_cols
  c(1, 2, 3, 5, 6, 7, 8, 9, 10, 23, 24)

}

#' Ensure values for filing status 'mstat' are proper.
#'
#' @param filing_status_colname Column, as a vector, containing filing status
#'
#' @keywords internal
check_filing_status <- function(filing_status_colname) {

  # mapping of strings to integers
  filing_status_values <- c(
    'single' = '1',
    'married, jointly' = '2',
    'married, separately' = '6',
    'dependent child' = '8',
    'head of household' = '1'
  )

  # make sure that all values are one of the valid options
  diff_names <- setdiff(unique(filing_status_colname), filing_status_mappings)

  if (length(diff_names) > 0) {
    stop(paste('The following filing status (mstat) are in your data, but are not legitimate values: ', paste0(diff_names, collapse = " "), collapse = " "))
  }

  filing_status_colname <- as.integer(filing_status_colname)

  return(filing_status_colname)

}

#' Recode marginal tax rates.
#'
#' Marginal tax rates are specified with the \code{marginal_tax_rates} parameter. The possible values are
#' descriptive strings. But,TAXSIM requires integers. Convert descriptice strings to integers.
#'
#' @param marginal_tax_rate String representing the \code{marginal_tax_rate} parameter in \code{taxsim_calculate_taxes}
#'
#' @keywords internal
convert_marginal_tax_rates <- function(marginal_tax_rate_specification) {

  possible_values <- c('Wages', 'Long Term Capital Gains', 'Primary Wage Earner', 'Secondary Wage Earner')

  if (!marginal_tax_rate_specification %in% possible_values) {
    stop(paste0("`marginal_tax_rate` must be one of: ", "'", paste0(possible_values, collapse = "', '"), "'"))
  }

  switch(marginal_tax_rate_specification,
         'Wages' = 11,
         'Long Term Capital Gains' = 70,
         'Primary Wage Earner' = 85,
         'Secondary Wage Earner' = 86
         )

}
