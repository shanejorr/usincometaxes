#' Create SSH command
#'
#' @param to_taxsim_tmp_filename Full file path and name to the temp file containing the data to upload to TAXSIM.
#' @param from_taxsim_tmp_filename Full file path and name to the temp file that will contain the downloaded data.
#' @param port String. The port to use when connecting to the TAXAIM server
#'
#' @return Returns a string that represents the ssh command.
#'
#' @keywords internal
create_ssh_command <- function(to_taxsim_tmp_filename, from_taxsim_tmp_filename, port) {

  if (!port %in% c('22', '443', '80')) {
    stop("`port` must be either '443', '80', or '22'.")
  }

  ssh_server <- 'taxsim35@taxsimssh.nber.org'

  paste0(
    "ssh -T -o ConnectTimeout=20 -o StrictHostKeyChecking=no -p ",
    port, " ", ssh_server, " < ",
    to_taxsim_tmp_filename, " > ", from_taxsim_tmp_filename
  )

}

#' Upload and download data
#'
#' Uploads the data to the TAXSIM server via SSH and then downloads the data with taxes.
#' The uploads and downloads are of csv files that are saved in temp directories.
#'
#' @param to_taxsim_tmp_filename Full file path and name to the temp file containing the data to upload to TAXSIM.
#' @param from_taxsim_tmp_filename Full file path and name to the temp file that will contain the downloaded data.
#' @param port String. The port to use when connecting to the TAXAIM server
#'
#' @keywords internal
connect_server_single_ssh <- function(to_taxsim_tmp_filename, from_taxsim_tmp_filename, port) {

  error_message <- "Could not connect to the TAXSIM server via ssh on the port we just tried."

  ssh_command <- create_ssh_command(to_taxsim_tmp_filename, from_taxsim_tmp_filename, port)

  tryCatch(
    warning = function(cnd) stop(error_message, call. = FALSE),
    error = function(cnd) stop(error_message, call. = FALSE),
    expr = {
      message(paste0("Connecting to TAXSIM server via ssh on port ", port, "..."))

      # default to using the 'shell' function to run ssh command, but use 'ssytem' if shell is not present
      if (exists('shell', mode = "function")) {
        exc <- shell(ssh_command)

      } else if (exists('system', mode = "function")) {
        exc <- system(ssh_command)

      } else {
        stop("Could not find the `shell` or `system` functions in R. These functions are needed to run SSH commands.", call. = FALSE)
      }

      # throw an error if there is a non-zero exit code
      if (exc != 0) stop()

      message("Upload and download successful!")
    }
  )

}

#' Upload and download data from all ports
#'
#' Tries to upload and download the data from the TAXSIM server using three different ports.
#' Will use the first port that is successful and the other ports will not be tried.
#'
#' @param to_taxsim_tmp_filename Full file path and name to the temp file containing the data to upload to TAXSIM.
#' @param from_taxsim_tmp_filename Full file path and name to the temp file that will contain the downloaded data.
#'
#' @keywords internal
connect_server_all_ssh <- function(to_taxsim_tmp_filename, from_taxsim_tmp_filename) {

  # check to see if ssh is installed on the local machine
  # produce error message if it is not
  if (Sys.which('ssh') == "") {
    stop("You do not have an SSH client installed on your computer. Please install SSH.\nUse `Sys.which('ssh')` to check if you have SSH installed.",
         call. = FALSE)
  }

  error_message <- "There was a problem with SSH."

  tryCatch(
    error = function(cnd) {
      tryCatch(
        error = function(cnd) {
          tryCatch(
            error = function(cnd) stop(error_message, call. = FALSE),
            connect_server_single_ssh(to_taxsim_tmp_filename, from_taxsim_tmp_filename, '80')
          )
        },
        connect_server_single_ssh(to_taxsim_tmp_filename, from_taxsim_tmp_filename, '443')
      )
    },
    connect_server_single_ssh(to_taxsim_tmp_filename, from_taxsim_tmp_filename, '22')
  )

}

#' Import data via ssh
#'
#' This function wraps all the other ssh functions to upload, download, and import TAXSIM results.
#' It's the only function that need sto be ran to import data via ssh
#'
#' @param to_taxsim_tmp_filename Full file path and name to the temp file containing the data to upload to TAXSIM.
#' @param from_taxsim_tmp_filename Full file path and name to the temp file that will contain the downloaded data.
#'
#' @keywords internal
import_data_ssh <- function(to_taxsim_tmp_filename, from_taxsim_tmp_filename, idtl) {

  # upload input data via ssh
  connect_server_all_ssh(to_taxsim_tmp_filename, from_taxsim_tmp_filename)

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
