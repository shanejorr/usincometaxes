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
