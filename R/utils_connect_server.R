#' Create SSH command
#'
#' @param to_taxsim_tmp_filename Full file path and name to the temp file containing the data to upload to TAXSIM.
#'      This is stdin.
#' @param from_taxsim_tmp_filename Full file path and name to the temp file that will contain the downloaded data.
#'      This is stdout.
#' @param std_error_filename The file name for the file to write out errors. This is stderror.
#' @param known_hosts_file File name to write out the known_hosts file. Must be in a temp directory
#'      because that is the only directory where you can edit files.
#' @param port String. The port to use when connecting to the TAXSIM server
#'
#' @return Returns a string that represents the ssh command.
#'
#' @keywords internal
create_ssh_command <- function(to_taxsim_tmp_filename, from_taxsim_tmp_filename, std_error_filename, known_hosts_file, port) {

  if (!port %in% c('22', '443', '80')) {
    stop("`port` must be either '443', '80', or '22'.")
  }

  ssh_server <- 'taxsim35@taxsimssh.nber.org'

  paste0(
    "ssh -T -o ConnectTimeout=20 -o StrictHostKeyChecking=no -o UserKnownHostsFile=", known_hosts_file,
    " -p ", port, " ", ssh_server, " < ", to_taxsim_tmp_filename,
    # stdout and stderror
    " 1> ", from_taxsim_tmp_filename, " 2> ", std_error_filename
  )

}

#' Upload and download data
#'
#' Uploads the data to the TAXSIM server via SSH and then downloads the data with taxes.
#' The uploads and downloads are of csv files that are saved in temp directories. The parameters are the
#' same as those in 'create_ssh_command'.
#'
#' @param to_taxsim_tmp_filename Full file path and name to the temp file containing the data to upload to TAXSIM.
#'      This is stdin.
#' @param from_taxsim_tmp_filename Full file path and name to the temp file that will contain the downloaded data.
#'      This is stdout.
#' @param std_error_filename The file name for the file to write out errors. This is stderror.
#' @param known_hosts_file File name to write out the known_hosts file. Must be in a temp directory
#'      because that is the only directory where you can edit files.
#'
#' @keywords internal
connect_server_single_ssh <- function(to_taxsim_tmp_filename, from_taxsim_tmp_filename, std_error_filename, known_hosts_file) {

  # check to see if ssh is installed on the local machine
  # produce error message if it is not
  if (Sys.which('ssh') == "") {
    stop("You do not have an SSH client installed on your computer. Please install SSH.\nUse `Sys.which('ssh')` to check if you have SSH installed.",
         call. = FALSE)
  }

  port <- '22'

  error_message <- "Could not connect to the TAXSIM server via ssh."

  ssh_command <- create_ssh_command(to_taxsim_tmp_filename, from_taxsim_tmp_filename, std_error_filename, known_hosts_file, port)

  # default to using the 'shell' function to run ssh command, but use 'system' if shell is not present
  if (exists('shell', mode = "function")) {
      exc <- shell(ssh_command)
  } else if (exists('system', mode = "function")) {
      exc <- system(ssh_command)
  } else {
      stop("Could not find the `shell` or `system` functions in R. These functions are needed to run SSH commands.", call. = FALSE)
  }

  # if there is something in the error log throw an error
  # check to see if there is an error in stderror and return the error message
  stderror <- readLines(std_error_filename)
  errors <- grepl('^Stop.*|^STOP.*', stderror)

  # if there is an error, print it and stop the function
  if (any(errors)) {
    error_code <- sub("^STOP |^Stop ", "", stderror[errors])
    error_prefix <- paste0(
      "TAXSIM's server returned a ", error_code, " error.\n",
      "This most likely means there is something wrong with the data's format.\n",
      "Please make sure your column names are correct and your data types are proper.\n",
      "For more information on formatting your data please see the following:\n",
      "     usincometaxes documentation: https://www.shaneorr.io/r/usincometaxes/articles/taxsim-input.html\n",
      "     TAXSIM 35 documentation: https://users.nber.org/~taxsim/taxsim35/\n",
      "\nYou can try manually uploading the data to TAXSIM as an avenue of troubleshooting.\n",
      "See the following address for more information: https://www.shaneorr.io/r/usincometaxes/articles/send-data-to-taxsim.html",
    )

    stop(error_prefix, call. = FALSE)
  }

  # throw an error if there is a non-zero exit code
  if (exc != 0) stop("There was an unexpected problem with either connecting to TAXSIM's server or with the format of your data.")

}

#' Import data via ssh
#'
#' This function wraps all the other ssh functions to upload, download, and import TAXSIM results.
#' It's the only function that need sto be ran to import data via ssh
#'
#' @param to_taxsim_tmp_filename Full file path and name to the temp file containing the data to upload to TAXSIM.
#'      This is stdin.
#' @param from_taxsim_tmp_filename Full file path and name to the temp file that will contain the downloaded data.
#'      This is stdout.
#' @param std_error_filename The file name for the file to write out errors. This is stderror.
#' @param known_hosts_file File name to write out the known_hosts file. Must be in a temp directory
#'      because that is the only directory where you can edit files.
#' @param idtl Whether all columns are being returned. 0 if only returning the primary columns.
#'      2 if returning all columns from TAXSIM
#'
#' @keywords internal
import_data_ssh <- function(to_taxsim_tmp_filename, from_taxsim_tmp_filename, std_error_filename, known_hosts_file, idtl) {

  # upload input data via ssh
  connect_server_single_ssh(to_taxsim_tmp_filename, from_taxsim_tmp_filename, std_error_filename, known_hosts_file)

  # import downloaded data
  import_data_helper(from_taxsim_tmp_filename, idtl)

}

#' Import data helper
#'
#' When returning all columns, the data retrieved from TAXSIM contains an extra column. This function
#' trims the extra column if we are returning all information.
#'
#' @param raw_data The raw data from TAXSIM that we want to load into R.
#'
#' @keywords internal
import_data_helper <- function(raw_data, idtl) {

  if (!(idtl %in% c(0, 2))) stop('`idtl` must either be 0 or 2')

  if (idtl == 2) {

    col_headers <- vroom::vroom(raw_data, col_names = FALSE, n_max = 1, progress = FALSE, show_col_types = FALSE)

    raw_data <- vroom::vroom(raw_data, col_names = FALSE, skip = 1, progress = FALSE, show_col_types = FALSE)

    if (ncol(raw_data) == 46 & all(is.na(raw_data$X46))) {

      raw_data <- raw_data[-46]

    }

    col_names <- t(col_headers[1, ])

    colnames(raw_data) <- col_names

  } else if (idtl == 0) {

    raw_data <- vroom::vroom(raw_data, progress = FALSE, show_col_types = FALSE)

  }

  return(raw_data)

}
