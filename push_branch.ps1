# PowerShell Script to Push final-laravel-integrated Branch to GitHub
# Run this script: .\push_branch.ps1

Write-Host "=== Step 1: Checking Current Status ===" -ForegroundColor Cyan
git branch
git status
git remote -v

Write-Host "`n=== Step 2: Creating Branch (if not exists) ===" -ForegroundColor Cyan
git checkout -b final-laravel-integrated 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Branch already exists, switching to it..." -ForegroundColor Yellow
    git checkout final-laravel-integrated
}
git branch

Write-Host "`n=== Step 3: Staging All Changes ===" -ForegroundColor Cyan
git add -A
git status --short

Write-Host "`n=== Step 4: Committing Changes ===" -ForegroundColor Cyan
$commitMessage = "Final Laravel backend integration - Complete migration from Supabase/PocketBase to Laravel API with admin group management, batch sync, file upload, and all features integrated"
git commit -m $commitMessage
git log --oneline -1

Write-Host "`n=== Step 5: Configuring Git for Large HTTP Push ===" -ForegroundColor Cyan
git config http.postBuffer 524288000
git config http.timeout 600
git config http.version HTTP/1.1
git config core.compression 9
git config pack.windowMemory "256m"
git config pack.packSizeLimit "2g"
Write-Host "Git configured successfully!" -ForegroundColor Green

Write-Host "`n=== Step 6: Pushing Branch to GitHub ===" -ForegroundColor Cyan
Write-Host "This may take several minutes for large repositories..." -ForegroundColor Yellow
git push -u origin final-laravel-integrated --progress

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n=== Push Successful! ===" -ForegroundColor Green
} else {
    Write-Host "`n=== Push Failed - Trying Alternative Method ===" -ForegroundColor Red
    Write-Host "Attempting push without progress flag..." -ForegroundColor Yellow
    git push -u origin final-laravel-integrated
}

Write-Host "`n=== Step 7: Verifying Push ===" -ForegroundColor Cyan
git fetch origin
git branch -r | Select-String "final-laravel-integrated"

Write-Host "`n=== Step 8: Checking Branch Status ===" -ForegroundColor Cyan
git branch -vv

Write-Host "`n=== Complete! ===" -ForegroundColor Green
Write-Host "Check the output above to verify the push was successful." -ForegroundColor Yellow

