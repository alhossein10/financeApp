# PowerShell script to update php.ini with certificate path
# Run this as Administrator

$phpIniPath = "C:\xampp\php\php.ini"
$certPath = "D:\Flutter_Projects\finance_backend\cacert.pem"

# Backup the original php.ini
Copy-Item $phpIniPath "$phpIniPath.backup"

# Read the content
$content = Get-Content $phpIniPath

# Update curl.cainfo
$content = $content -replace ';curl.cainfo =', "curl.cainfo = `"$certPath`""
$content = $content -replace 'curl.cainfo = .*', "curl.cainfo = `"$certPath`""

# Update openssl.cafile
$content = $content -replace ';openssl.cafile=', "openssl.cafile=`"$certPath`""
$content = $content -replace 'openssl.cafile=.*', "openssl.cafile=`"$certPath`""

# Write back
$content | Set-Content $phpIniPath

Write-Host "php.ini updated successfully!"
Write-Host "Backup saved to: $phpIniPath.backup"
