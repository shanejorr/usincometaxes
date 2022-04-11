#' Ensure input data set has required fields and datatypes are correct
#'
#' Check to ensure all the required column are present and data types are correct. This function binds all the checks through helper functions.
#'
#' @param .data A data frame containing the input parameters for the TAXSIM 32 program. The column names of the input parameters are below. The column can be in any order.
#' @param cols The column names, as a string, in the data set `.data`
#' @param state_column_name The column name of the state column.
#'
#' @return The function does not return a value. It either produces a stop message with the error or prints that all checks were successful.
#' @keywords internal
check_data <- function(.data, cols, state_column_name) {

  # make sure all the required column are present
  check_required_cols(cols)

  # ensure the id_number column is an integer and contains unique values
  check_id_number(.data[['id_number']])

  # some numeric columns must have all values greater than zero
  check_greater_zero(.data, cols)

  # make sure state names are either two letter abbreviations or full name of state
  check_state(.data, cols, state_column_name)

  # make sure that no single tax filers have spouse ages or income
  check_spouse(.data, cols)

  # tax year must be between the following two values
  # tax year is required, so we don't need to check whether it exists
  if (!all(.data$tax_year >= 1960 & .data$tax_year <= 2024)) {
    stop("`tax_year` must be a numeric value between 1960 and 2023", call. = FALSE)
  }

  message('All required columns are present and the data is in the proper format!')

  return(NULL)

}

#' Check state column
#'
#' State should be either a two letter abbreviation or full state name. Check to make sure this is true.
#'
#' @param .data A data frame containing the input parameters for the TAXSIM 32 program. The column names of the input parameters are below. The column can be in any order.
#' @param cols The column names, as a string, in the data set `.data`.
#' @param state_column_name The column name of the state column.
#'
#' @keywords internal
check_state <- function(.data, cols, state_column_name) {

  # state should either be the two letter abbreviation or full name
  if (state_column_name %in% cols) {

    proper_states <- c(datasets::state.abb, datasets::state.name, "DC", "District of Columbia")

    # make state list and entered data lower case to ensure a state is not recogizend simply because of capitalization
    proper_states <- tolower(proper_states)
    entered_states <- tolower(.data[[state_column_name]])

    if (!all(entered_states %in% proper_states)) {
      stop("One of your state names is unrecognizable. Names should either be the full name or two letter abbreviation.", call. = FALSE)
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

  required_columns <- names(taxsim_cols())[1:3]
  required_cols_present <- sort(intersect(required_columns, cols))
  all_required_present <- isTRUE(all.equal(sort(required_columns), sort(required_cols_present)))

  if (!all_required_present) {

    missing_column <- setdiff(required_columns, required_cols_present)
    stop(paste0("The required column `", missing_column, "`is not present in `.data`."), call. = FALSE)

  } else {

    return(NULL)

  }

}

#' Check numeric columns
#'
#' Checks that each column which should be numeric or integer is numeric or integer.
#'
#' @param .data A data frame containing the input parameters for the TAXSIM 32 program. The column names of the input parameters are below. The column can be in any order.
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
#' @param .data A data frame containing the input parameters for the TAXSIM 32 program. The column names of the input parameters are below. The column can be in any order.
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

#' Check that the `id_number` column is an integer and every value is unique.
#'
#' The `id_number` column requires a whole number and unique value. Check to make sure this is true.
#'
#' @param id_number_col Vector that id the `id_number` column. This will always be the column `id_number` in the input data frame.
#'
#' @keywords internal
check_id_number <- function(id_number_col) {

  # make sure id_number is an integer
  id_remainders <- c(id_number_col) %% 1

  all(id_remainders == 0)

  if (!all(id_remainders == 0)) {
    stop("id_number must be whole numbers.", call. = FALSE)
  }

  # make sure every value is unique
  number_unique_values <- length(unique(id_number_col))
  total_values <- length(id_number_col)

  if (number_unique_values != total_values) {
    stop("id_number must contain unique values.", call. = FALSE)
  } else {
    return(NULL)
  }

}
#' Check input parameters
#'
#' Check that the input parameters to `taxsim_calculate_taxes` are of the proper type
#'    The paramters to this function should be the same as those to `taxsim_calcualte_taxes`
#'
#' @keywords internal
check_parameters <- function(.data, all_columns) {

  if (!is.data.frame(.data)) stop("`.data` parameter must be a data frame.", call. = FALSE)

  if (!(all_columns %in% c(T, F))) stop('`all_columns` parameter must be either TRUE or FALSE.', call. = FALSE)

  NULL

}

#' Ensure single taxpayers do not have spouse ages or income
#'
#' @param .data A data frame containing the input parameters for the TAXSIM 32 program. The column names of the input parameters are below. The column can be in any order.
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
