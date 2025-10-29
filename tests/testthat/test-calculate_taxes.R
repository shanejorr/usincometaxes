test_that("Package output matches TAXSIM test file", {

  # example test from TAXSIM http://taxsim.nber.org/taxsim35/low-level-remote.html
  taxsim_input <- data.frame(
    taxsimid = 1,
    mstat = 2,
    year = 1970,
    ltcg = 100000
  )

  taxsim_output <- taxsim_calculate_taxes(taxsim_input, return_all_information = FALSE)

  federal_taxes <- taxsim_output$fiitax

  # number from http://taxsim.nber.org/taxsim35/low-level-remote.html
  test_result <- 16700.04

  expect_equal(federal_taxes, test_result)
})

test_that("Output is correct (including marital status)", {

  filing_status_values <-   c(
    'single' = 1,
    'married, jointly' = 2,
    'married, separately' = 6,
    'dependent child' = 8,
    'head of household' = 1
  )

  # program can calculate taxes for the current year and previous years
  id_nums <- as.integer(seq(1, 10))
  n <- length(id_nums)
  current_year <- 2023
  years <- seq(current_year, current_year - n + 1)

  n_additional_filing_status <- n - length(filing_status_values)

  taxsim_input <- data.frame(
    taxsimid = id_nums,
    mstat = c(names(filing_status_values), names(filing_status_values)[1:n_additional_filing_status]),
    year = years,
    pwages = rep(50000, n)
  )

  n_col_short <- 8
  n_col_long <- 51  # Updated for new WASM version with additional columns

  taxsim_output_short <- taxsim_calculate_taxes(taxsim_input, return_all_information = FALSE)
  taxsim_output_long <- taxsim_calculate_taxes(taxsim_input, return_all_information = TRUE)

  # test that ID numbers are equal
  expect_equal(taxsim_output_short$taxsimid, taxsim_input$taxsimid)
  expect_equal(taxsim_output_long$taxsimid, taxsim_input$taxsimid)

  # test that column numbers are correct
  expect_equal(ncol(taxsim_output_short), n_col_short)
  expect_equal(ncol(taxsim_output_long), n_col_long)

})

test_that("All states work", {

  states <- state.abb

  id_nums <- seq(1, length(states))

  taxsim_input <- data.frame(
    taxsimid = id_nums,
    mstat = 2,
    year = 2018,
    pwages = 50000,
    state = states
  )

  taxsim_output <- taxsim_calculate_taxes(taxsim_input, return_all_information = FALSE)

  # test that all states were returned
  expect_equal(nrow(taxsim_output), 50)

})
