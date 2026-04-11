# PowerShell script to fix all localization errors

Write-Host "Fixing localization errors..." -ForegroundColor Green

# Function to replace translate() calls with direct property access
function Fix-TranslateCalls {
    param($file)
    
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        
        # Common translate() patterns to fix
        $patterns = @{
            "l10n\.translate\('no_syp_recorded'\)" = "l10n.noSypRecorded"
            "l10n\.translate\('new_transfer'\)" = "l10n.newTransfer"
            "l10n\.translate\('retry'\)" = "l10n.retry"
            "l10n\.translate\('no_users_in_group'\)" = "l10n.noUsersInGroup ?? 'No users in group'"
            "l10n\.translate\('recipient_name'\)" = "l10n.recipientName"
            "l10n\.translate\('select_recipient'\)" = "l10n.selectRecipient ?? 'Select recipient'"
            "l10n\.translate\('amount_usd'\)" = "l10n.amountUsd"
            "l10n\.translate\('transaction_date'\)" = "l10n.transactionDate"
            "l10n\.translate\('cancel'\)" = "l10n.cancel"
            "l10n\.translate\('create'\)" = "l10n.create"
            "l10n\.translate\('no_incoming'\)" = "l10n.incoming"
            "l10n\.translate\('usd'\)" = "l10n.usd"
            "l10n\.translate\('date'\)" = "l10n.date"
            "l10n\.translate\('invalid_amount'\)" = "l10n.invalidAmount"
            "l10n\.translate\('amount_exceeds_balance'\)" = "l10n.amountExceedsBalance"
            "l10n\.translate\('convert'\)" = "l10n.convert"
            "l10n\.translate\('exchange_history'\)" = "l10n.exchangeHistory"
            "l10n\.translate\('available_balance'\)" = "l10n.fundBoxBalance ?? 'Available Balance'"
            "l10n\.translate\('hide'\)" = "'Hide'"
            "l10n\.translate\('exchange_details'\)" = "l10n.exchangeDetails"
            "l10n\.translate\('target_currency'\)" = "'Target Currency'"
            "l10n\.translate\('max'\)" = "'Max'"
            "l10n\.translate\('please_enter_amount'\)" = "l10n.pleaseEnterAmount"
            "l10n\.translate\('amount_syp'\)" = "l10n.amountSyp"
            "l10n\.translate\('amount_try'\)" = "l10n.amountTry"
            "l10n\.translate\('exchange_rate'\)" = "l10n.exchangeRate"
            "l10n\.translate\('exchange_date'\)" = "l10n.exchangeDate"
            "l10n\.translate\('notes'\)" = "l10n.notes"
            "l10n\.translate\('create_exchange'\)" = "l10n.createExchange"
            "l10n\.translate\('exchange_created_success'\)" = "l10n.exchangeCreatedSuccess"
            "l10n\.translate\('error'\)" = "l10n.error"
            "widget\.l10n\.translate" = "widget.l10n."
            "AppLocalizations\.of\(context\)\.translate" = "AppLocalizations.of(context)!."
        }
        
        $modified = $false
        foreach ($pattern in $patterns.Keys) {
            if ($content -match $pattern) {
                $content = $content -replace $pattern, $patterns[$pattern]
                $modified = $true
            }
        }
        
        if ($modified) {
            Set-Content $file -Value $content -NoNewline
            Write-Host "Fixed: $file" -ForegroundColor Yellow
            return $true
        }
    }
    return $false
}

# Files to fix
$files = @(
    "lib\ui\cash_inbox_page.dart",
    "lib\ui\user_cash_inbox_page.dart",
    "lib\ui\currency_tool_page.dart",
    "lib\ui\expense_page.dart",
    "lib\ui\superadmin_cash_page.dart",
    "lib\ui\superadmin_expenses_page.dart",
    "lib\features\export\presentation\pages\export_page.dart",
    "lib\features\onboarding\presentation\pages\onboarding_page.dart",
    "lib\features\transfers\presentation\widgets\transfer_form.dart",
    "lib\core\widgets\multi_currency_balance_card.dart",
    "lib\core\widgets\app_navigation_bar.dart"
)

$fixedCount = 0
foreach ($file in $files) {
    if (Fix-TranslateCalls $file) {
        $fixedCount++
    }
}

Write-Host "`nFixed $fixedCount files" -ForegroundColor Green
Write-Host "Now run: flutter pub run build_runner build --delete-conflicting-outputs" -ForegroundColor Cyan
