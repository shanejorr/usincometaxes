# create functions by hand to test

library(tidyverse)
library(curl)
library(glue)
library(usincometaxes)

# testing -----------------------------------------

source("R/calculate_taxes.R")
source("R/custom_names.R")
source("R/helper_check_data.R")
source("R/helper_clean_data.R")
source("R/helper_recode_data.R")
load("R/sysdata.rda")

.data <- data.frame(
  id_number = as.integer(c(1, 2)),
  state = c('North Carolina', 'NY'),
  tax_year = c(2015, 2015),
  filing_status = c('single', 'married, jointly'),
  primary_wages = c(10000, 100000),
  primary_age = c(26, 36)
)

test_data <- create_dataset_for_taxsim(.data)

taxes <- taxsim_calculate_taxes(.data)

merge(.data, taxes, by = 'id_number')
###

.data <- create_dataset_for_taxsim(.data)

cols <- colnames(.data)
check_data(.data, cols, 'state')

# send to taxsim --------------------------------------------

required_variables <- c('taxsimid', 'mstat', 'year')

to_taxsim <- data.frame(
  taxsimid = rep(1, n),
  mstat = rep(2, n),
  year = rep(20, n),
  ltcg = rep(100000, n)
)

test_answer = 16700.04

to_taxsim[] <- lapply(to_taxsim, round, digits = 0)
to_taxsim[] <- lapply(to_taxsim, as.integer)

#to_taxsim_filename <- 'to_taxsim.csv'

to_taxsim_tmp_filename <- tempfile("to_taxsim_")
utils::write.csv(to_taxsim, to_taxsim_tmp_filename, row.names = FALSE)
read.csv(to_taxsim_tmp_filename)

#write.csv(tax_df, to_taxsim_filename, row.names = FALSE)
#read.csv(to_taxsim_filename)

# random filename to uplaod to server
fake_taxsim_filename <- sample(letters, 10, replace = T)
fake_taxsim_filename <- paste(fake_taxsim_filename, collapse = "")
fake_taxsim_filename <- paste0("ftp://taxsim:02138@taxsimftp.nber.org/tmp/", fake_taxsim_filename)

RCurl::ftpUpload(
  what = to_taxsim_tmp_filename,
  to = fake_taxsim_filename
)

# FTP url to download results
taxsim_server_url <- paste0(fake_taxsim_filename, ".txm32")

from_taxsim_curl <- RCurl::getURL(taxsim_server_url, userpwd = "taxsim:02138", connecttimeout = 60)
from_taxsim <- read.csv(text = from_taxsim_curl)
