# PowerShell script to fix all localization issues

$files = @(
    "lib/features/export/presentation/pages/export_page.dart",
    "lib/features/onboarding/presentation/pages/onboarding_page.dart",
    "lib/features/admin/presentation/pages/database_management_page.dart",
    "lib/features/profile/presentation/widgets/profile_info_card.dart",
    "lib/features/admin_group/presentation/widgets/group_code_display.dart",
    "lib/features/admin_group/presentation/widgets/group_member_list.dart",
    "lib/features/admin_group/presentation/widgets/join_group_form.dart",
    "lib/features/admin_group/presentation/widgets/group_code_input.dart",
    "lib/features/admin_group/presentation/widgets/group_member_card.dart",
    "lib/features/admin_group/presentation/widgets/member_fund_box_balance.dart",
    "lib/core/widgets/app_navigation_bar.dart",
    "lib/features/transfers/presentation/widgets/transfer_form.dart",
    "lib/core/widgets/multi_currency_balance_card.dart",
    "lib/utils/pdf_export_helper.dart"
)

Write-Host "Fixing localization issues in $($files.Count) files..." -ForegroundColor Green

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "Processing $file..." -ForegroundColor Yellow
        
        $content = Get-Content $file -Raw
        
        # Replace .translate() calls with direct property access
        $content = $content -replace "l10n\.translate\('([^']+)'\)", 'l10n?.$1'
        $content = $content -replace "l10n!\.translate\('([^']+)'\)", 'l10n!.$1'
        $content = $content -replace "AppLocalizations\.of\(context\)\.translate\('([^']+)'\)", 'AppLocalizations.of(context)?.$1'
        $content = $content -replace "AppLocalizations\.of\(context\)!\.translate\('([^']+)'\)", 'AppLocalizations.of(context)!.$1'
        
        # Fix specific property names that need conversion from snake_case to camelCase
        $replacements = @{
            'transaction_date' = 'transactionDate'
            'please_fill_all_fields' = 'pleaseFillAllFields'
            'fund_box_balance' = 'fundBoxBalance'
            'create_outgoing_transfer' = 'createOutgoingTransfer'
            'add_incoming' = 'addIncoming'
            'no_outgoing_transfers' = 'noOutgoingTransfers'
            'no_incoming' = 'incoming'
            'transfer_created' = 'transferCreated'
            'export_data' = 'exportData'
            'export_downloaded_successfully' = 'exportDownloadedSuccessfully'
            'date_range' = 'dateRange'
            'start_date' = 'startDate'
            'end_date' = 'endDate'
            'clear_dates' = 'clearDates'
            'export_format' = 'exportFormat'
            'export_status' = 'exportStatus'
            'requesting_export' = 'requestingExport'
            'please_wait' = 'pleaseWait'
            'export_queued' = 'exportQueued'
            'export_in_queue' = 'exportInQueue'
            'processing_export' = 'processingExport'
            'export_ready' = 'exportReady'
            'downloading_export' = 'downloadingExport'
            'export_completed' = 'exportCompleted'
            'file_saved_successfully' = 'fileSavedSuccessfully'
            'open_file' = 'openFile'
            'export_failed' = 'exportFailed'
            'no_data_available' = 'noDataAvailable'
            'export_pdf' = 'exportPdf'
            'export_excel' = 'exportExcel'
            'no_expenses_found' = 'noExpensesYet'
            'filter_by_group' = 'filterByGroup'
            'all_groups' = 'allGroups'
            'grand_total' = 'grandTotal'
            'total_expenses' = 'totalExpenses'
            'expense_count' = 'expenseCount'
            'error_loading_stats' = 'errorLoadingStats'
            'clear_all_data' = 'clearAllData'
            'clear_all_data_warning' = 'clearAllDataWarning'
            'delete_all_data' = 'deleteAllData'
            'all_data_cleared' = 'allDataCleared'
            'error_clearing_data' = 'errorClearingData'
            'database_management' = 'databaseManagement'
            'member_since' = 'memberSince'
            'edit_profile' = 'editProfile'
            'admin_group.code_copied' = 'codeCopied'
            'admin_group.group_code' = 'groupCode'
            'admin_group.copied' = 'copied'
            'admin_group.copy_code' = 'copyCode'
            'admin_group.share_with_team' = 'shareWithTeam'
            'admin_group.search_members' = 'searchMembers'
            'admin_group.filter_by_department' = 'filterByDepartment'
            'admin_group.all_departments' = 'allDepartments'
            'admin_group.members_count' = 'membersCount'
            'admin_group.no_members_found' = 'noMembersFound'
            'admin_group.no_members_yet' = 'noMembersYet'
            'admin_group.loading_members' = 'loadingMembers'
            'admin_group.clear_filters' = 'clearFilters'
            'admin_group.code_required' = 'codeRequired'
            'admin_group.code_must_be_6' = 'codeMustBe6'
            'admin_group.code_invalid_chars' = 'codeInvalidChars'
            'admin_group.join_instructions' = 'joinInstructions'
            'admin_group.join_group' = 'joinGroup'
            'admin_group.join_help' = 'joinHelp'
            'admin_group.code_too_short' = 'codeTooShort'
            'admin_group.code_too_long' = 'codeTooLong'
            'admin_group.get_from_admin' = 'getFromAdmin'
            'admin_group.code_requirements' = 'codeRequirements'
            'admin_group.confirm_remove_title' = 'confirmRemoveTitle'
            'admin_group.confirm_remove' = 'confirmRemove'
            'admin_group.remove_member' = 'removeMember'
            'admin_group.admin_badge' = 'adminBadge'
            'admin_group.cannot_remove_self' = 'cannotRemoveSelf'
            'loading_balance' = 'loadingBalance'
            'transfers.select_recipient' = 'recipientName'
            'errors.insufficient_balance_usd' = 'amountExceedsBalance'
            'errors.generic' = 'error'
            'transfers.select_admin' = 'selectOrganization'
            'transfers.select_user' = 'user'
            'transfers.recipient_required' = 'organizationRequired'
            'transfers.amount_usd' = 'amountUsd'
            'transfers.amount_required' = 'amountUsdRequired'
            'transfers.amount_invalid' = 'invalidAmount'
            'transfers.transfer_date' = 'transactionDate'
            'transfers.notes' = 'notes'
            'fund_box.current_balance' = 'fundBoxBalance'
            'transfers.create_transfer' = 'newTransfer'
            'onboarding_cash_management_title' = 'onboardingCashManagementTitle'
            'onboarding_cash_management_desc' = 'onboardingCashManagementDesc'
            'onboarding_expenses_title' = 'onboardingExpensesTitle'
            'onboarding_expenses_desc' = 'onboardingExpensesDesc'
            'onboarding_transfers_title' = 'onboardingTransfersTitle'
            'onboarding_transfers_desc' = 'onboardingTransfersDesc'
            'onboarding_exports_title' = 'onboardingExportsTitle'
            'onboarding_exports_desc' = 'onboardingExportsDesc'
            'get_started' = 'getStarted'
        }
        
        foreach ($key in $replacements.Keys) {
            $value = $replacements[$key]
            $content = $content -replace "l10n\?\.`"$key`"", "l10n?.$value"
            $content = $content -replace "l10n!\.`"$key`"", "l10n!.$value"
        }
        
        Set-Content $file $content -NoNewline
        Write-Host "  ✓ Fixed $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ File not found: $file" -ForegroundColor Red
    }
}

Write-Host "`nAll files processed!" -ForegroundColor Green
