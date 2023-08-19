
<!-- README.md is generated from README.Rmd. Please edit that file -->
<!-- badges: start -->
<!-- badges: end -->

## Calculate Federal and State Income Taxes

`usincometaxes` is an R package that calculates federal and state income
taxes in the United States. It relies on the National Bureau of Economic
Research’s (NBER) [TAXSIM 35](http://taxsim.nber.org/taxsim35/) tax
simulator for calculations. The package takes care of the
behind-the-scenes work of getting the data in the proper format,
converting it to the proper file type for uploading to the NBER server,
uploading the data, downloading the results, and placing the results
into a tidy data frame.

*NOTE: This package is not associated with the NBER. It is a private
creation that uses their wonderful tax calculator.*

## Installation

You can install `usincometaxes` from CRAN:

``` r
install.packages('usincometaxes')
```

## Quick example

`usincometaxes` helps users estimate household income taxes from data
sets containing financial and household data. This allows users to
estimate income taxes from surveys with financial information, as the
United States Census Public Use Micro Data (PUMS).

The short example below uses `taxsim_calculate_taxes()` to calculate
income taxes.

``` r
library(dplyr)
library(knitr)
library(usincometaxes)

family_income <- data.frame(
  taxsimid = c(1, 2),
  state = c('North Carolina', 'NY'),
  year = c(2015, 2020),
  mstat = c('married, jointly', 'single'),
  pwages = c(50000, 100000), # primary wages
  page = c(26, 36) # primary age
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

| taxsimid |  fiitax |  siitax |  fica | frate | srate | ficar | tfica |
|---------:|--------:|--------:|------:|------:|------:|------:|------:|
|        1 |  3487.5 | 2012.50 |  7650 |    15 |  5.75 |  15.3 |  3825 |
|        2 | 15103.5 | 5377.86 | 15300 |    24 |  6.41 |  15.3 |  7650 |

Users can use the `taxsimid` column to join the tax data with the
original data set. Every `taxsimid` in the input data is represented in
the output tax data.

``` r
family_income %>%
  left_join(family_taxes, by = 'taxsimid') %>%
  kable()
```

| taxsimid | state          | year | mstat            | pwages | page |  fiitax |  siitax |  fica | frate | srate | ficar | tfica |
|---------:|:---------------|-----:|:-----------------|-------:|-----:|--------:|--------:|------:|------:|------:|------:|------:|
|        1 | North Carolina | 2015 | married, jointly |  50000 |   26 |  3487.5 | 2012.50 |  7650 |    15 |  5.75 |  15.3 |  3825 |
|        2 | NY             | 2020 | single           | 100000 |   36 | 15103.5 | 5377.86 | 15300 |    24 |  6.41 |  15.3 |  7650 |

## Output

`taxsim_calculate_taxes()` returns a data frame where each row
corresponds to a row in `.data` and each column is a piece of tax
information. The output and `.data` can be linked by the `taxsimid`
column.

The amount of output (tax information) received is controlled by the
`return_all_information` parameter to `taxsim_calculate_taxes()`.
Setting `return_all_information` to `FALSE` returns minimal information
such as federal and state tax liabilities and FICA taxes. When
`return_all_information` is `TRUE` 44 different tax items are returned.

`usoncometax`’s output contains the same information and column names as
[TAXSIM 35](http://taxsim.nber.org/taxsim35/). Therefore, please consult
either the [Description of Output Columns
vignette](https://www.shaneorr.io/r/usincometaxes/articles/taxsim-output.html)
or [TAXSIM 35 documentation](http://taxsim.nber.org/taxsim35/) for more
output information.

``` r
family_taxes_full_output <- taxsim_calculate_taxes(
  .data = family_income,
  marginal_tax_rates = 'Wages',
  return_all_information = TRUE
)

kable(family_taxes_full_output)
```

| taxsimid |  fiitax |  siitax |  fica | frate | srate | ficar | tfica | credits | v10_federal_agi | v11_ui_agi | v12_soc_sec_agi | v13_zero_bracket_amount | v14_personal_exemptions | v15_exemption_phaseout | v16_deduction_phaseout | v17_itemized_deductions | v18_federal_taxable_income | v19_tax_on_taxable_income | v20_exemption_surtax | v21_general_tax_credit | v22_child_tax_credit_adjusted | v23_child_tax_credit_refundable | v24_child_care_credit | v25_eitc | v26_amt_income | v27_amt_liability | v28_fed_income_tax_before_credit | v29_fica | v30_state_household_income | v31_state_rent_expense | v32_state_agi | v33_state_exemption_amount | v34_state_std_deduction_amount | v35_state_itemized_deduction | v36_state_taxable_income | v37_state_property_tax_credit | v38_state_child_care_credit | v39_state_eitc | v40_state_total_credits | v41_state_bracket_rate | staxbc | v42_self_emp_income | v43_medicare_tax_unearned_income | v44_medicare_tax_earned_income | v45_cares_recovery_rebate |
|---------:|--------:|--------:|------:|------:|------:|------:|------:|--------:|----------------:|-----------:|----------------:|------------------------:|------------------------:|-----------------------:|-----------------------:|------------------------:|---------------------------:|--------------------------:|---------------------:|-----------------------:|------------------------------:|--------------------------------:|----------------------:|---------:|---------------:|------------------:|---------------------------------:|---------:|---------------------------:|-----------------------:|--------------:|---------------------------:|-------------------------------:|-----------------------------:|-------------------------:|------------------------------:|----------------------------:|---------------:|------------------------:|-----------------------:|-------:|--------------------:|---------------------------------:|-------------------------------:|--------------------------:|
|        1 |  3487.5 | 2012.50 |  7650 |    15 |  5.75 |  15.3 |  3825 |       0 |           50000 |          0 |               0 |                   12600 |                    8000 |                      0 |                      0 |                       0 |                      29400 |                    3487.5 |                    0 |                      0 |                             0 |                               0 |                     0 |        0 |          50000 |                 0 |                           3487.5 |     7650 |                   50000.01 |                      0 |      50000.01 |                          0 |                          15000 |                            0 |                 35000.01 |                             0 |                           0 |              0 |                       0 |                   0.00 |      0 |                   0 |                                0 |                              0 |                         0 |
|        2 | 15103.5 | 5377.86 | 15300 |    24 |  6.41 |  15.3 |  7650 |       0 |          100000 |          0 |               0 |                   12400 |                       0 |                      0 |                      0 |                       0 |                      87600 |                   15103.5 |                    0 |                      0 |                             0 |                               0 |                     0 |        0 |         100000 |                 0 |                          15103.5 |    15300 |                  100001.01 |                      0 |     100000.01 |                          0 |                           8000 |                            0 |                 92000.01 |                             0 |                           0 |              0 |                       0 |                   6.41 |      0 |                   0 |                                0 |                              0 |                         0 |

## Input

Taxes are calculated with `taxsim_calculate_taxes()` using the financial
and household characteristics found in the data frame represented by the
`.data` parameter. Each column is a different piece of information and
each row contains a tax payer unit.

All columns must have the column names and data types listed in the
[Description of Input
Columns](https://www.shaneorr.io/r/usincometaxes/articles/taxsim-input.html)
vignette. These are the same column names found in the [TAXSIM
35](http://taxsim.nber.org/taxsim35/) documentation. Therefore, you can
consult the package documentation or TAXSIM 35 documentation for more
information on input columns. There are two differences between
`usincometaxes` and TAXSIM 35:

1.  `usincometaxes` allows users to specify the state with either the
    two letter abbreviation or [state SOI
    code](https://taxsim.nber.org/statesoi.html). `usincometaxes` will
    convert the abbreviation to an SOI code for TAXSIM 35.
2.  For filing status, `mstat`, users can either use the TAXSIM 35
    integer found in TAXSIM 35’s documentation or one of the following
    descriptions:
    - “single” or 1 for single;
    - “married, jointly” or 2 for married, filing jointly;
    - “married, separately” or 6 for married, filing separately;
    - “dependent child” or 8 for dependent, usually a child with income;
      or
    - “head of household” or 1 for head of household filing status.

The input data frame, `.data`, can contain columns beyond those listed
in the vignette. The additional columns will be ignored.

## Marginal tax rates

By default, marginal tax rates are calculated using wages. The default
can be changed with the `marginal_tax_rates` parameter to
`taxsim_calculate_taxes()`. Possible options are: ‘Wages’ (default),
‘Long Term Capital Gains’, ‘Primary Wage Earner’, or ‘Secondary Wage
Earner’.

## Giving credit

The NBER’s [TAXSIM 35](http://taxsim.nber.org/taxsim35/) tax simulator
does all tax calculations. This package simply lets users interact with
the tax simulator through R. Therefore, users should cite the TAXSIM 35
tax simulator when they use this package in their work:

          Feenberg, Daniel Richard, and Elizabeth Coutts, An
Introduction to the TAXSIM Model, Journal of Policy Analysis and
Management vol 12 no 1, Winter 1993, pages 189-194.

Aman Gupta Karmani created the [WebAssembly / JavaScript
files](https://github.com/tmm1/taxsim.js). These files also power his
tax calculator web app at [taxsim.app](https://taxsim.app).
