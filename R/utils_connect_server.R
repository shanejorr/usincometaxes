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

  .data <- .data |> select(-mtr)

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
