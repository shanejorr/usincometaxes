# create functions by hand to test

library(tidyverse)
library(vroom)
library(RCurl)
library(httr)
library(ssh)
library(glue)
#library(usincometaxes)

# testing -----------------------------------------

devtools::load_all()

taxsim_input <- data.frame(
  id_number = as.integer(1),
  filing_status = 'married, jointly',
  tax_year = 1970,
  long_term_capital_gains = 100000
) %>%
  create_dataset_for_taxsim()

write_csv(taxsim_input, "test_main.csv")


family_income <- data.frame(
  id_number = as.integer(c(1, 2)),
  state = c('North Carolina', 'NY'),
  tax_year = c(2015, 2020),
  filing_status = c('single', 'married, jointly'),
  primary_wages = c(10000, 100000),
  primary_age = c(26, 36)
)

taxsim_calculate_taxes(
  .data = family_income,
  return_all_information = FALSE,
  upload_method = 'ftp'
)

test_ssh <- 'ssh -q -o "BatchMode=yes" user@host "echo 2>&1" && echo "UP" || echo "DOWN"'
system(taxsim_ssh_command)

to_taxsim_filename <- 'test_to_taxsim.csv'

taxsim_ssh_command <- paste0("ssh -T -o StrictHostKeyChecking=no taxsimssh@taxsimssh.nber.org <", to_taxsim_filename)

to_taxsim <- create_dataset_for_taxsim(family_income)

from_taxsim_curl <- 'test_from_taxsim.csv'

readr::write_csv(to_taxsim, to_taxsim_filename)

session <- ssh_connect("taxsimssh@taxsimssh.nber.org", verbose = 2)

scp_upload(session, to_taxsim_filename)


ssh_command <- paste0("ssh -T -o ConnectTimeout=10 -o StrictHostKeyChecking=no taxsimssh@taxsimssh.nber.org < ",
                      to_taxsim_filename, " > ", from_taxsim_curl)

system(ssh_command)

scp(
  host = 'taxsimssh.nber.org',
  user = 'taxsimssh'
)

#############################

taxsim_http_command <- paste0('curl -F txpydata.raw=@',to_taxsim_filename, ' "https://wwwdev.nber.org/uptest/webfile.cgi" > "test_http.csv"')
system(taxsim_http_command)


POST(
  "https://wwwdev.nber.org/uptest/webfile.cgi",
    body = list(
      # send the file with mime type `"application/rds"` so the RDS parser is used
      txpydata.raw = upload_file('test_main.csv', 'application/csv')
    )
  ) %>%
  content(as = 'text', type = 'application/csv')

