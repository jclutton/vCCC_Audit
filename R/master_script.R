#' @title Master Script of vCCCAudit Project
#'
#' @author Jon Clutton
#'
#' @name master_script
#'
#' @description
#' This is the master script for vCCC_Audit.
#' It is written currently written to run manually. However, it is designed
#' to switch onto the shiny server.
#' Libraries, directories, and scripts to be run are all declared in this
#' script. The variable no_email can be changed to 1 to test the project and
#' stop emails.
#'
#' @section Instructions to Run:
#' Download the current REDCap database and save to data/redcap. \cr
#' Press Source \cr
#'
#' @section Directory Shortcuts:
#' base_dir - project level directory \cr
#' data_dir - data \cr
#' script_dir - R scripts \cr
#' module_dir - random python and .txt files associated with projects \cr
#' codebook_dir - within data_dir, codebooks \cr
#' output_dir - within data_dir, output data \cr
#'
#' @section Project Level Variables:
#' no_email - stops emails if set to any number other than 0 \cr
#' monitor_fname \cr
#' monitor_lname \cr
#' monitor_email \cr
#'
#' @section Development:
#' 9.27.22 Began Project JC \cr
#' 9.27.22 Initial build complete. JC \cr
#' 9.28.22 Reviewed with Heidi and Amber. Making changes to emails and REDCap. JC \cr
#' 10.7.22 Completing final testing and documenting. Plan to initiate next week. JC \cr


message("Began master_script")

##### Set Project Wide Variables #####
#Set to 1 when testing the project and don't want to send emails.
no_email <- 0
monitor_fname <- "Heidi"
monitor_lname <- "Anderson"
monitor_email <- "handerson8@kumc.edu"

##### Load Project Wide Libraries ####
if(all(grepl("tidyverse",(.packages()))==FALSE)){require(tidyverse)}
if(all(grepl("rio",(.packages()))==FALSE)){require(rio)}
if(all(grepl("lubridate",(.packages()))==FALSE)){require(lubridate)}

##### Directories #####
if(Sys.info()['user']=="vidon"){ #Eric's computer
  root <- file.path('Z:')
  user <- 'Eric'
} else if(Sys.info()['user']=="jclutton"){ #Jon's computer
  root <- file.path('P:')
  user <- 'Jon'
} else {
  error("This drive has not been set up yet.")
}

#Set the base directory for the project. All downstream directories should be build off this
base_dir <- file.path(root,'IRB_STUDY0011132_Cohort','ADC_Metrics','Temp','vCCCAudit')

#Set immediate downstream large project related directories
data_dir <- file.path(base_dir,'data')
script_dir <- file.path(base_dir,'R')
module_dir <- file.path(base_dir,'modules')

#Set smaller directories
codebook_dir <- file.path(data_dir,'codebooks')
output_dir <- file.path(data_dir,'output')

directories_to_save <- c('base_dir','script_dir','data_dir','module_dir','codebook_dir','output_dir')
save(list = directories_to_save, file = file.path(codebook_dir,'directories.Rdata'))

### Run Scripts #####
#Scripts to run
message("master_script run scripts")

#Daily Scripts
source(file.path(script_dir,'load_data.R'))

#Weekly Scripts - Run every Monday
if(wday(today()) == 2){
source(file.path(script_dir,'send_monitor_email.R'))
}

#Biweekly Scripts - Run Every other Monday
if(wday(today()) == 2 & week(today())%%2 == 0){
source(file.path(script_dir,'send_emails.R'))
}
