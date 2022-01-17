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

to_taxsim_filename <- 'test_to_taxsim.csv'

to_taxsim_tmp_filename <- tempfile(fileext = ".csv")
vroom_write(taxsim_input, to_taxsim_tmp_filename, ",", progress = FALSE)

vroom(to_taxsim_tmp_filename)


family_income <- data.frame(
  id_number = as.integer(c(1, 2)),
  state = c('North Carolina', 'NY'),
  tax_year = c(2015, 2020),
  filing_status = c('single', 'married, jointly'),
  primary_wages = c(10000, 100000),
  primary_age = c(26, 36)
)

# 1) The ssh login is "taxsim35" rather than "taxsim32". Logins are accepted at ports 22, 80 and 443.
# I would suggest defaulting to 80 or 443 as they are less likely to be firewalled.

taxsim_calculate_taxes(
  .data = family_income,
  return_all_information = FALSE,
  upload_method = 'ftp'
)

test_ssh <- 'ssh -q -o "BatchMode=yes" user@host "echo 2>&1" && echo "UP" || echo "DOWN"'
system(taxsim_ssh_command)

from_taxsim_filename <- 'test_from_taxsim.csv'


ssh_cmd <- paste0("ssh -T -o ConnectTimeout=10 -o StrictHostKeyChecking=no -p 443 taxsim35@taxsimssh.nber.org < ",
                  to_taxsim_tmp_filename, " > ", from_taxsim_filename)
Sys.which('ssh')
shell(ssh_cmd)

# ftp

taxsim_user <- 'taxsim'
taxsim_pass <- '02138'
taxsim_user_pass <- paste0(taxsim_user, ":", taxsim_pass)

# create random filename to upload to server
fake_taxsim_filename <- sample(letters, 10, replace = T)
fake_taxsim_filename <- paste(fake_taxsim_filename, collapse = "")
fake_taxsim_filename <- paste0("ftp://", taxsim_user_pass, "@taxsimftp.nber.org/tmp/", fake_taxsim_filename)

RCurl::ftpUpload(
  what = to_taxsim_tmp_filename,
  to = fake_taxsim_filename
)

paste0("curl -u taxsim:02138 -T ", to_taxsim_filename, " ftp://taxsimftp.nber.org/tmp/shane")
"curl -u taxsim:02138 ftp://taxsimftp.nber.org/tmp/shane.txm35"

# http
paste0('curl -F txpydata.raw=@txpydata.raw "https://wwwdev.nber.org/uptest/webfile.cgi"')

# download data set containing tax values from taxsim server
# store data in temp folder

# FTP url to download results
taxsim_server_url <- paste0(fake_taxsim_filename, ".txm32")

from_taxsim_curl <- RCurl::getURL(taxsim_server_url, userpwd = taxsim_user_pass, connecttimeout = 120)

from_taxsim <- vroom::vroom(
  from_taxsim_curl, trim_ws = TRUE, show_col_types = FALSE, progress = FALSE
)


#############################################3

to_taxsim <- create_dataset_for_taxsim(family_income)

from_taxsim_curl <- 'test_from_taxsim.csv'

readr::write_csv(to_taxsim, to_taxsim_filename)

session <- ssh_connect("taxsim35@taxsimssh.nber.org:80", verbose = 2)

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

