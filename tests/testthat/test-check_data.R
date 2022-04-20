test_that("Filing status properly converts to integer", {

  # mapping of strings to integers
  filing_status_values <-   c(
    'single' = 1,
    'married, jointly' = 2,
    'married, separately' = 6,
    'dependent child' = 8,
    'head of household' = 1
  )

  id_nums <- seq(1, length(filing_status_values))

  taxsim_input <- data.frame(
    taxsimid = id_nums,
    mstat = names(filing_status_values),
    year = 2018,
    pwages = 50000,
    state = 'NC'
  )

  taxsim_dataset <- create_dataset_for_taxsim(taxsim_input)

  # test that all states were returned
  expect_equal(taxsim_dataset$mstat, as.character(filing_status_values))

})
