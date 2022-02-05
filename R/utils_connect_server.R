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

  if (!port %in% c('443', '80', '20')) {
    stop("`port` must be either '443', '80', or '20'.")
  }

  paste0(
    "ssh -T -o ConnectTimeout=20 -o StrictHostKeyChecking=no -p ",
    port, " taxsimssh@taxsimssh.nber.org < ",
    to_taxsim_tmp_filename, " > ", from_taxsim_tmp_filename
  )

}

#' Upload and import TAXSIM results via ftp
#'
#' @param to_taxsim_tmp_filename Full file path and name to the temp file containing the data to upload to TAXSIM.
#'
#' @return A Dataframe of TAXSIM results.
#'
#' @keywords internal
import_data_ftp <- function(to_taxsim_tmp_filename) {

  message('Connecting to TAXSIM server via ftp ...')

  # create random user id
  user_id <- paste0(sample(letters, 10), collapse = "")

  # username and password are publically listed, so we're not revealing private information
  user_pwd <- 'taxsim:02138'

  upload_address <- paste0("ftp://", user_pwd, "@taxsimftp.nber.org/tmp/", user_id, collapse = "")

  download_address <- paste0("ftp://taxsimftp.nber.org/tmp/", user_id, ".txm32", collapse = "")

  RCurl::ftpUpload(to_taxsim_tmp_filename, upload_address)

  message('Data uploaded ...')

  results <- RCurl::getURL(download_address, userpwd = user_pwd)

  message('Data downloaded ...')

  vroom::vroom(results, show_col_types = FALSE)

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

  error_message <- "Could not connect to the TAXSIM server via ssh."

  ssh_command <- create_ssh_command(to_taxsim_tmp_filename, from_taxsim_tmp_filename, port)

  tryCatch(
    warning = function(cnd) stop(error_message, call. = FALSE),
    error = function(cnd) stop(error_message, call. = FALSE),
    expr = {
      message(paste0("Connecting to TAXSIM server via ssh on port ", port, "..."))

      # default to using the 'shell' function to run ssh command, but use 'ssytem' if shell is not present
      if (exists('shell', mode = "function")) {
        shell(ssh_command)

      } else if (exists('system', mode = "function")) {
        system(ssh_command)

      } else {
        stop("Could not find the `shell` or `system` functions in R. These functions are needed to run SSH commands.", call. = FALSE)
      }

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

  error_message <- "Could not connect to the TAXSIM server via ssh."

  tryCatch(
    error = function(cnd) {
      tryCatch(
        error = function(cnd) {
          tryCatch(
            error = function(cnd) stop(error_message, call. = FALSE),
            connect_server_single_ssh(to_taxsim_tmp_filename, from_taxsim_tmp_filename, '20')
          )
        },
        connect_server_single_ssh(to_taxsim_tmp_filename, from_taxsim_tmp_filename, '80')
      )
    },
    connect_server_single_ssh(to_taxsim_tmp_filename, from_taxsim_tmp_filename, '443')
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
import_data_ssh <- function(to_taxsim_tmp_filename, from_taxsim_tmp_filename) {

  # upload input data via ssh
  connect_server_all_ssh(to_taxsim_tmp_filename, from_taxsim_tmp_filename)

  # import downloaded data
  vroom::vroom(from_taxsim_tmp_filename, show_col_types = FALSE, progress = FALSE)
}
