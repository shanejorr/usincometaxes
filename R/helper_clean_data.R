#' Get state SOI from name.
#'
#' Return the integer number state SOI of a state based on either its two letter abbreviation or
#'     full name.
#'
#' @param .data A data frame containing the input parameters for the TAXSIM 32 program.
#'     The column names of the input parameters are below. The column can be in any order.
#'
#' @return Named integer vector with each number between 1 and 51 representing the state's SOI.
#'     Names are the state's two letter abbreviation.
get_state_soi <- function(state_column) {

  # the SOI crosswalk has two letter abbreviation
  # if full names were entered, we need to change them to the full-state spellings

  # add DC to list of states, since there is an SOI code for it
  # lwoer-case everything to make it easier to match with the user-entered states
  state_abb <- tolower(c(state.abb, "DC", "No State"))
  state_name <- tolower(c(state.name, "District of Columbia", "No State"))

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

#' Recode filing status.
#'
#' Check to make sure the strings in `filing_status` are correct and recode from a string to an integer.
#'
#' @param filing_status_colname Column, as a vector, containing filing status
#'
#' @return Vector with integers reflecting numeric value of filing status.
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
