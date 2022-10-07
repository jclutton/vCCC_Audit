#' @title Load Data
#'
#' @author Jon Clutton
#'
#' @name load_data
#'
#' @include master_script.R
#'
#' @description
#' This script loads and aggregates all data for the project.
#' Data are stored in base_dir/data
#' There are three directories in the data folder
#' 1) codebooks - store all excel sheets. These are updated by the study team
#' 2) redcap - the redcap project will be exported to this folder
#' 3) output - any output data will be stored in the output folder \cr \cr
#'
#' @section Development:
#' 5.9.22 Began development. JC \cr
#' 5.10.22 Initial build complete. JC \cr
#'
message("Began load_data")
##### Upload Codebooks #####
redcap_dictionary <- import(file.path(data_dir,'codebooks','VCCCMonitoring_DataDictionary.csv'))

emails <- import(file.path(data_dir,'codebooks','emails.xlsx'))

####### Upload REDCap data #####
redcap <- import(file.path(data_dir,'redcap','VCCCMonitoring.csv'))



