// This file documents the fixes needed for export page compilation errors
// Run these fixes manually or use the commands below

/*
FIXES NEEDED:

1. FlavorConfig.isAdmin -> FlavorConfig.instance.flavor.isAdmin
2. FlavorConfig.isUser -> FlavorConfig.instance.flavor.isUser  
3. AppLocalizations.of(context) can be null - add ! operator
4. InvoiceStatus ambiguous - use explicit import
5. UserExportPage const constructor - remove const

FILES TO FIX:
- lib/core/routing/home_scaffold.dart
- lib/core/routing/app_router.dart
- lib/features/admin/presentation/pages/admin_export_page.dart
- lib/features/user/presentation/pages/user_export_page.dart
*/
