#' @title
#' Create a data set to send to TAXSIM 32.
#'
#' @param .data The data set used to calculate taxes from
#'
#' @description
#' This function takes a data set, checks it to make sure it is in the proper format for TAXSIM 32,
#' and then cleans so it can be sent to TAXSIM 32.
#'
#' @details None
#' @keywords internal
create_dataset_for_taxsim <- function(.data) {

  state_colname <- 'state'
  filing_status_colname <- 'filing_status'

  cols <- colnames(.data)

  # only keep TAXSIM columns
  cols_in_taxsim_and_df <- intersect(cols, names(taxsim_cols()))
  .data <- .data[cols_in_taxsim_and_df]

  # make sure all the data is of the proper type
  # function will either stop the running of a function with text of the error
  # or print that everything is OK
  check_data(.data, cols, state_colname)

  # make sure all column that should be numeric are in fact numeric
  # if so, also convert them to integer
  .data <- check_numeric(.data, cols)

  # get the state SOI if the state column is present
  if (state_colname %in% cols) {
    .data[[state_colname]] <- get_state_soi(.data[[state_colname]])
  }

  # make sure all filing_status values are proper and recode filing_status to integer,
  # which is needed for taxsim
  if (filing_status_colname %in% cols) {
    .data[[filing_status_colname]] <- recode_filing_status(.data[[filing_status_colname]])
  }

  # change column names to the required TAXSIM column names
  for (col in cols_in_taxsim_and_df) {
    new_colname_for_taxsim <- taxsim_cols()[[col]]
    names(.data)[names(.data) == col] <- new_colname_for_taxsim
  }

  return(.data)

}

#' @title
#' Calculate state and federal taxes using TAXSIM 32.
#'
#' @description
#' This function calculates state and federal income taxes using the TAXSIM 32 tax simulator.
#' See \url{https://users.nber.org/~taxsim/taxsim32/} for more information on TAXSIM 32.
#'
#' @param .data Data frame containing the information that will be used to calculate taxes.
#'    This data set will be sent to TAXSIM. Data frame must have specified column names and data types.
#' @param return_all_information Boolean (TRUE or FALSE). Whether to return all information from TAXSIM (TRUE),
#'     or only key information (FALSE). Returning all information returns 42 columns of output, while only
#'     returning key information returns 9 columns. It is faster to download results with only key information.
#' @param upload_method Either 'ftp' or 'ssh', can also use upper case. Defaults to 'ftp'. Determines whether ftp or ssh will be used to send data
#'    to TAXSIM and retrieve the results. SSH is faster, so use it when there are over 100,000 records.
#'    SSH is available in Windows 10 since autumn of 2019.
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
#' @section Additional Output
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
#' family_taxes <- taxsim_calculate_taxes(family_income, upload_method = 'ftp')
#'
#' merge(family_income, family_taxes, by = 'id_number')
#'
#' @section Giving credit where it is due:
#'
#' The NBER's \href{http://users.nber.org/~taxsim/taxsim32/}{TAXSIM 32} tax simulator does all tax
#' calculations. This package simply lets users interact with the tax simulator through R. Therefore,
#' users should cite the TAXSIM 32 tax simulator when they use this package in their work:
#'
#' Feenberg, Daniel Richard, and Elizabeth Coutts, An Introduction to the TAXSIM Model,
#' Journal of Policy Analysis and Management vol 12 no 1, Winter 1993, pages 189-194.
#'
#' @export
taxsim_calculate_taxes <- function(.data, return_all_information = FALSE, upload_method = 'ftp') {

  # make ftp and ssh lower case so that FTP and SSH work also
  upload_method <- tolower(upload_method)

  # check parameter options
  # must change this function if parameters are added
  check_parameters(.data, return_all_information, upload_method)

  # TAXSIM username and password are publicly listed
  # that's why they are hard-coded
  taxsim_user <- 'taxsim'
  taxsim_pass <- '02138'
  taxsim_user_pass <- paste0(taxsim_user, ":", taxsim_pass)

  # create data set to send to taxsim
  to_taxsim <- create_dataset_for_taxsim(.data)

  # add 2 to column if we need all columns, otherwise add 0 for only the default columns
  to_taxsim$idtl <- if (return_all_information) 2 else 0

  # send data set to taxsim server

  # save csv file of data set to a temp folder
  to_taxsim_tmp_filename <- tempfile("to_taxsim_")
  readr::write_csv(to_taxsim, to_taxsim_tmp_filename)

  if (upload_method == 'ftp') {

    # create random filename to upload to server
    fake_taxsim_filename <- sample(letters, 10, replace = T)
    fake_taxsim_filename <- paste(fake_taxsim_filename, collapse = "")
    fake_taxsim_filename <- paste0("ftp://", taxsim_user_pass, "@taxsimftp.nber.org/tmp/", fake_taxsim_filename)

    # upload TAXSIM csv file to server
    print("Uploading data to TAXSIM server via ftp.")

    tryCatch(
      expr = {
        RCurl::ftpUpload(
          what = to_taxsim_tmp_filename,
          to = fake_taxsim_filename
        )

        # download data set containing tax values from taxsim server
        # store data in temp folder

        # FTP url to download results
        taxsim_server_url <- paste0(fake_taxsim_filename, ".txm32")

        print("Downloading data from TAXSIM server via ftp.")

        from_taxsim_curl <- RCurl::getURL(taxsim_server_url, userpwd = taxsim_user_pass, connecttimeout = 120)

        from_taxsim <- vroom::vroom(
          from_taxsim_curl, trim_ws = TRUE, show_col_types = FALSE, progress = FALSE
        )
      },
      error = function(e){
        stop("There was a problem with ftp or the dataset is in the wrong format. Try ssh instead.")
      }
    )

  } else if (upload_method == 'ssh') {

    # tempfile to save csv results into
    from_taxsim_curl <- paste0(tempfile("from_taxsim_"), ".csv")

    ssh_command <- paste0("ssh -T -o ConnectTimeout=10 -o StrictHostKeyChecking=no taxsimssh@taxsimssh.nber.org < ",
                          to_taxsim_tmp_filename, " > ", from_taxsim_curl)

    print("Sending and retrieving data from TAXSIM server via SSH")

    # run ssh command with error handling
    tryCatch(
      expr = {

        system(ssh_command, timeout = 120)

        from_taxsim <- vroom::vroom(
          from_taxsim_curl, trim_ws = TRUE, show_col_types = FALSE, progress = FALSE
        )

      },
      error = function(e){
        stop("There was a problem with ssh or the dataset is in the wrong format. Try ftp instead.")
      }
    )

  }

  # clean final output
  # convert from tibble to data frame for consistency
  from_taxism_cleaned <- clean_from_taxsim(from_taxsim)
  #from_taxism_cleaned <- data.frame(from_taxism_cleaned)

  return(from_taxism_cleaned)

}
