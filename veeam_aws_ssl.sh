#!/bin/bash
##      .SYNOPSIS
##      SSL Certificate for Veeam Backup for AWS with Let's Encrypt
## 
##      .DESCRIPTION
##      This Script will take the most recent Let's Encrypt certificate and push it to the Veeam Backup for AWS Web Server 
##      The Script, and the whole Let's Encrypt it is provided as it is, and bear in mind you can not open support Tickets regarding this project. It is a Community Project
##	
##      .Notes
##      NAME:  veeam_aws_ssl.sh
##      ORIGINAL NAME: veeam_aws_ssl.sh
##      LASTEDIT: 21/06/2020
##      VERSION: 1.0
##      KEYWORDS: Veeam, SSL, Let's Encrypt
   
##      .Link
##      https://jorgedelacruz.es/
##      https://jorgedelacruz.uk/

# Configurations
##
# Endpoint URL for login action
veeamDomain="YOURVEEAMAWSAPPLIANCEDOMAIN"
veeamSSLPassword="YOURVEEAMSSLPASSWORD" #Introduce a password that will be use to merge the SSL into a .PFX
veeamOutputPFXPath="/tmp/bundle.pfx"
veeamUsername="YOURVEEAMBACKUPUSER"
veeamPassword="YOURVEEAMBACKUPPASS"
veeamBackupAWSServer="https://YOURVEEAMBACKUPIP"
veeamBackupAWSPort="11005" #Default Port

veeamBearer=$(curl -X POST --header "Content-Type: application/x-www-form-urlencoded" --header "Accept: application/json" -d "Username=$veeamUsername&Password=$veeamPassword&refresh_token=&grant_type=Password&mfa_token=&mfa_code=" "$veeamBackupAWSServer:$veeamBackupAWSPort/api/v1/token" -k --silent | jq -r '.access_token')

##
# Veeam Backup for AWS SSL PFX Certificate Creation. This part will combine Let's Encrypt SSL files into a valid .pfx for Microsoft for AWS
##
openssl pkcs12 -export -out $veeamOutputPFXPath -inkey /root/.acme.sh/$veeamDomain/$veeamDomain.key -in /root/.acme.sh/$veeamDomain/fullchain.cer -password pass:$veeamSSLPassword

##
# Veeam Backup for AWS SSL Certificate Push. This part will retrieve last Let's Encrypt Certificate and push it
##
veeamVBAURL="$veeamBackupAWSServer:$veeamBackupAWSPort/api/v1/settings/certificates/upload"

curl -X POST "$veeamVBAURL" -H "accept: application/json" -H "x-api-version: 1.0-rev0" -H "Authorization: Bearer $veeamBearer" -H "Content-Type: multipart/form-data" -F "certificateFile=@$veeamOutputPFXPath;type=application/x-pkcs12" -F "certificatePassword=$veeamSSLPassword" -k

echo "Your Veeam Backup for AWS SSL Certificate has been replaced with a valid Let's Encrypt one. Go to https://$veeamDomain"