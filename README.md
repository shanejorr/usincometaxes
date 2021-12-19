
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

`usincometaxes` helps users estimate household income taxes from data
sets containing financial and household data. This allows users to
estimate income taxes from surveys with financial information, as the
United States Census Public Use Micro Data (PUMS).

`usincometaxes` contains one function: `taxsim_calculate_taxes()`. Below
is a simple example of its use.

``` r
library(dplyr)
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

family_taxes <- taxsim_calculate_taxes(
  .data = family_income,
  return_all_information = FALSE,
  upload_method = 'ftp'
)
#> [1] "All required columns are present and the data is in the proper format!"
#> [1] "Uploading data to TAXSIM server via ftp."
#> [1] "Downloading data from TAXSIM server via ftp."
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

`taxsim_calculate_taxes()` returns a data frame where each row
corresponds to a row in `.data` and each column is a piece of tax
information. The output and `.data` can be linked by the `id_number`
column.

The amount of output (tax information) received is controlled by the
`return_all_information` parameter to `taxsim_calculate_taxes()`.
Setting `return_all_information` to `FALSE` returns minimal information
such as federal and state tax liabilities and FICA taxes. When
`return_all_information` is `TRUE` 45 different tax items are returned.

See the [Description of Output
Columns](https://www.shaneorr.io/r/usincometaxes/articles/taxsim-output.html)
vignette for output information.

## Input

Taxes are calculated with `taxsim_calculate_taxes()` using the financial
and household characteristics found in the data frame represented by the
`.data` parameter. Each column is a different piece of information and
each row contains a tax payer unit.

All columns must have the column names and data types listed in the
[Description of Input
Columns](https://www.shaneorr.io/r/usincometaxes/articles/taxsim-input.html)
vignette. `.data` can contain columns beyond those listed in the
vignette. The additional columns will be ignored.

## Upload and download method

FTP or SSH can be used to upload and retrieve information to and from
the TAXSIM server. This is set with the `upload_method` parameter to
`taxsim_calculate_taxes()` and defaults to FTP. Behind the scenes, FTP
uses the `RCurl` package and SSH issues an SSH command to the operating
system. Large data sets should sue SSH since it is faster.

## Giving credit

The NBER’s [TAXSIM 32](https://users.nber.org/~taxsim/taxsim32/) tax
simulator does all tax calculations. This package simply lets users
interact with the tax simulator through R. Therefore, users should cite
the TAXSIM 32 tax simulator when they use this package in their work:

          Feenberg, Daniel Richard, and Elizabeth Coutts, An
Introduction to the TAXSIM Model, Journal of Policy Analysis and
Management vol 12 no 1, Winter 1993, pages 189-194.
