context("Final Output")

test_that("Package output matches TAXSIM test file", {

  # example test from TAXSIM http://users.nber.org/~taxsim/taxsim32/low-level-remote.html
  taxsim_input <- data.frame(
    id_number = as.integer(1),
    filing_status = 'married, jointly',
    tax_year = 1970,
    long_term_capital_gains = 100000
  )

  taxsim_output <- taxsim_calculate_taxes(taxsim_input)

  federal_taxes <- taxsim_output$federal_taxes

  # number from http://users.nber.org/~taxsim/taxsim32/low-level-remote.html
  test_result <- 16700.04

  expect_equal(federal_taxes, test_result)

  # make sure ID numbers are properly returned
  # and program can calculate taxes for the current year and previous years
  id_nums <- as.integer(seq(1, 10))
  n <- length(id_nums)
  current_year <- as.numeric(format(Sys.Date(), "%Y"))
  years <- seq(current_year, current_year - n + 1)

  taxsim_input <- data.frame(
    id_number = id_nums,
    filing_status = rep('married, jointly', n),
    tax_year = years,
    primary_wages = rep(50000, n)
  )

  taxsim_output <- taxsim_calculate_taxes(taxsim_input)

  expect_equal(taxsim_input$id_number, taxsim_output$id_number)

})
