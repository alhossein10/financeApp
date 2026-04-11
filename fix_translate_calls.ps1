# PowerShell script to fix all l10n.translate() calls to use direct property access

Write-Host "Fixing localization translate() calls..." -ForegroundColor Cyan

# Define the mappings from translate keys to property names
$mappings = @{
    'add_expense' = 'addExpense'
    'date' = 'date'
    'all' = 'all'
    'today' = 'today'
    'this_week' = 'thisWeek'
    'this_month' = 'thisMonth'
    'custom' = 'custom'
    'user' = 'user'
    'all_users' = 'allUsers'
    'usd' = 'usd'
    'syp' = 'syp'
    'try' = 'currencyTry'
    'created_by' = 'createdBy'
    'unknown_user' = 'unknownUser'
    'view_invoice' = 'viewInvoice'
    'edit' = 'edit'
    'delete' = 'delete'
    'retry_sync' = 'retrySync'
    'delete_invoice' = 'deleteInvoice'
    'confirm_delete' = 'confirmDelete'
    'delete_expense_confirmation' = 'deleteExpenseConfirmation'
    'cancel' = 'cancel'
    'delete_invoice_confirmation' = 'deleteInvoiceConfirmation'
    'no_admin_members_available' = 'noAdminMembersAvailable'
    'create_outgoing_transfer' = 'createOutgoingTransfer'
    'recipient_name' = 'recipientName'
    'amount_usd' = 'amountUsd'
    'transaction_date' = 'transactionDate'
    'create' = 'create'
    'new_incoming' = 'newIncoming'
    'description' = 'description'
    'retry' = 'retry'
}

# Files to fix
$files = @(
    'lib/ui/expense_page.dart',
    'lib/ui/superadmin_cash_page.dart',
    'lib/ui/superadmin_expenses_page.dart',
    'lib/features/export/presentation/pages/export_page.dart',
    'lib/features/onboarding/presentation/pages/onboarding_page.dart',
    'lib/features/admin/presentation/pages/database_management_page.dart',
    'lib/features/profile/presentation/widgets/profile_info_card.dart',
    'lib/features/admin_group/presentation/widgets/group_code_display.dart',
    'lib/features/admin_group/presentation/widgets/group_member_list.dart',
    'lib/features/admin_group/presentation/widgets/join_group_form.dart',
    'lib/features/transfers/presentation/widgets/transfer_form.dart',
    'lib/core/widgets/multi_currency_balance_card.dart',
    'lib/core/widgets/app_navigation_bar.dart',
    'lib/features/admin_group/presentation/widgets/group_code_input.dart',
    'lib/features/admin_group/presentation/widgets/group_member_card.dart',
    'lib/features/admin_group/presentation/widgets/member_fund_box_balance.dart'
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "Processing $file..." -ForegroundColor Yellow
        
        $content = Get-Content $file -Raw
        $originalContent = $content
        
        # Replace l10n.translate('key') with l10n.key
        foreach ($key in $mappings.Keys) {
            $property = $mappings[$key]
            $content = $content -replace "l10n\.translate\('$key'\)", "l10n.$property"
            $content = $content -replace "l10n\?\.translate\('$key'\)", "l10n?.$property"
        }
        
        # Replace l10n?.translate with l10n? for property access patterns
        $content = $content -replace "l10n\?\.translate\(", "l10n?."
        
        if ($content -ne $originalContent) {
            Set-Content -Path $file -Value $content -NoNewline
            Write-Host "  ✓ Fixed $file" -ForegroundColor Green
        } else {
            Write-Host "  - No changes needed for $file" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ✗ File not found: $file" -ForegroundColor Red
    }
}

Write-Host "`nDone! Please review the changes and run flutter build to verify." -ForegroundColor Cyan
