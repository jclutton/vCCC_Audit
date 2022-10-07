
#Python script to send emails to physicians
#Written on 2020-06-14 by EDV and JC
#This script has been adapted for the Activity Tracking project on 2022-5-10 by JC

# Send an HTML email with an embedded image and a plain text messagel for
# email clients that don't want to display the HTML.
import smtplib, sys, email, os, urllib, csv
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.image import MIMEImage
from email.utils import formataddr
from email.mime.base import MIMEBase
from email import encoders

print("Began send_email.py")

#set email to send from
sender_email = "handerson8@kumc.edu"

#read in first receiver email from the command line
receiver_email = sys.argv[1]

#read in html formatted body from command line
body = sys.argv[2]
body2 = open(body, 'r')
source_code = body2.read() 

#read in spreadsheet attachments
audit = sys.argv[3]
visit_audit = sys.argv[4]

#read in spreadsheet names
audit_name = sys.argv[5]
visit_audit_name = sys.argv[6]
 
#recipients = [receiver_email,'handerson8@kumc.edu','aunrein3@kumc.edu']
recipients = [receiver_email]

msg2email = MIMEMultipart('related')
msg2email["Subject"] = "vCCC Monitoring"
msg2email["From"] = email.utils.formataddr(('Heidi Anderson', sender_email))
msg2email["To"] = ", ".join(recipients)
msg2email.preamble = 'This is a multi-part msg2email in MIME format.'


msgAlternative = MIMEMultipart("alternative")
msg2email.attach(msgAlternative)

######### create the plain MIMEText object #############
text = """\
If you see this please contact jclutton@kumc.edu and let the him know you cannot see
the html version of this email.
"""
msgText = MIMEText(text, 'plain', 'utf-8')
msgAlternative.attach(msgText)


######## Create the html  version of your msg2email ############

html=source_code
         
msgHTML = MIMEText(html, "html", 'utf-8')
msgAlternative.attach(msgHTML)

#########  Attach xlsx files #########

part1 = MIMEBase('application', "octet-stream")
part1.set_payload(open(audit, "rb").read())
encoders.encode_base64(part1)
part1.add_header('Content-Disposition', "attachment; filename= %s" % audit_name)
msg2email.attach(part1)

part2 = MIMEBase('application', "octet-stream")
part2.set_payload(open(visit_audit, "rb").read())
encoders.encode_base64(part2)
part2.add_header('Content-Disposition', "attachment; filename= %s" % visit_audit_name)
msg2email.attach(part2)



####### Create secure connection with server and send email ########

try:
   server =  smtplib.SMTP('smtp.kumc.edu', 25)
   server.sendmail(sender_email, recipients, msg2email.as_string())
   print('successfully sent the mail')
   server.close()
except:
        print("failed to send mail")






