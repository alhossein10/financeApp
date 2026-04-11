# PowerShell script to fix all localization issues

$files = @(
    "lib/features/admin_group/presentation/pages/group_management_page.dart",
    "lib/features/admin_group/presentation/widgets/group_member_list.dart",
    "lib/features/admin_group/presentation/widgets/group_member_card.dart",
    "lib/features/admin_group/presentation/widgets/member_fund_box_balance.dart",
    "lib/features/admin_group/presentation/widgets/group_code_display.dart",
    "lib/features/profile/presentation/pages/profile_page.dart",
    "lib/features/settings/presentation/pages/language_settings_page.dart",
    "lib/features/admin_group/presentation/widgets/join_group_form.dart",
    "lib/features/admin_group/presentation/widgets/group_code_input.dart",
    "lib/features/profile/presentation/widgets/profile_info_card.dart",
    "lib/features/admin/presentation/pages/database_management_page.dart",
    "lib/features/onboarding/presentation/pages/onboarding_page.dart",
    "lib/core/widgets/app_navigation_bar.dart",
    "lib/features/superadmin/presentation/pages/superadmin_transfer_page.dart",
    "lib/features/transfers/presentation/widgets/transfer_form.dart",
    "lib/features/admin_group/presentation/pages/join_group_page.dart",
    "lib/features/admin_group/presentation/pages/group_info_page.dart"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "Processing $file..."
        $content = Get-Content $file -Raw
        
        # Fix translate() method calls
        $content = $content -replace "l10n\.translate\('([^']+)'\)", 'l10n.$1'
        $content = $content -replace 'l10n\?\.translate\(''([^'']+)''\)', 'l10n?.$1'
        
        # Fix adminGroup nested access
        $content = $content -replace 'l10n\?\.adminGroup\.', 'l10n?.'
        $content = $content -replace 'l10n\.adminGroup\.', 'l10n.'
        $content = $content -replace 'AppLocalizations\.of\(context\)\?\.adminGroup\.', 'AppLocalizations.of(context)?.'
        
        # Fix transfers nested access
        $content = $content -replace 'l10n\?\.transfers\.', 'l10n?.'
        $content = $content -replace 'l10n\.transfers\.', 'l10n.'
        
        # Fix fundBox nested access
        $content = $content -replace 'l10n\?\.fundBox\.', 'l10n?.'
        $content = $content -replace 'l10n\.fundBox\.', 'l10n.'
        
        # Fix errors nested access
        $content = $content -replace 'l10n\?\.errors\.', 'l10n?.'
        $content = $content -replace 'l10n\.errors\.', 'l10n.'
        
        Set-Content $file $content -NoNewline
        Write-Host "Fixed $file"
    } else {
        Write-Host "File not found: $file" -ForegroundColor Yellow
    }
}

Write-Host "`nAll files processed!" -ForegroundColor Green
