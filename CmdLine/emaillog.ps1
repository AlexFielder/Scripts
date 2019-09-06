#the following works fine if you input the correct username/password/smtp server address:
$email = "smtpuser@yourdomain.com" 
$emailto = "alex.fielder@graitec.com"

$pass = "smtppassword" 
$smtpServer = "smtp.yourdomain.com"

$msg = new-object Net.Mail.MailMessage 
$smtp = new-object Net.Mail.SmtpClient($smtpServer) 
$smtp.EnableSsl = $true
$msg.From = "$email" 
$msg.To.Add("$emailto")

$msg.BodyEncoding = [system.Text.Encoding]::UTF8 
$msg.SubjectEncoding = [system.Text.Encoding]::UTF8 
$msg.IsBodyHTML = $true

$msg.Subject = "It's an email Subject field" 
$msg.Body = "Your text here"

$SMTP.Credentials = New-Object System.Net.NetworkCredential("$email", "$pass");
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
$smtp.Send($msg)