
<!-- README.md is generated from README.Rmd. Please edit that file -->
<!-- badges: start -->
<!-- badges: end -->

## Calculate Federal and State Income Taxes

`usincometaxes` is an R package that calculates federal and state income
taxes in the United States. It relies on the National Bureau of Economic
Research’s (NBER) [TAXSIM 32](https://users.nber.org/~taxsim/taxsim32/)
tax simulator for calculations. The package takes care of the
behind-the-scenes work of getting the data in the proper format,
converting it to the proper file type for uploading to the NBER server,
uploading the data, downloading the results, and placing the results
into a tidy data frame.

*NOTE: This package is not associated with the NBER. It is a private
creation that uses their wonderful tax calculator.*

## Installation

You can install `usincometaxes` from
[GitHub](https://github.com/shanejorr/usincometaxes) with:

``` r
devtools::install_github("shanejorr/usincometaxes")
```

## Quick example

`usincometaxes` contains one function: `taxsim_calculate_taxes()`. Below
is a simple example of its use.

``` r
library(tidyverse)
library(knitr)
library(usincometaxes)

family_income <- data.frame(
  id_number = as.integer(c(1, 2)),
  state = c('North Carolina', 'NY'),
  tax_year = c(2015, 2020),
  filing_status = c('single', 'married, jointly'),
  primary_wages = c(10000, 100000),
  primary_age = c(26, 36)
)

family_taxes <- taxsim_calculate_taxes(family_income)
#> [1] "All required columns are present and the data is in the proper format!"
#> [1] "Uploading data to TAXSIM server."
#> [1] "Downloading data to TAXSIM server."
```

``` r
kable(family_taxes)
```

| id_number | federal_taxes | state_taxes | fica_taxes | federal_marginal_rate | state_marginal_rate | fica_rate |
|----------:|--------------:|------------:|-----------:|----------------------:|--------------------:|----------:|
|         1 |       -369.12 |      143.75 |       1530 |                  7.65 |                5.75 |        15 |
|         2 |       5029.00 |     4586.76 |      15300 |                 12.00 |                6.09 |        15 |

Users can use the `id_number` column to join the tax data with the
original data set. Every `id_number` in the input data is represented in
the output tax data.

``` r
family_income %>%
  left_join(family_taxes, by = 'id_number') %>%
  kable()
```

| id_number | state          | tax_year | filing_status    | primary_wages | primary_age | federal_taxes | state_taxes | fica_taxes | federal_marginal_rate | state_marginal_rate | fica_rate |
|----------:|:---------------|---------:|:-----------------|--------------:|------------:|--------------:|------------:|-----------:|----------------------:|--------------------:|----------:|
|         1 | North Carolina |     2015 | single           |         1e+04 |          26 |       -369.12 |      143.75 |       1530 |                  7.65 |                5.75 |        15 |
|         2 | NY             |     2020 | married, jointly |         1e+05 |          36 |       5029.00 |     4586.76 |      15300 |                 12.00 |                6.09 |        15 |

## Output

`taxsim_calculate_taxes()` returns a data frame containing the following
columns:

-   `id_number`: ID number from the input data set, so users can match
    the tax information with the input data set
-   `federal_taxes`: Total federal taxes
-   `state_taxes`: Total state taxes, if a state was identified
-   `fica_taxes`: Total FICA taxes, including the employers and
    employees share
-   `federal_marginal_rate`: Marginal federal tax rate
-   `state_marginal_rate`: Marginal state tax rate, if a state was
    identified
-   `fica_rate`: FICA rate

## Input

`.data` is the only parameter for `taxsim_calculate_taxes()`. It is a
data frame containing the information used to calculate taxes. Column
names must match the names below.

### Required columns

The following columns are required:

-   `id_number` An arbitrary, non-negative, **integer**. This number
    links the results from TAXSIM 32 to the original data frame with
    entries.

-   `tax_year` Tax year ending Dec 31 (4 digits between 1960 and 2023).
    State must be zero if year is before 1977 or after 2023.

-   `filing_status` Filing status of tax unit. One of the following:
    “single” for single; “married, jointly” for married, filing jointly;
    “married, separately” for married, filing separately; “dependent
    child” for dependent, usually a child with income; or “head of
    household” for head of household filing status.

### Optional columns

Optional columns can be found in the help documentation of
`taxsim_calculate_taxes()` under the section `Optional columns`. Use
`?taxsim_calculate_taxes` to access the help documentation.

## Giving credit

The NBER’s [TAXSIM 32](https://users.nber.org/~taxsim/taxsim32/) tax
simulator does all tax calculations. This package simply lets users
interact with the tax simulator through R. Therefore, users should cite
the TAXSIM 32 tax simulator when they use this package in their work:

          Feenberg, Daniel Richard, and Elizabeth Coutts, An
Introduction to the TAXSIM Model, Journal of Policy Analysis and
Management vol 12 no 1, Winter 1993, pages 189-194.
