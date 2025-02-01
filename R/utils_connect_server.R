#' Use WASM to calculate taxes locally
#'
#' @param .data Dataset that can be sent to WASM.
#'
#' @keywords internal
calculate_taxes_wasm <- function(.data) {

  # connect to js and wasm files
  wasm_path   <- system.file("taxsim/taxsim.wasm", package = "usincometaxes")
  js_path     <- system.file("taxsim/taxsim.js",    package = "usincometaxes")
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

  return(from_taxsim)

}

#' Check if SSH is available on the system
#'
#' @return Logical indicating if SSH is available
#' @keywords internal
is_ssh_available <- function() {
  os_type <- .Platform$OS.type

  if (os_type == "windows") {
    # Check if SSH is available on Windows
    ssh_check <- suppressWarnings(system("where ssh", intern = TRUE))
    return(!inherits(ssh_check, "try-error") && length(ssh_check) > 0)
  } else {
    # Check if SSH is available on Unix-like systems
    ssh_check <- suppressWarnings(system("which ssh", intern = TRUE))
    return(!inherits(ssh_check, "try-error") && length(ssh_check) > 0)
  }
}

#' Execute SSH command in a cross-platform way
#'
#' @param command The SSH command to execute
#' @return The command output or an error
#' @keywords internal
execute_ssh_command <- function(command) {
  os_type <- .Platform$OS.type

  if (os_type == "windows") {
    # Use shell() on Windows
    result <- shell(command, intern = TRUE)
  } else {
    # Use system() on Unix-like systems
    result <- system(command, intern = TRUE)
  }

  return(result)
}

#' Use SSH to calculate taxes through NBER's server
#'
#' @param .data Dataset that can be sent to NBER's server
#' @param port Port number to use for SSH connection (defaults to 22)
#' @keywords internal
calculate_taxes_ssh <- function(.data, port = 22) {

  # Check if SSH is available
  if (!is_ssh_available()) {
    stop(
      "SSH is not available on your system. Please install OpenSSH or use the WASM method instead.\n",
      "For Windows users: OpenSSH can be installed through Windows Features or PowerShell.\n",
      "For Unix users: Install OpenSSH through your package manager.",
      call. = FALSE
    )
  }

  # Create temporary files for input and output
  tmp_input <- tempfile(fileext = ".raw")
  tmp_output <- tempfile(fileext = ".raw")

  # Convert input data to string format that TAXSIM expects
  data_string <- vroom::vroom_format(.data, delim = ",", eol = "\n")

  # Write data to temporary file
  writeLines(data_string, tmp_input)

  # Construct SSH command with options to suppress prompts
  ssh_command <- sprintf(
    "ssh -T -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p %d txmtest@taxsim35.nber.org < %s > %s",
    port,
    tmp_input,
    tmp_output
  )

  # Execute SSH command using cross-platform function
  system_result <- tryCatch(
    {
      execute_ssh_command(ssh_command)
      TRUE
    },
    error = function(e) {
      FALSE
    },
    warning = function(w) {
      TRUE  # SSH often gives warnings but still works
    }
  )

  if (!system_result) {
    stop("Failed to connect to TAXSIM server. Please check your internet connection and try again.",
         call. = FALSE)
  }

  # Read results
  response_text <- tryCatch(
    {
      readLines(tmp_output)
    },
    error = function(e) {
      stop("Failed to read TAXSIM results.", call. = FALSE)
    },
    finally = {
      # Clean up temporary files
      unlink(tmp_input)
      unlink(tmp_output)
    }
  )

  # Convert response to tibble
  from_taxsim <- tibble::tibble(
    utils::read.table(
      text = response_text,
      header = TRUE,
      sep = ",",
      stringsAsFactors = FALSE
    )
  )

  return(from_taxsim)
}
