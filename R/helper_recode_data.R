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
