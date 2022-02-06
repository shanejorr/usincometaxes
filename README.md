
<!-- README.md is generated from README.Rmd. Please edit that file -->
<!-- badges: start -->
<!-- badges: end -->

## Calculate Federal and State Income Taxes

`usincometaxes` is an R package that calculates federal and state income
taxes in the United States. It relies on the National Bureau of Economic
Research’s (NBER) [TAXSIM 32](http://taxsim.nber.org/taxsim32/) tax
simulator for calculations. The package takes care of the
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
  id_number = c(1, 2),
  state = c('North Carolina', 'NY'),
  tax_year = c(2015, 2020),
  filing_status = c('single', 'married, jointly'),
  primary_wages = c(50000, 100000),
  primary_age = c(26, 36)
)

family_taxes <- taxsim_calculate_taxes(
  .data = family_income,
  marginal_tax_rates = 'Wages',
  return_all_information = FALSE
)
```

``` r
kable(family_taxes)
```

| id\_number | federal\_taxes | state\_taxes | fica\_taxes | federal\_marginal\_rate | state\_marginal\_rate | fica\_rate |
|-----------:|---------------:|-------------:|------------:|------------------------:|----------------------:|-----------:|
|          1 |        5718.75 |      2443.75 |        7650 |                      25 |                  5.75 |         15 |
|          2 |        5029.00 |      4586.76 |       15300 |                      12 |                  6.09 |         15 |

Users can use the `id_number` column to join the tax data with the
original data set. Every `id_number` in the input data is represented in
the output tax data.

``` r
family_income %>%
  left_join(family_taxes, by = 'id_number') %>%
  kable()
```

| id\_number | state          | tax\_year | filing\_status   | primary\_wages | primary\_age | federal\_taxes | state\_taxes | fica\_taxes | federal\_marginal\_rate | state\_marginal\_rate | fica\_rate |
|-----------:|:---------------|----------:|:-----------------|---------------:|-------------:|---------------:|-------------:|------------:|------------------------:|----------------------:|-----------:|
|          1 | North Carolina |      2015 | single           |          5e+04 |           26 |        5718.75 |      2443.75 |        7650 |                      25 |                  5.75 |         15 |
|          2 | NY             |      2020 | married, jointly |          1e+05 |           36 |        5029.00 |      4586.76 |       15300 |                      12 |                  6.09 |         15 |

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

## Marginal tax rates

By default, marginal tax rates are calculated using wages. The default
can be changed with the `return_all_information` parameter to
`taxsim_calculate_taxes()`. Possible options are: ‘Wages’ (default),
‘Long Term Capital Gains’, ‘Primary Wage Earner’, or ‘Secondary Wage
Earner’.

Go to the Marginal Tax Rates section of the [TAXSIM 32
documentation](https://users.nber.org/~taxsim/taxsim32/) for more
information.

## Giving credit

The NBER’s [TAXSIM 32](http://taxsim.nber.org/taxsim32/) tax simulator
does all tax calculations. This package simply lets users interact with
the tax simulator through R. Therefore, users should cite the TAXSIM 35
tax simulator when they use this package in their work:

          Feenberg, Daniel Richard, and Elizabeth Coutts, An
Introduction to the TAXSIM Model, Journal of Policy Analysis and
Management vol 12 no 1, Winter 1993, pages 189-194.
