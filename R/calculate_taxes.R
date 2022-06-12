#' Convert a data frame to the TAXSIM 35 output.
#'
#' This function takes a data set that is in the format required for \code{\link{taxsim_calculate_taxes}},
#' checks it to make sure it is in the proper format for TAXSIM 35, and then cleans so it can be sent to TAXSIM 35.
#' This function is useful for troubleshooting. It is not needed to calculate taxes. The function is useful
#' if you continue receiving unreasonable errors from \code{\link{taxsim_calculate_taxes}}. In such as case,
#' you can run this function on your data set. You should then save the resulting
#' data frame as a csv file. Then, upload the file to \href{http://taxsim.nber.org/taxsim35/}{TAXSIM 35}.
#' If there are no errors with TAXSIM 35 then the issue lies in \code{\link{taxsim_calculate_taxes}}.
#'
#' \code{\link{create_dataset_for_taxsim}} takes the same columns as column names as \href{http://taxsim.nber.org/taxsim35/}{TAXSIM 35}.
#'
#' @param .data Data frame containing the information that will be used to calculate taxes.
#'    This data set will be sent to TAXSIM. Data frame must have specified column names and data types.
#'
#' @return A data frame that that can be manually uploaded to \href{http://taxsim.nber.org/taxsim35/}{TAXSIM 35}.
#'
#' @examples
#'
#' family_income <- data.frame(
#'     taxsimid = c(1, 2),
#'     state = c('North Carolina', 'NY'),
#'     year = c(2015, 2015),
#'     mstat = c('single', 'married, jointly'),
#'     pwages = c(10000, 100000),
#'     page = c(26, 36)
#' )
#'
#' family_taxes <- create_dataset_for_taxsim(family_income)
#'
#' # You can then write out the data frame as a csv file for uploading to TAXSIM 35
#'
#' @export
create_dataset_for_taxsim <- function(.data) {

  state_colname <- 'state'
  filing_status_colname <- 'mstat'

  cols <- colnames(.data)

  # only keep TAXSIM columns
  cols_in_taxsim_and_df <- intersect(cols, taxsim_cols())
  .data <- .data[cols_in_taxsim_and_df]

  # return an error is any required columns have missing values (except for state)
  for (col in c('taxsim', 'year', 'mstat')) {
    if (any(is.na(.data[[col]]))) stop(paste0("No", col, "values can be NA."))
  }

  # convert all NA values to 0 for non-required items
  cols_to_convert <- taxsim_cols()[5:length(taxsim_cols())]
  .data <- convert_na(.data, cols_to_convert)

  # make sure all the data is of the proper type
  # function will either stop the running of a function with text of the error
  # or print that everything is OK
  check_data(.data, cols, state_colname)

  # make sure all column that should be numeric are in fact numeric
  # if so, also convert them to integer
  .data <- check_numeric(.data, cols)

  # if state is character, convert to SOI codes
  # if state is numeric, ensure all values are SOI codes
  if (state_colname %in% cols) {

    if (is.character(.data[[state_colname]])) {
      .data[[state_colname]] <- get_state_soi(.data[[state_colname]])

    } else if (is.numeric(.data[[state_colname]])) {

      # identify SOI codes in the data that are not actual SOI codes
      not_soi_codes <- setdiff(unique(.data[[state_colname]]), soi_and_states_crosswalk)

      # stop function if we find SOI codes in the data that are not actual SOI codes
      if (length(not_soi_codes) > 0) {
        stop(paste('The following SOI codes are in your data, but are not actual SOI codes: ', paste0(not_soi_codes, collapse = " "), collapse = " "))
      }
    }

    # convert missing state values to 0
    .data[[state_colname]][is.na(.data[[state_colname]])] <- 0

  }

  # make sure all filing_status values are proper
  # and if character descriptions are used for filing status, convert to number
  if (filing_status_colname %in% cols) {
    .data[[filing_status_colname]] <- check_filing_status(.data[[filing_status_colname]])
  }

  return(.data)

}

#' @title
#' Calculate state and federal taxes using TASXSIM 35.
#'
#' @description
#' This function calculates state and federal income taxes using the TAXSIM 35 tax simulator.
#' See \url{http://taxsim.nber.org/taxsim35/} for more information on TAXSIM 35.
#'
#' @param .data Data frame containing the information that will be used to calculate taxes.
#'    This data set will be sent to TAXSIM. Data frame must have specified column names and data types.
#' @param marginal_tax_rates Variable to use when calculating marginal tax rates. One of 'Wages', 'Long Term Capital Gains',
#'     'Primary Wage Earner', or 'Secondary Wage Earner'. Default is 'Wages'.
#' @param return_all_information Boolean (TRUE or FALSE). Whether to return all information from TAXSIM (TRUE),
#'     or only key information (FALSE). Returning all information returns 42 columns of output, while only
#'     returning key information returns 9 columns. It is faster to download results with only key information.
#' @param interface String indicating which NBER TAXSIM interface to use. Should
#'   be one of: "ssh," "http," or "wasm."
#'
#'   - "ssh" uses SSH to connect to taxsimssh.nber.org. Your system must already
#'   have SSH installed.
#'   - "http" uses CURL to connect to
#'   https://taxsim.nber.org/uptest/webfile.cgi. Approximate max file size: 1000
#'   rows.
#'   - "wasm" uses a compiled WebAssembly version of the TAXSIM app. Details
#'   about generating the wasm file can be found here:
#'   https://github.com/tmm1/taxsim.js
#'
#' @section Formatting your data:
#'
#' In the input data set, \code{.data}, each column is a tax characteristic (year, filing status, income, etc.)
#' and each row is a tax filing unit.
#'
#' Columns should take the same names, and fulfill the same requirements, as those needed for \href{http://taxsim.nber.org/taxsim35/}{TAXSIM 35}.
#' Potential columns, with there names and descriptions, can be found at: \href{http://taxsim.nber.org/taxsim35/}{http://taxsim.nber.org/taxsim35/}.
#'
#' The following columns are required: \code{taxsimid}, \code{year}, \code{mstat}, and \code{state}.
#'
#' There are two points where \code{\link{taxsim_calculate_taxes}} departs from \href{http://taxsim.nber.org/taxsim35/}{TAXSIM 35}.
#'
#' 1. For filing status, \code{mstat}, users can either enter the number allowed by \href{http://taxsim.nber.org/taxsim35/}{TAXSIM 35}
#' or one of the following descriptions:
#'
#' - "single"
#' - "married, jointly"
#' - "married, separately"
#' - "dependent child"
#' - "head of household"
#'
#' 2. For \code{state}, users can either enter the SOI code, as required by \href{http://taxsim.nber.org/taxsim35/}{TAXSIM 35},
#' the two-letter state abbreviation, or the full name of the state.
#'
#' It is OK if the input data set, \code{.data}, contains columns in addition to the ones that are used by \href{http://taxsim.nber.org/taxsim35/}{TAXSIM 35}.
#'
#' @return
#'
#' The output data set contains all the information returned by \href{http://taxsim.nber.org/taxsim35/}{TAXSIM 35},
#' using the same column names. Descriptions of these columns can be found at the bottom of the page
#' containing \href{http://taxsim.nber.org/taxsim35/}{TAXSIM 35's documentation}.
#'
#' @examples
#'
#' \dontrun{
#' family_income <- data.frame(
#'     taxsimid = c(1, 2),
#'     state = c('North Carolina', 'NY'),
#'     year = c(2015, 2015),
#'     mstat = c('single', 'married, jointly'),
#'     pwages = c(10000, 100000),
#'     page = c(26, 36)
#' )
#'
#'
#' family_taxes <- taxsim_calculate_taxes(family_income)
#'
#' merge(family_income, family_taxes, by = 'taxsimid')
#' }
#'
#' @section Giving credit where it is due:
#'
#' The NBER's \href{http://taxsim.nber.org/taxsim35/}{TAXSIM 35} tax simulator does all tax
#' calculations. This package simply lets users interact with the tax simulator through R. Therefore,
#' users should cite the TASXSIM 35 tax simulator when they use this package in their work:
#'
#' Feenberg, Daniel Richard, and Elizabeth Coutts, An Introduction to the TAXSIM Model,
#' Journal of Policy Analysis and Management vol 12 no 1, Winter 1993, pages 189-194.
#'
#' @export
taxsim_calculate_taxes <- function(.data, marginal_tax_rates = 'Wages', return_all_information = FALSE, interface = "ssh") {

  # save input ID numbers as object, so we can make sure the output ID numbers are the same
  input_s <- .data$taxsimid

  # create data set to send to taxsim
  .data <- create_dataset_for_taxsim(.data)

  # check parameter options
  # must change this function if parameters are added
  check_parameters(.data, return_all_information)

  # add 2 to column if we need all columns, otherwise add 0 for only the default columns
  idtl <- if (return_all_information) 2 else 0

  .data[['idtl']] <- idtl

  # add marginal tax rate calculation
  .data[['mtr']] <- convert_marginal_tax_rates(marginal_tax_rates)

  # send data set to taxsim server

  # save csv file of data set to a temp folder
  to_taxsim_tmp_filename <- tempfile(pattern = 'upload_', fileext = ".csv")
  from_taxsim_tmp_filename <- tempfile(pattern = 'download_', fileext = ".csv")

  stop_error_message <- paste0(
    "There was a problem in trying to retrieve your data.\n",
    "Either we could not connect to the TAXSIM server or your data is not in the proper format.\n",
    "You can try manually uploading the data to TAXSIM as an avenue of troubleshooting.\n",
    "See the following address for more information: https://www.shaneorr.io/r/usincometaxes/articles/send-data-to-taxsim.html"
  )

  if (interface == "ssh") {

    vroom::vroom_write(.data, to_taxsim_tmp_filename, delim = ",", progress = FALSE)

    # try uploading and downloading via ssh
    std_error_filename <- tempfile(pattern = 'std_error_', fileext = ".txt")
    known_hosts_file <- paste0(tempdir(), '/known_hosts')

    from_taxsim <- tryCatch(
      error = function(cnd) stop(stop_error_message, call. = FALSE),
      import_data_ssh(to_taxsim_tmp_filename, from_taxsim_tmp_filename, std_error_filename, known_hosts_file, idtl)
    )

  } else if (interface == "http") {

    # convert input data to string
    data_string <- vroom::vroom_format(.data, delim = ",")

    # remove trailing newline character - causes error with TAXSIM
    # and write to file
    cat(sub(x = data_string, "(\r\n|\n)$", ""),
        file = to_taxsim_tmp_filename)

    # create http post and send to NBER
    http_response <- httr::POST(
      url = "https://taxsim.nber.org/uptest/webfile.cgi",
      body = list(txpydata.raw = httr::upload_file(to_taxsim_tmp_filename)))

    # extract response body as to text
    response_text <- httr::content(http_response, as = 'text')

    # convert text to a tibble to match vroom format
    from_taxsim <- tibble::tibble(
      utils::read.table(text = response_text,
                        header = T,
                        sep = ","))

  } else if (interface == "wasm") {

    # connect to js and wasm files
    wasm_path   <- system.file("webassembly/taxsim.wasm", package = "usincometaxes")
    js_path     <- system.file("javascript/taxsim.js",    package = "usincometaxes")
    wasm_binary <- readBin(wasm_path, raw(), file.info(wasm_path)$size)

    # convert input data to string
    data_string <- vroom::vroom_format(.data, delim = ",", eol = "\\n")

    # load the V8 context
    ctx <- V8::v8()
    ctx$assign("wasmBinary", wasm_binary)
    ctx$source(js_path)

    response_text <- ctx$call("taxsim",
                              V8::JS(paste0("'", data_string, "'")),
                              V8::JS("{wasmBinary}"),
                              await = TRUE)

    from_taxsim <- tibble::tibble(
      utils::read.table(text = response_text,
                        header = T,
                        sep = ","))

  } else {
    stop("Invalid value for `interface` argument.")
  }

  message("Connected to TAXSIM server and downloaded tax data.")

  # add column names to the TAXSIM columns that do not have names
  from_taxsim <- clean_from_taxsim(from_taxsim)

  # check that input and output data sets have the same unique ID numbers
  output_s <- from_taxsim$taxsimid

  if (!setequal(input_s, output_s)) {
    stop(paste0(
      "The input and output data sets should have the exact same numbers for `taxsimid` and they do not.",
      "\nThis could mean that your input data was not in the proper format, producing problems in the output.",
      "\nPlease check your input data.",
      "\nSee the following link for formatting information: https://www.shaneorr.io/r/usincometaxes/articles/taxsim-input.html"
       )
    )
  }

  return(from_taxsim)

}
