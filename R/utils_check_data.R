#' Ensure input data set has required fields and data types are correct
#'
#' Check to ensure all the required column are present and data types are correct. This function binds all the checks through helper functions.
#'
#' @param .data A data frame containing the input parameters for the TAXSIM 35 program. The column names of the input parameters are below. The column can be in any order.
#' @param cols The column names, as a string, in the data set `.data`
#' @param state_column_name The column name of the state column.
#'
#' @return The function does not return a value. It either produces a stop message with the error or prints that all checks were successful.
#' @keywords internal
check_data <- function(.data, cols, state_column_name) {

  # make sure all the required column are present
  check_required_cols(cols)

  # ensure the taxsimid column is an integer and contains unique values
  check_taxsimid(.data[['taxsimid']])

  # some numeric columns must have all values greater than zero
  check_greater_zero(.data, cols)

  # make sure state names are either two letter abbreviations or full name of state
  # only if state si a character
  if (is.character(.data[['state']])) {
    check_state(.data, cols, state_column_name)
  }

  # make sure that no single tax filers have spouse ages or income
  check_spouse(.data, cols)

  # tax year must be between the following two values
  # tax year is required, so we don't need to check whether it exists
  if (!all(.data$year >= 1960 & .data$year <= 2024)) {
    stop("`year` must be a numeric value between 1960 and 2023", call. = FALSE)
  }

  return(NULL)

}

#' Check state column
#'
#' State should be either a two letter abbreviation or full state name. Check to make sure this is true.
#'
#' @param .data A data frame containing the input parameters for the TAXSIM 35 program. The column names of the input parameters are below. The column can be in any order.
#' @param cols The column names, as a string, in the data set `.data`.
#' @param state_column_name The column name of the state column.
#'
#' @keywords internal
check_state <- function(.data, cols, state_column_name) {

  # state should either be the two letter abbreviation or full name
  # if state is a character
  if (is.character(.data[[state_column_name]])) {

    proper_states <- c(datasets::state.abb, datasets::state.name, "DC", "District of Columbia", "No State")

    # make state list and entered data lower case to ensure a state is not recogizend simply because of capitalization
    proper_states <- tolower(proper_states)
    entered_states <- tolower(.data[[state_column_name]])

    if (!all(entered_states %in% proper_states)) {
      stop("One of your state names is unrecognizable. Names should either be the full name, two letter abbreviation, or SOI code.", call. = FALSE)
    }

  } else if (is.numeric(.data[[state_column_name]])) {

    # check input SOIs against crosswalk
    wrong_soi <- setdiff(.data[[state_column_name]], soi_and_states_crosswalk)

    # produce an error if there are any wrong SOIs
    if (length(wrong_soi) > 0) {
      soi_string <- paste0(wrong_soi, collapse = ", ")
      stop(paste0("The following state SOI code is nto a valid SOI: ", soi_string), call. = FALSE)
    }

  }

  return(NULL)

}

#' Ensure the required columns are present
#'
#' @param cols The column names, as a string, in the data set `.data`
#'
#' @keywords internal
check_required_cols <- function(cols) {

  required_columns <- taxsim_cols()[1:3]
  required_cols_present <- sort(intersect(required_columns, cols))
  all_required_present <- isTRUE(all.equal(sort(required_columns), sort(required_cols_present)))

  if (!all_required_present) {

    missing_column <- setdiff(required_columns, required_cols_present)
    stop(paste0("The required column `", missing_column, "`is not present in `.data`."), call. = FALSE)

  } else {

    return(NULL)

  }

}

#' Ensure values for filing status 'mstat' are proper.
#'
#' @param filing_status_vector Column, as a vector, containing filing status
#'
#' @keywords internal
check_filing_status <- function(filing_status_vector) {

  # mapping of strings to integers
  # if this changes, need to change test in test-calculate_taxes, where we copy and paste this
  filing_status_values <-   c(
    'single' = 1,
    'married, jointly' = 2,
    'married, separately' = 6,
    'dependent child' = 8,
    'head of household' = 1
  )

  # return an error if any of marital status are NA
  if (any(is.na(filing_status_vector))) stop("No mstat values can be NA.")

  if (is.numeric(filing_status_vector)) {

    # make sure that all values are one of the valid options
    diff_names <- setdiff(unique(filing_status_vector), filing_status_values)

    if (length(diff_names) > 0) {
      stop(paste('The following filing status (mstat) are in your data, but are not legitimate values: ', paste0(diff_names, collapse = " "), collapse = " "))
    }

  } else if (is.character(filing_status_vector)) {

    # make sure that all values are one of the valid options
    diff_names <- setdiff(unique(tolower(filing_status_vector)), names(filing_status_values))

    if (length(diff_names) > 0) {
      stop(paste('The following filing status (mstat) are in your data, but are not legitimate values: ', paste0(diff_names, collapse = " "), collapse = " "))
    }

    filing_status_vector <- tolower(filing_status_vector)

    filing_status_vector[filing_status_vector %in% c('single', 'head of household')] <- 1
    filing_status_vector[filing_status_vector == 'married, jointly'] <- 2
    filing_status_vector[filing_status_vector == 'married, separately'] <- 6
    filing_status_vector[filing_status_vector == 'dependent child'] <- 8
    filing_status_vector[filing_status_vector == 'head of household'] <- 1

  }

  return(filing_status_vector)

}

#' Check numeric columns
#'
#' Checks that each column which should be numeric or integer is numeric or integer.
#'
#' @param .data A data frame containing the input parameters for the TAXSIM 35 program. The column names of the input parameters are below. The column can be in any order.
#' @param cols The column names, as a string, in the data set `.data`.
#'
#' @keywords internal
check_numeric <- function(.data, cols) {

  # all numeric columns should be 'double' or integer
  numeric_cols <- names(taxsim_cols())[-non_numeric_col()]
  numeric_data_types <- c('numeric', 'integer')

  numeric_cols_in_data <- intersect(numeric_cols, cols)

  # create boolean vector of each column that should be numeric and whether it is numeric in the data set
  column_datatypes <- sapply(.data[numeric_cols_in_data], class)
  column_datatypes_are_numeric <- column_datatypes %in% numeric_data_types

  # if all the should-be numeric columns are not numeric, create stop message that contains the columns
  # not of the proper data type
  if (!all(column_datatypes_are_numeric)) {

    col_wrong_datatype <- paste0(names(column_datatypes[!column_datatypes_are_numeric]), collapse = '; ')
    stop(paste0("The following columns should be numeric: ", col_wrong_datatype), call. = FALSE)

  } else {

    # convert all numeric values to integer and return dataframe
    .data[numeric_cols_in_data] <- as.data.frame(lapply(.data[numeric_cols_in_data], as.integer))

    return(.data)

  }

}

#' Check that columns are greater than zero
#'
#' Some columns must have all values greater than zero. Check to make sure this is true.
#'
#' @param .data A data frame containing the input parameters for the TAXSIM 35 program. The column names of the input parameters are below. The column can be in any order.
#' @param cols The column names, as a string, in the data set `.data`.
#'
#' @keywords internal
check_greater_zero <- function(.data, cols) {

  cols_greater_zero <- names(taxsim_cols())[greater_zero_cols()]

  greater_zero_cols_in_data <- intersect(cols_greater_zero, cols)

  test_greater_zero <- function(test_data) all(test_data >= 0 | is.na(test_data))

  are_cols_greater_zero <- sapply(.data[greater_zero_cols_in_data], test_greater_zero)

  # if all values are not greater than zero, stop and provide message
  if (!all(are_cols_greater_zero)) {

    col_above_zero <- paste0(greater_zero_cols_in_data[!are_cols_greater_zero], collapse = '; ')
    stop(paste0(
        "The following columns have values less than zero: ",
        col_above_zero,
        "\nAll values in these columns should be greater than zero."
      ),
      call. = FALSE)

  } else {

    return(NULL)

  }

}

#' Check that the `taxsimid` column is an integer and every value is unique.
#'
#' The `taxsimid` column requires a whole number and unique value. Check to make sure this is true.
#'
#' @param taxsimid_col Vector that id the `taxsimid` column. This will always be the column `taxsimid` in the input data frame.
#'
#' @keywords internal
check_taxsimid <- function(taxsimid_col) {

  # make sure taxsimid is an integer
  id_remainders <- c(taxsimid_col) %% 1

  all(id_remainders == 0)

  if (!all(id_remainders == 0)) {
    stop("taxsimid must be whole numbers.", call. = FALSE)
  }

  # make sure every value is unique
  number_unique_values <- length(unique(taxsimid_col))
  total_values <- length(taxsimid_col)

  if (number_unique_values != total_values) {
    stop("taxsimid must contain unique values.", call. = FALSE)
  } else {
    return(NULL)
  }

}
#' Check input parameters
#'
#' Check that the input parameters to `taxsim_calculate_taxes` are of the proper type
#'    The parameters to this function should be the same as those to `taxsim_calcualte_taxes`
#'
#' @keywords internal
check_parameters <- function(.data, all_columns) {

  if (!is.data.frame(.data)) stop("`.data` parameter must be a data frame.", call. = FALSE)

  if (!(all_columns %in% c(T, F))) stop('`all_columns` parameter must be either TRUE or FALSE.', call. = FALSE)

  NULL

}

#' Ensure single taxpayers do not have spouse ages or income
#'
#' @param .data A data frame containing the input parameters for the TAXSIM 35 program. The column names of the input parameters are below. The column can be in any order.
#' @param cols The column names, as a string, in the data set `.data`.
#'
#' @keywords internal
check_spouse <- function(.data, cols) {

  if ('sage' %in% cols) {

    if (!('page' %in% cols)) stop("You have `sage` column, but not `page`. You need to add `page`.", call. = FALSE)

    if (any(.data[['mstat']] == 1 & .data[['sage']] > 0)) {

      stop("You have a 'single' filer with a `sage` greater than 0. All single filers must have spouse ages of 0", call. = FALSE)

    }
  }

  if ('swages' %in% cols) {

    if (!('pwages' %in% cols)) stop("You have `swages` column, but not `pwages`. You need to add `pwages`.", call. = FALSE)

  }

  NULL

}
