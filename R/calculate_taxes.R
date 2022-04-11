#' Convert a data frame to the TAXSIM 35 output.
#'
#' This function takes a data set that is in the format required for \code{\link{taxsim_calculate_taxes}},
#' checks it to make sure it is in the proper format for TAXSIM 35, and then cleans so it can be sent to TAXSIM 35.
#' This function is useful for troubleshooting. It is not needed to calculate taxes. The function is useful
#' if you continue receiving unreasonable errors from \code{\link{taxsim_calculate_taxes}}. In such as case,
#' you can run this function on the data frame used in \code{\link{taxsim_calculate_taxes}}. You should then save
#' this data frame as a csv file. Then, upload the file to \href{http://taxsim.nber.org/taxsim35/}{TAXSIM 35}.
#' If there are no errors with TAXSIM 35 then the issue lies in \code{\link{taxsim_calculate_taxes}}.
#'
#' @param .data Data frame containing the information that will be used to calculate taxes.
#'    This data set will be sent to TAXSIM. Data frame must have specified column names and data types.
#'
#' @return A data frame that that can be manually uploaded to \href{http://taxsim.nber.org/taxsim35/}{TAXSIM 35}.
#'
#' @examples
#'
#' family_income <- data.frame(
#'     id_number = c(1, 2),
#'      state = c('North Carolina', 'NY'),
#'      tax_year = c(2015, 2015),
#'      filing_status = c('single', 'married, jointly'),
#'      primary_wages = c(10000, 100000),
#'      primary_age = c(26, 36)
#' )
#'
#' family_taxes <- create_dataset_for_taxsim(family_income)
#'
#' \dontrun{
#' # write out the data frame as a csv file for uploading to TAXSIM 35
#' vroom::vroom_write(family_taxes, delim = ",")
#' }
#'
#' @export
create_dataset_for_taxsim <- function(.data) {

  state_colname <- 'state'
  filing_status_colname <- 'mstat'

  cols <- colnames(.data)

  # only keep TAXSIM columns
  cols_in_taxsim_and_df <- intersect(cols, names(taxsim_cols()))
  .data <- .data[cols_in_taxsim_and_df]

  # convert all NA values to 0 for non-required items
  non_req_cols <- names(taxsim_cols()[4:length(taxsim_cols())])
  non_req_cols <- intersect(colnames(.data), non_req_cols)
  .data[non_req_cols][is.na(.data[non_req_cols])] <- 0

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

  }

  # make sure all filing_status values are proper
  if (filing_status_colname %in% cols) {
    .data[[filing_status_colname]] <- recode_filing_status(.data[[filing_status_colname]])
  }

  return(.data)

}

#' @title
#' Calculate state and federal taxes using TAXSIM 32.
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
#'
#' @section Required columns:
#'
#' \code{id_number} An arbitrary, non-negative, whole number. Each number must be unique.
#'      This number links the results from TAXSIM 32 to the original data frame with entries.
#'
#' \code{tax_year} Tax year ending Dec 31 (4 digits between 1960 and 2023). State must be zero if
#'      year is before 1977 or after 2023.
#'
#' \code{filing_status} Filing status of tax unit. One of the following: "single" for single;
#'      "married, jointly" for married, filing jointly; "married, separately" for married, filing separately;
#'      "dependent child" for dependent, usually a child with income; or "head of household" for head of household filing status.
#'
#' @section Optional columns:
#'
#' \code{state} State two letter abbreviation or state SOI code. If state income taxes are not needed,
#'      either label as "No State" or remove this variable. State income tax information is only available from 1977 to 2023.
#'
#' \code{primary_age} Age of primary taxpayer as of December 31st of tax year. Taxpayer age variables
#'      determine eligibility for additional standard deductions, personal exemption, EITC and AMT exclusion.
#'
#' \code{spouse_age} Age of spouse as of December 31st of tax year.
#'
#' \code{num_dependents} Total number of dependents.
#'
#' \code{num_dependents_thirteen} Number of children under 13 with eligible child care expenses (Dependent Care Credit).
#'
#' \code{num_dependents_seventeen} Number of children under 17 for the entire tax year (Child Credit).
#'      This includes children under 13.
#'
#' \code{num_dependents_eitc} Number of qualifying children for EITC. (Typically younger than 19 or
#'      younger than 24 and a full-time student).
#'
#' \code{primary_wages} Wage and salary income of Primary Taxpayer (include self-employment but no QBI).
#'
#' \code{spouse_wages} Wage and salary income of Spouse (include self-employment but no QBI). Must
#'      be zero or the column should not exist for non-joint returns.
#'
#' \code{dividends} Dividend income (qualified dividends only for 2003 on).
#'
#' \code{interest} Interest income received (+/-).
#'
#' \code{short_term_capital_gains} Short Term Capital Gains or losses (+/-).
#'
#' \code{long_term_capital_gains} Long Term Capital Gains or losses (+/-).
#'
#' \code{other_property_income} Other property income subject to NIIT, including: unearned or limited
#'      partnership and passive S-Corp profits; rent not eligible for QBI deduction; non-qualified
#'      dividends; capital gains distributions on form 1040; and other income or loss not otherwise enumerated here.
#'
#' \code{other_non_property_income} Other non-property income not subject to Medicare NIIT such as:
#'      alimony; nonwage fellowships; and state income tax refunds (itemizers only). Also includes
#'      adjustments and items such as: alimony paid; Keogh and IRA contributions; foreign income exclusion; and NOLs
#'
#' \code{pensions} Taxable Pensions and IRA distributions.
#'
#' \code{social_security} Gross Social Security Benefits.
#'
#' \code{unemployment} Unemployment compensation received.
#'
#' \code{other_transfer_income} Other non-taxable transfer income such as: welfare; workers comp;
#'      veterans benefits; and child support that would affect eligibility for state property tax
#'      rebates but would not be taxable at the federal level.
#'
#' \code{rent_paid} Rent paid (used only for calculating state property tax rebates).
#'
#' \code{property_taxes} Real Estate taxes paid. This is a preference for the AMT and is is also
#'      used to calculate state property tax rebates.
#'
#' \code{other_itemized_deductions} Other Itemized deductions that are a preference for the Alternative
#'      Minimum Tax. These would include: Other state and local taxes (line 8 of Schedule A) plus
#'      local income tax; Preference share of medical expenses; Miscellaneous (line 27).
#'
#' \code{child_care_expenses} Child care expenses.
#'
#' \code{misc_deductions} Deductions not included in `other_itemized_deductions` and not a preference
#'      for the AMT, including (on Schedule A for 2009). Might include: Deductible medical expenses
#'      not included in Line 16; Motor Vehicle Taxes paid; Home mortgage interest; Charitable contributions;
#'      and Casulty or Theft Losses.
#'
#' \code{scorp_income} Active S-Corp income (is SSTB).
#'
#' \code{qualified_business_income} Primary Taxpayer's Qualified Business Income (QBI) subject to a
#'      preferential rate without phaseout and assuming sufficient wages paid or capital to be eligible
#'      for the full deduction. Subject to SECA and Medicare additional Earnings Tax.
#'
#' \code{specialized_service_trade} Primary Taxpayer's Specialized Service Trade or Business service
#'      (SSTB) with a preferential rate subject to claw-back. Subject to SECA and Medicare Additional Earnings Tax.
#'
#' \code{spouse_qualified_business_income} Spouse's QBI. Must be zero for non-joint returns, or the
#'      column should not exist.
#'
#' \code{spouse_specialized_service_trade} Spouse's SSTB. Must be zero for non-joint returns, or the
#'      column should not exist.
#'
#' @section Note on number of dependents:
#'
#' \code{num_dependents} columns are not mutually exclusive. For example, a family with a 13 year old
#' can report the dependent in \code{num_dependents_thirteen} and also in \code{num_dependents_seventeen}.
#'
#' @return Returns a data frame with the following columns:
#'
#' \code{id_number} The unique id number for the row that corresponds to the id number in \code{.data}
#'
#' \code{federal_taxes} Total federal taxes due. Corresponds to \code{fiitax} in TAXSIM.
#'
#' \code{state_taxes} Total state taxes due; if state taxes were calculated.
#'      Corresponds to \code{siitax} in TAXSIM.
#'
#' \code{fica_taxes} Total FICA taxes due. This includes both the employee and company share.
#'      Corresponds to \code{fica} in TAXSIM.
#'
#' \code{federal_marginal_rate} Federal marginal tax rate of taxpayer. Corresponds to \code{frate} in TAXSIM.
#'
#' \code{state_marginal_rate} State marginal tax rate of taxpayer. Corresponds to \code{srate} in TAXSIM.
#'
#' \code{fica_rate} FICA rate. Corresponds to \code{ficar} in TAXSIM.
#'
#' Additional columns will be returned if \code{return_all_information = TRUE}
#'
#'
#' @examples
#'
#' family_income <- data.frame(
#'     id_number = c(1, 2),
#'      state = c('North Carolina', 'NY'),
#'      tax_year = c(2015, 2015),
#'      filing_status = c('single', 'married, jointly'),
#'      primary_wages = c(10000, 100000),
#'      primary_age = c(26, 36)
#' )
#'
#' family_taxes <- taxsim_calculate_taxes(family_income)
#'
#' merge(family_income, family_taxes, by = 'id_number')
#'
#' @section Giving credit where it is due:
#'
#' The NBER's \href{http://taxsim.nber.org/taxsim35/}{TAXSIM 35} tax simulator does all tax
#' calculations. This package simply lets users interact with the tax simulator through R. Therefore,
#' users should cite the TAXSIM 32 tax simulator when they use this package in their work:
#'
#' Feenberg, Daniel Richard, and Elizabeth Coutts, An Introduction to the TAXSIM Model,
#' Journal of Policy Analysis and Management vol 12 no 1, Winter 1993, pages 189-194.
#'
#' @export
taxsim_calculate_taxes <- function(.data, marginal_tax_rates = 'Wages', return_all_information = FALSE) {

  # save input ID numbers as object, so we can make sure the output ID numbers are the same
  input_id_numbers <- .data$id_number

  # create data set to send to taxsim
  # to_taxsim <- create_dataset_for_taxsim(.data)

  # check parameter options
  # must change this function if parameters are added
  check_parameters(.data, return_all_information)

  # add 2 to column if we need all columns, otherwise add 0 for only the default columns
  idtl <- if (return_all_information) 2 else 0

  to_taxsim[['idtl']] <- idtl

  # add marginal tax rate calculation
  to_taxsim[['mtr']] <- convert_marginal_tax_rates(marginal_tax_rates)

  # send data set to taxsim server

  # save csv file of data set to a temp folder
  to_taxsim_tmp_filename <- tempfile(pattern = 'upload_', fileext = ".csv")
  vroom::vroom_write(to_taxsim, to_taxsim_tmp_filename, delim = ",", progress = FALSE)

  from_taxsim_tmp_filename <- tempfile(pattern = 'download_', fileext = ".csv")

  # try uploading and downloading via ssh first,
  # then use ftp if ftp does not work
  from_taxsim <- tryCatch(
    error = function(cnd) {
      tryCatch(
        error = function(cnd) stop('Could not connect to TAXSIM server via ftp or ssh', call. = FALSE),
        import_data_ftp(to_taxsim_tmp_filename, idtl)
      )
    },
    import_data_ssh(to_taxsim_tmp_filename, from_taxsim_tmp_filename, idtl)
  )

  # clean final output
  from_taxism_cleaned <- clean_from_taxsim(from_taxsim)

  # check that input and output data sets have the same unique ID numbers
  output_id_numbers <- from_taxism_cleaned$id_number

  if (!setequal(input_id_numbers, output_id_numbers)) {
    stop(paste0(
      "The input and output data sets should have the exact same numbers for `id_number` and they do not.",
      "\nThis could mean that your input data was not in the proper format, producing problems in the output.",
      "\nPlease check your input data.",
      "\nSee the following link for formatting information: https://www.shaneorr.io/r/usincometaxes/articles/taxsim-input.html"
       )
    )
  }

  return(from_taxism_cleaned)

}
