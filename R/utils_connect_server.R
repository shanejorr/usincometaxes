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
    port, " taxsim35@taxsimssh.nber.org < ",
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
connect_server_single <- function(to_taxsim_tmp_filename, from_taxsim_tmp_filename, port) {

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
connect_server_all <- function(to_taxsim_tmp_filename, from_taxsim_tmp_filename) {

  error_message <- "Could not connect to the TAXSIM server via ssh."

  tryCatch(
    error = function(cnd) {
      tryCatch(
        error = function(cnd) {
          tryCatch(
            error = function(cnd) stop(error_message, call. = FALSE),
            connect_server_single(to_taxsim_tmp_filename, from_taxsim_tmp_filename, '20')
          )
        },
        connect_server_single(to_taxsim_tmp_filename, from_taxsim_tmp_filename, '80')
      )
    },
    connect_server_single(to_taxsim_tmp_filename, from_taxsim_tmp_filename, '443')
  )

}
