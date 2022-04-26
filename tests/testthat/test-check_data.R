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

test_that("Missing values properly converted", {

  taxsim_input <- data.frame(
    taxsimid = c(1,2),
    mstat = c(1,2),
    year = c(2018,2019),
    state = c(NA, 'NC')
  )

  final_col <- length(taxsim_cols())-2
  test_cols <- taxsim_cols()[5:final_col]

  taxsim_input[test_cols] <- c(NA, 10)

  taxsim_dataset <- create_dataset_for_taxsim(taxsim_input)

  new_expected_values <- as.data.frame(matrix(c(0, 10), nrow = 2, ncol = length(test_cols)))

  colnames(new_expected_values) <- test_cols

  # test that all NA values were changed, but other values were not changed
  expect_equal(taxsim_dataset[test_cols], new_expected_values)
  expect_equal(taxsim_dataset[['state']], c(0, 34))

})
