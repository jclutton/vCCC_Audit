#' @title send_monitor_email
#'
#' @author Jon Clutton
#'
#' @name send_monitor_email
#'
#' @include load_data.R
#'
#' @description
#' An html table is created as the body of the email and written to modules/send_monitor_email_module. The email is sent using
#' python. To change senders or recipients of the email, change manually within the python script found here - modules/send_monitor_email_module/send_email.py \cr
#' The purpose of this script is to send the study monitor a review of all ongoing open inquiries in the vCCC monitoring project
#'
#'
#' @section Development:
#' 10.5.22 Began development. JC \cr





message("Began send_monitor_email")
##### Html Table function #####
html_table_generator <- function(table = NULL){

  if(nrow(table) == 0) {
    '
        <p style= "font-size:100%;"> <b><i>Congrats! You have no open inquiries.</b></i>  </p>
'
  } else {

    table %>%
      htmlTable::addHtmlTableStyle(align = "c",
                                   col.rgroup = c("none", "#F7F7F7"),
                                   css.cell = "height: 10px; padding: 5 px",
                                   css.table = "border-collapse: separate; border-spacing: 5px 0") %>%
      htmlTable::htmlTable(.,rnames = F)
  }
}

#### Set module directory ####
this_module_dir <- file.path(module_dir,'send_monitor_email_module')

##### Open Audits #####
tcog_audits <- redcap %>%
  filter(redcap_repeat_instrument == "t_cog_audit_tracker") %>%
  select(record_id, redcap_repeat_instance, rater_id_tcog, contains("cog__")) %>%
  pivot_longer(contains("cog__")) %>%
  mutate(number = str_sub(name, start = -1)) %>%
  mutate(test = str_sub(name, end = -5)) %>%
  select(-name) %>%
  pivot_wider(id = c("record_id", "redcap_repeat_instance", "rater_id_tcog","test"),
              names_from = "number",
              values_from = "value") %>%
  filter(`2` == 1) %>%
  filter(`7` == 0) %>%
  mutate(Status = case_when(`6` == 0 & `7` == 0 ~ "Review Required",
                            `6` == 0 & `7` == 1 ~ "Likely Error, Please Check",
                            `6` == 0  ~ "Waiting on Monitor")) %>%
  arrange(Status)

visit_tracker_audits <- redcap %>%
  filter(redcap_repeat_instrument == "visit_tracker") %>%
  filter(visit_monitoring_status___1 == 1 & visit_monitoring_status___3 != 1) %>%
  mutate(Status = case_when(visit_monitoring_status___2 == 0 ~ "Review Required",
                            visit_monitoring_status___2 == 1 ~ "Waiting on Monitor")) %>%
  select(record_id, visit_coordinator, redcap_repeat_instance, Status)


##### Make monitor email ####
fname <- monitor_fname
lname <- monitor_lname

#### Tcog Audits for monitor ####
tcog_audit_requiring_response <- tcog_audits %>%
  filter(Status == "Waiting on Monitor" | Status == "Likely Error, Please Check") %>%
  select(record_id, redcap_repeat_instance, test, Status) %>%
  rename("Repeat Instance" = redcap_repeat_instance, "Test" = test)

openxlsx::write.xlsx(tcog_audit_requiring_response, file = file.path(output_dir,paste0('monitor_tcog_',fname,'_',lname,'.xlsx')), overwrite = TRUE)

#### Visit Tracker Audits for current rater ####
visit_tracker_requiring_response <- visit_tracker_audits %>%
  filter(Status == "Waiting on Monitor") %>%
  select(-visit_coordinator) %>%
  rename("Repeat Instance" = redcap_repeat_instance)

openxlsx::write.xlsx(visit_tracker_requiring_response, file = file.path(output_dir,paste0('monitor_visit_tracker_',fname,'_',lname,'.xlsx')), overwrite = TRUE)

#### Tcog Audits open ####
tcog_open <- tcog_audits %>%
  filter(Status == "Review Required") %>%
  left_join(., emails, by = c("rater_id_tcog"="redcap_id")) %>%
  select(record_id, redcap_repeat_instance, rater, test, Status) %>%
  rename("Repeat Instance" = redcap_repeat_instance, "Test" = test) %>%
  arrange(rater)

#### Visit Tracker Audits Open ####
visit_tracker_open <- visit_tracker_audits %>%
  filter(Status == "Review Required") %>%
  left_join(., emails, by = c("visit_coordinator"="redcap_id")) %>%
  select(record_id, redcap_repeat_instance, rater, Status) %>%
  rename("Repeat Instance" = redcap_repeat_instance) %>%
  arrange(rater)


##### Create body of email in HTML #####
## Base 64 encode adrc logo so that it can be saved in emails
adrc_logo <- RCurl::base64Encode(readBin(file.path(module_dir,"send_staff_time_email_module","adrc_logo.jpg"), "raw", file.info(file.path(module_dir,"send_staff_time_email_module","adrc_logo.jpg"))[1, "size"]), "adrc_logo")
adrc_logo_html <- sprintf('<img src="data:image/png;base64,%s">', adrc_logo)

body <- paste0('<!DOCTYPE html>
                <table align="center" border="0" cellpadding="0" cellspacing="0" width="600">
                  <tr>
                    <td align="center" style="padding: 40px 0 35px 0;">
                    ',adrc_logo_html,'
                    </td>
                  </tr>
                 <tr>
                  <td align="left" style="padding: 10px 0px 35px 0px;">
                    <p style=style= "font-size:100%;">Hi ',fname,',
                    <br><br>This is your weekly monitor report for vCCC.
                    You have ',nrow(tcog_audit_requiring_response),' T-Cog and ',nrow(visit_tracker_requiring_response),' Visit inquiries requiring your response.
                    There are ',nrow(visit_tracker_open) + nrow(tcog_open),' inquiries awaiting rater responses.
                    <br><br> Feel free to respond to this email if you have any questions or feedback. </p>
                  </td>
                 </tr>
                 <tr>
                  <td align="center" style="padding: 5px 0 5px 0;">
                    <p style="font-family:arial;" style= "font-size:125%;"><b>vCCC T-Cog Inquiries Ready For Monitor Review as of ',format(today(), format = "%b., %d, %Y"),' </b></p>
                  </td>
                 </tr>
                 <tr>
                  <td align="center" style="padding: 0px 0 35px 0;">
                    ',html_table_generator(tcog_audit_requiring_response),'
                  </td>
                 </tr>
                                  </tr>
                 <tr>
                  <td align="center" style="padding: 5px 0 5px 0;">
                    <p style="font-family:arial;" style= "font-size:125%;"><b>vCCC Visit Inquiries Ready For Monitor Review as of ',format(today(), format = "%b., %d, %Y"),' </b></p>
                  </td>
                 </tr>
                 <tr>
                  <td align="center" style="padding: 0px 0 35px 0;">
                    ',html_table_generator(visit_tracker_requiring_response),'
                  </td>
                 </tr>
                                  <tr>
                  <td align="center" style="padding: 5px 0 5px 0;">
                    <p style="font-family:arial;" style= "font-size:125%;"><b>Open T-Cog Inquiries </b></p>
                  </td>
                 </tr>
                 <tr>
                  <td align="center" style="padding: 0px 0 35px 0;">
                    ',html_table_generator(tcog_open),'
                  </td>
                 </tr>
                                  </tr>
                 <tr>
                  <td align="center" style="padding: 5px 0 5px 0;">
                    <p style="font-family:arial;" style= "font-size:125%;"><b>Open Visit Inquiries</b></p>
                  </td>
                 </tr>
                 <tr>
                  <td align="center" style="padding: 0px 0 35px 0;">
                    ',html_table_generator(visit_tracker_open),'
                  </td>
                 </tr>
    ')

#### Most recent spread sheets ####
current_tcog_spreadsheet <- file.path(output_dir,paste0('monitor_tcog_',fname,'_',lname,'.xlsx'))
current_visit_spreadsheet <- file.path(output_dir,paste0('monitor_visit_tracker_',fname,'_',lname,'.xlsx'))



##### Mail presets #####

TO = "jclutton@kumc.edu"

##### Send to python to send email ######
cat(body, file = file.path(this_module_dir,"send_monitor_email.txt"))
mailcmd<-paste("py",
               file.path(this_module_dir,"send_email.py"),
               TO,
               file.path(this_module_dir,"send_monitor_email.txt"),
               current_tcog_spreadsheet,
               current_visit_spreadsheet,
               basename(current_tcog_spreadsheet),
               basename(current_visit_spreadsheet))

#Command to send email. no_email is a project wide variable set in masterscript
if(no_email == 0) {
  system(mailcmd)
}





