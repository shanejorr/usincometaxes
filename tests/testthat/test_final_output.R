context("Final Output")

test_that("Package output matches TAXSIM test file", {

  # example test from TAXSIM http://users.nber.org/~taxsim/taxsim32/low-level-remote.html
  taxsim_input <- data.frame(
    id_number = as.integer(1),
    filing_status = 'married, jointly',
    tax_year = 1970,
    long_term_capital_gains = 100000
  )

  # test with ftp and ssh
  taxsim_output_ftp <- taxsim_calculate_taxes(taxsim_input, return_all_information = FALSE, upload_method = 'ftp')
  taxsim_output_ssh <- taxsim_calculate_taxes(taxsim_input, return_all_information = FALSE, upload_method = 'ssh')

  federal_taxes_ftp <- taxsim_output_ftp$federal_taxes
  federal_taxes_ssh <- taxsim_output_ftp$federal_taxes

  # number from http://users.nber.org/~taxsim/taxsim32/low-level-remote.html
  test_result <- 16700.04

  expect_equal(federal_taxes_ftp, test_result)
  expect_equal(federal_taxes_ssh, test_result)
})

test_that("Output is correct", {

  # make sure ID numbers are properly returned

  # program can calculate taxes for the current year and previous years
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

  n_col_short <- 7
  n_col_long <- 43

  taxsim_output_short <- taxsim_calculate_taxes(taxsim_input, return_all_information = FALSE, upload_method = 'ftp')
  taxsim_output_long <- taxsim_calculate_taxes(taxsim_input, return_all_information = TRUE, upload_method = 'ftp')

  # test that ID numbers are equal
  expect_equal(taxsim_input$id_number, taxsim_output_short$id_number)
  expect_equal(taxsim_input$id_number, taxsim_output_long$id_number)

  # test that column numbers are correct
  expect_equal(n_col_short, ncol(taxsim_output_short))
  expect_equal(n_col_long, ncol(taxsim_output_long))

})
