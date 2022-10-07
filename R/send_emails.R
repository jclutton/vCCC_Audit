#' @title send_emails
#'
#' @author Jon Clutton
#'
#' @name send_emails
#'
#' @include load_data.R
#'
#' @description
#' An html table is created as the body of the email and written to modules/send_staff_time_email_module. The email is sent using
#' python. To change senders or recipients of the email, change manually within the python script found here - modules/send_staff_time_email_module/send_email.py \cr
#' The purpose of this script is to send individual emails to all raters in the vCCC project
#'
#'
#' @section Development:
#' 9.27.22 Began development. JC \cr
#' 9.27.22 Initial build complete. JC \cr


message("Began send_staff_time_email")
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


##### Make each email ####
for(i in 1:nrow(emails)){
  current <- emails$redcap_id[i]
  fname <- emails$fname[i]
  lname <- emails$lname[i]

  #### Tcog Audits for current rater ####
  current_open_audits <- tcog_audits %>%
    filter(rater_id_tcog == current) %>%
    select(record_id, redcap_repeat_instance, test, Status) %>%
    rename("Repeat Instance" = redcap_repeat_instance, "Test" = test)

  openxlsx::write.xlsx(current_open_audits, file = file.path(output_dir,paste0('tcog_audits_',fname,'_',lname,'.xlsx')), overwrite = TRUE)

  #### Visit Tracker Audits for current rater ####
  current_open_visit_tracker_audits <- visit_tracker_audits %>%
    filter(visit_coordinator == current) %>%
    select(-visit_coordinator) %>%
    rename("Repeat Instance" = redcap_repeat_instance)

  openxlsx::write.xlsx(current_open_visit_tracker_audits, file = file.path(output_dir,paste0('visit_tracker_audits_',fname,'_',lname,'.xlsx')), overwrite = TRUE)


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
                    <br><br>Welcome to the vCCC Auditing Project. Tests with potential errors will be shown below as well as in the attached spreadsheet.
                    You have ',sum(current_open_audits$Status == "Review Required"),' T-Cog inquiries and ',sum(current_open_visit_tracker_audits$Status == "Review Required"),' Visit inquiries requiring your attention.
                    <br><br> Feel free to respond to this email if you have any questions or feedback. </p>
                  </td>
                 </tr>
                 <tr>
                  <td align="center" style="padding: 5px 0 5px 0;">
                    <p style="font-family:arial;" style= "font-size:125%;"><b>Open vCCC T-Cog Inquiries as of ',format(today(), format = "%b., %d, %Y"),' </b></p>
                  </td>
                 </tr>
                 <tr>
                  <td align="center" style="padding: 0px 0 35px 0;">
                    ',html_table_generator(current_open_audits),'
                  </td>
                 </tr>
                                  </tr>
                 <tr>
                  <td align="center" style="padding: 5px 0 5px 0;">
                    <p style="font-family:arial;" style= "font-size:125%;"><b>Open vCCC Visit Inquiries as of ',format(today(), format = "%b., %d, %Y"),' </b></p>
                  </td>
                 </tr>
                 <tr>
                  <td align="center" style="padding: 0px 0 35px 0;">
                    ',html_table_generator(current_open_visit_tracker_audits),'
                  </td>
                 </tr>
    ')

  #### Most recent spread sheets ####
 current_tcog_spreadsheet <- file.path(output_dir,paste0('tcog_audits_',fname,'_',lname,'.xlsx'))
 current_visit_spreadsheet <- file.path(output_dir,paste0('visit_tracker_audits_',fname,'_',lname,'.xlsx'))



  ##### Mail presets #####

  TO = "jclutton@kumc.edu"

  ##### Send to python to send email ######
  cat(body, file = file.path(module_dir,"send_staff_time_email_module","send_staff_time_email.txt"))
  mailcmd<-paste("py",
                 file.path(module_dir,"send_staff_time_email_module","send_email.py"),
                 TO,
                 file.path(module_dir,"send_staff_time_email_module","send_staff_time_email.txt"),
                 current_tcog_spreadsheet,
                 current_visit_spreadsheet,
                 basename(current_tcog_spreadsheet),
                 basename(current_visit_spreadsheet))

  #Command to send email. no_email is a project wide variable set in masterscript
  if(no_email == 0 & current < 100) {
    system(mailcmd)
  }



}

