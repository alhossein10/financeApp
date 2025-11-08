# PowerShell script to enable required PHP extensions
# Run this as Administrator

$phpIniPath = "C:\xampp\php\php.ini"

# Backup the original php.ini
Copy-Item $phpIniPath "$phpIniPath.backup-extensions" -Force

# Read the content
$content = Get-Content $phpIniPath

# Enable GD extension
$content = $content -replace ';extension=gd', 'extension=gd'

# Enable other useful extensions for Laravel
$content = $content -replace ';extension=zip', 'extension=zip'
$content = $content -replace ';extension=fileinfo', 'extension=fileinfo'

# Write back
$content | Set-Content $phpIniPath

Write-Host "PHP extensions enabled successfully!"
Write-Host "Backup saved to: $phpIniPath.backup-extensions"
Write-Host "Please restart your terminal/server for changes to take effect."
