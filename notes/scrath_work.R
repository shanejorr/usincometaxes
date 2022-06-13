# This file is a scratch pad to try random stuff. It is not included in the package build.

library(tidyverse)
library(vroom)
library(RCurl)
library(httr)
library(ssh)
library(glue)
library(usincometaxes)

# STOP 993 (data is of wrong type )
# STOP 901 (extra column that is not a column)

# testing -----------------------------------------

devtools::load_all()

taxsim_input <- data.frame(
  taxsimid = c(1,2),
  mstat = 2,
  year = 1970,
  state = c('NC', 'NC'),
  ltcg = 100000
)

a <- create_dataset_for_taxsim(taxsim_input)

df <- taxsim_calculate_taxes(taxsim_input, return_all_information = T, interface = "http")

to_taxsim_tmp_filename <- 'notes/to_taxsim.csv'
from_taxsim_tmp_filename <- 'notes/from_taxsim.csv'
std_error_filename <- 'notes/stderror.txt'
known_hosts_file <- 'notes/known_hosts'

vroom::vroom_write(taxsim_input, to_taxsim_tmp_filename, ",", progress = FALSE)

connect_server_single_ssh(to_taxsim_tmp_filename, from_taxsim_tmp_filename, std_error_filename, known_hosts_file)

import_data_helper(from_taxsim_tmp_filename, idtl = 0)

import_data_ssh(to_taxsim_tmp_filename, from_taxsim_tmp_filename, std_error_filename, known_hosts_file, 0)

# ssh -T -o ConnectTimeout=20 -o UserKnownHostsFile='a.txt' -o StrictHostKeyChecking=no -p 22 taxsim35@taxsimssh.nber.org < notes/to_taxsim.csv 1> notes/from_taxsim.csv 2> notes/error.txt

'curl -F notes/from_taxsim.csv=@notes/to_taxsim.csv "https://wwwdev.nber.org/uptest/webfile.cgi"'

session <- ssh_connect("taxsim35@taxsimssh.nber.org")

connect_server_single_ssh(to_taxsim_tmp_filename, from_taxsim_filename, '443')

ssh_cmd <- paste0("ssh -T -o ConnectTimeout=10 -o StrictHostKeyChecking=no -p 22 taxsimssh@taxsimssh.nber.org < ",
                  to_taxsim_tmp_filename, " > ", from_taxsim_filename)

a <- system(ssh_cmd)

b <- processx::run(ssh_cmd, c('T', 'o', 'ConnectTimeout', '10', 'StrictHostKeyChecking', 'no',
                              'taxsimssh@taxsimssh.nber.org', '<', to_taxsim_tmp_filename))


px <- paste0(
  system.file(package = "processx", "bin", "px"),
  system.file(package = "processx", "bin", .Platform$r_arch, "px.exe")
)



# create random user id
user_id <- paste0(sample(letters, 10), collapse = "")

# username and password are publically listed, so we're not revealing private information
user_pwd <- 'taxsim:02138'

upload_address <- paste0("ftp://", user_pwd, "@taxsimftp.nber.org/tmp/", user_id, collapse = "")

download_address <- paste0("ftp://taxsimftp.nber.org/tmp/", user_id, ".txm35", collapse = "")

RCurl::ftpUpload(to_taxsim_tmp_filename, upload_address)

message('Data uploaded ...')

results <- RCurl::getURL(download_address, userpwd = user_pwd)

vroom(results)

#curl -u taxsim:02138 -T txpydata.csv ftp://taxsim:02138@taxsimftp.nber.org/tmp/mrdvxlukwaa
#curl -u taxsim:02138 ftp://taxsimftp.nber.org/tmp/mrdvxlukwaa.txm35

############

sample_data <- data.frame(taxsimid = 1,
                          mstat = 2,
                          year = 1970,
                          ltcg = 100000,
                          idtl = 2)

library(RCurl)
write.csv(sample_data, "./txpydata.csv", row.names = F, na="")
ftpUpload("./txpydata.csv", "ftp://taxsim:02138@taxsimftp.nber.org/tmp/userid")
results <- getURL("ftp://taxsimftp.nber.org/tmp/userid.txm35", userpwd =
                    "taxsim:02138")
taxsim_data <- read.csv(text = results)

######################

family_income <- data.frame(
  id_number = as.integer(c(1, 2)),
  state = c('North Carolina', 'NY'),
  tax_year = c(2020, 2020),
  filing_status = c('single', 'married, jointly'),
  primary_wages = c(10000, 15000),
  primary_age = c(26, 36),
  spouse_wages = c(0, 15000),
  spouse_age = c(0, 36),
  num_dependents = c(3,3),
  age_youngest_dependent = c(3,3),
  age_youngest_dependent = c(4,4),
  age_second_youngest_dependent= c(5,5)
)

family_taxes <- taxsim_calculate_taxes(
  .data = family_income,
  return_all_information = TRUE
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
Sys.which('ss') == ""
shell(ssh_cmd, shell = Sys.which('ssh'))

# check to see if ssh is installed on the local machine
# produce error message if it is not
if (Sys.which('ssh') == "") {
  stop("You do not have an SSH client installed on your computer. Please install SSH.\nUse Sys.which('ssh') to check if you have SSH installed.")
}

connect_server_all(to_taxsim_tmp_filename, from_taxsim_filename)

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
taxsim_server_url <- paste0(fake_taxsim_filename, ".txm35")

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

sample_data <- data.frame(
  taxsimid = 1,
  mstat = 2,
  year = 1970,
  ltcg = 100000,
  idtl = 2
)

to_taxsim_tmp_filename <- 'notes/to_taxsim.csv'
from_taxsim_tmp_filename <- 'notes/from_taxsim.csv'
std_error_filename <- 'notes/stderror.txt'

write_csv(taxsim_input, to_taxsim_tmp_filename, ",", progress = FALSE)

taxsim_http_command <- paste0(
  "curl -F txpydata.raw=@",to_taxsim_tmp_filename,
  " 'https://wwwdev.nber.org/uptest/webfile.cgi' 1> ", from_taxsim_tmp_filename,
  " 2> ", std_error_filename
)

system(taxsim_http_command)

read.csv(to_taxsim_filename)

POST(
  "https://wwwdev.nber.org/uptest/webfile.cgi",
    body = list(
      txpydata.raw = upload_file(to_taxsim_tmp_filename, 'application/csv')
    )
  ) %>%
  content(as = 'text', type = 'application/csv')

