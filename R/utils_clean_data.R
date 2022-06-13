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
#' @return Data frame containing the row's `taxsimid` and tax calculations. This data frame can be
#'     merged with the original input data frame by `taxsimid`.
#'
#' @keywords internal
clean_from_taxsim <- function(from_taxsim) {

  # change column names from the TAXSIM names to more descriptive names
  for (col in colnames(from_taxsim)) {
    new_colname_output <- from_taxsim_cols()[[col]]
    names(from_taxsim)[names(from_taxsim) == col] <- new_colname_output
  }

  # remove state and year because they are also in the input data
  # since they are in the input data, when you join input and output by taxsimid, they will appear twice
  from_taxsim[c('state', 'year')] <- NULL

  return(from_taxsim)

}

#' Map input column names.
#'
#' Map the input column names required in this package to the input column names required by TAXSIM.
#'
#' @keywords internal
taxsim_cols <- function() {

  # NOTE: You need to change replace_missing() and check_required_cols() if you change this function.

  c(
    'taxsimid', 'year', 'mstat', # required
    'state', 'page', 'sage',
    'depx', 'age1', 'age2', 'age3', # dependents
    'pwages', 'swages', 'psemp', 'ssemp', 'dividends', 'intrec', 'stcg', 'ltcg', 'otherprop', 'nonprop',
    'pensions', 'gssi', 'pui', 'sui', 'transfers', 'rentpaid', 'proptax', 'otheritem',
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
    'taxsimid' = 'taxsimid', 'year' = 'year', 'state' = 'state',  'fiitax' = 'fiitax',
    'siitax' = 'siitax',  'fica' = 'fica',  'frate' = 'frate',
    'srate' = 'srate',  'ficar' = 'ficar', 'tfica' = 'tfica',

    # extended output
    'v10' = 'v10_federal_agi', 'v11' = 'v11_ui_agi', 'v12' = 'v12_soc_sec_agi', 'v13' = 'v13_zero_bracket_amount',
    'v14' = 'v14_personal_exemptions', 'v15' = 'v15_exemption_phaseout', 'v16' = 'v16_deduction_phaseout',
    'v17' = 'v17_itemized_deductions', 'v18' = 'v18_federal_taxable_income', 'v19' = 'v19_tax_on_taxable_income',
    'v20' = 'v20_exemption_surtax', 'v21' = 'v21_general_tax_credit', 'v22' = 'v22_child_tax_credit_adjusted',
    'v23' = 'v23_child_tax_credit_refundable', 'v24' = 'v24_child_care_credit', 'v25' = 'v25_eitc',
    'v26' = 'v26_amt_income', 'v27' = 'v27_amt_liability', 'v28' = 'v28_fed_income_tax_before_credit', 'v29' = 'v29_fica',

    # columns are zero if no state is specified
    'v30' = 'v30_state_household_income', 'v31' = 'v31_state_rent_expense',
    'v32' = 'v32_state_agi', 'v33' = 'v33_state_exemption_amount', 'v34' = 'v34_state_std_deduction_amount',
    'v35' = 'v35_state_itemized_deduction', 'v36' = 'v36_state_taxable_income', 'v37' = 'v37_state_property_tax_credit',
    'v38' = 'v38_state_child_care_credit', 'v39' = 'v39_state_eitc', 'v40' = 'v40_state_total_credits',
    'v41' = 'v41_state_bracket_rate',

    # extra federal columns
    'v42' = 'v42_self_emp_income', 'v43' = 'v43_medicare_tax_unearned_income',
    'v44' = 'v44_medicare_tax_earned_income', 'v45' = 'v45_cares_recovery_rebate'
  )

  return(col_names_output)

}

#' @keywords internal
non_numeric_col <- function() {

  # state is the only non-numeric column
  # integer numbers represent the number in taxsim_cols
  c(3, 4)
}

#' @keywords internal
greater_zero_cols <- function() {

  # columns that must have all values greater than zero
  # integer numbers represent the number in taxsim_cols
  c(1, 2, 5, 6, 7, 8, 9, 10, 23, 24)

}

#' Recode marginal tax rates.
#'
#' Marginal tax rates are specified with the \code{marginal_tax_rates} parameter. The possible values are
#' descriptive strings. But,TAXSIM requires integers. Convert descriptive strings to integers.
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

#' Convert NA values to either 0 or the proper state value
#'
#' @keywords internal
convert_na <- function(.data, cols_to_convert) {

  cols_to_convert <- intersect(colnames(.data), cols_to_convert)

  if (is.character(.data[['state']])) {
    .data[['state']][is.na(.data[['state']])] <- 'No State'
  } else if (is.numeric(.data[['state']])) {
    .data[['state']][is.na(.data[['state']])] <-'No State'
  }

  .data[cols_to_convert][is.na(.data[cols_to_convert])] <- 0

  return(.data)

}
