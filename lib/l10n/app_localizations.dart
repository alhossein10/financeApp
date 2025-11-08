import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Finance App',
      'cash': 'Cash',
      'convert': 'Convert',
      'expenses': 'Expenses',
      'export': 'Export',
      'fund_box_usd': 'Fund Box (USD)',
      'set_fund_balance': 'Set Fund Balance (USD)',
      'cancel': 'Cancel',
      'save': 'Save',
      'transfer': 'Transfer',
      'transfers': 'Transfers',
      'new_transfer': 'New Transfer',
      'transfer_created': 'Transfer created successfully',
      'transfer_deleted': 'Transfer deleted successfully',
      'recipient_name': 'Recipient name',
      'create_outgoing_transfer': 'Create Outgoing Transfer',
      'outgoing_transfers': 'Outgoing Transfers',
      'no_outgoing_transfers': 'No outgoing transfers yet',
      'no_admin_members_available': 'No admin members available',
      'fund_box_balance': 'Fund Box Balance',
      'please_fill_all_fields': 'Please fill all required fields',
      'amount_usd': 'Amount USD',
      'converted_amount': 'Converted Amount (USD → SYP)',
      'exchange_rate': 'Exchange Rate (USD → SYP)',
      'converted_total_syp': 'Converted Total (SYP)',
      'create': 'Create',
      'edit_conversion': 'Edit conversion',
      'edit_transfer_conversion': 'Edit Transfer Conversion',
      'refund_delete': 'Refund and delete',
      'delete': 'Delete',
      'no_syp_recorded': 'No SYP recorded',
      'converted_amount_error': 'Converted amount cannot exceed total transfer amount',
      'usd_syp_rate': 'USD → SYP rate',
      'usd': 'USD',
      'syp': 'SYP',
      'try': 'TRY',
      'currency': 'Currency',
      'all': 'All',
      'add_expense': 'Add expense',
      'new_expense': 'New Expense',
      'edit_expense': 'Edit Expense',
      'item_description': 'Item description *',
      'expense_date': 'Expense Date',
      'price_usd': 'Price USD',
      'price_syp': 'Price SYP',
      'price_try': 'Price TRY',
      'invoice_status': 'Invoice status',
      'invoice_available': 'Invoice available',
      'no_invoice_available': 'No invoice available',
      'no_file_selected': 'No file selected',
      'upload': 'Upload',
      'edit': 'Edit',
      'date': 'Date',
      'today': 'Today',
      'this_week': 'This Week',
      'this_month': 'This Month',
      'custom': 'Custom',
      'export_pdf': 'Export PDF',
      'export_excel': 'Export Excel',
      'expenses_list': 'Expenses List',
      'description': 'Description',
      'invoice': 'Invoice',
      'yes': 'Yes',
      'no': 'No',
      'outgoing': 'Outgoing',
      'incoming': 'Incoming',
      'add_incoming': 'Add Incoming',
      'new_incoming': 'New Incoming',
      'edit_incoming': 'Edit Incoming',
      'transaction_date': 'Transaction Date',
      'search': 'Search',
      'search_by_name': 'Search by recipient name',
      'this_year': 'This Year',
      'summary': 'Summary',
      'total': 'Total',
      'take_photo': 'Take Photo',
      'from_gallery': 'From Gallery',
      'photo_saved': 'Photo saved successfully',
      'no_camera': 'No camera available',
      'export_cash': 'Export Cash',
      'export_invoices': 'Export Invoices',
      'add_exchange': 'Add Exchange',
      'exchange_history': 'Exchange History',
      'no_exchanges': 'No exchange history',
      'cash_transactions': 'Cash Transactions',
      'invoice_images': 'Invoice Images',
      'no_invoice_images': 'No invoice images found',
      'welcome': 'Welcome',
      'login': 'Login',
      'register': 'Create Account',
      'username': 'Username',
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'forgot_password': 'Forgot Password?',
      'remember_me': 'Remember me',
      'logout': 'Logout',
      'profile': 'Profile',
      'account_settings': 'Account Settings',
      'change_password': 'Change Password',
      'invalid_credentials': 'Invalid credentials',
      'registration_success': 'Account created successfully',
      'weak_password': 'Weak password',
      'email_already_exists': 'Email already exists',
      'username_already_exists': 'Username already exists',
      'welcome_back': 'Welcome Back!',
      'sign_in_to_continue': 'Sign in to continue',
      'create_your_account': 'Create Your Account',
      'fill_details_to_start': 'Fill in the details to get started',
      'dont_have_account': "Don't have an account?",
      'already_have_account': 'Already have an account?',
      'sign_up': 'Sign Up',
      'password_requirements': 'Password must be at least 8 characters with uppercase, lowercase, and number',
      'manage_finances': 'Manage your finances easily and securely',
      'skip': 'Skip',
      'next': 'Next',
      'get_started': 'Get Started',
      'onboarding_cash_management_title': 'Cash Management',
      'onboarding_cash_management_desc': 'Track your fund box balance, manage transfers, and monitor incoming transactions all in one place.',
      'onboarding_expenses_title': 'Expense Tracking',
      'onboarding_expenses_desc': 'Record and categorize your expenses with invoice scanning support for easy documentation.',
      'onboarding_transfers_title': 'Money Transfers',
      'onboarding_transfers_desc': 'Send money with automatic currency conversion and exchange rate tracking.',
      'onboarding_exports_title': 'Export & Reports',
      'onboarding_exports_desc': 'Generate PDF and Excel reports of your financial data with customizable filters.',
      'view_tutorial': 'View Tutorial',
      'syncing': 'Syncing...',
      'sync_completed': 'Sync completed successfully',
      'sync_failed': 'Sync failed',
      'retry_sync': 'Retry Sync',
      'sync_retry': 'Retry',
      'sync_all': 'Sync All',
      'sync_in_progress': 'Sync in progress',
      'admin_dashboard': 'Admin Dashboard',
      'statistics': 'Statistics',
      'total_users': 'Total Users',
      'total_expenses': 'Total Expenses',
      'pending_sync': 'Pending Sync',
      'total_amount': 'Total Amount',
      'recent_user_expenses': 'Recent User Expenses',
      'user_activity_summary': 'User Activity Summary',
      'created_by': 'Created by',
      'unknown_user': 'Unknown User',
      'no_expenses_yet': 'No expenses yet',
      'no_user_activity': 'No user activity',
      'sync_pending': 'Pending',
      'sync_syncing': 'Syncing',
      'sync_synced': 'Synced',
      'sync_status': 'Sync Status',
      'all_users': 'All Users',
      'all_statuses': 'All Statuses',
      'user': 'User',
      'filter_by_user': 'Filter by User',
      'filter_by_recipient': 'Filter by Recipient',
      'total_syp': 'Total SYP',
      'must_select_same_user': 'You must select the same user for exchange history and expenses to export the file',
      'export_exchanges': 'Export Exchanges',
      'combined_export': 'Combined Export',
      'export_user_data': 'Export User Data',
      'please_select_user': 'Please select a user first',
      'export_error': 'Export Error',
      'view_invoice': 'View Invoice',
      'no_invoice_image': 'No invoice image available',
      'failed_to_load_image': 'Failed to load image',
      'invoice_image': 'Invoice Image',
      'unauthorized_access': 'Unauthorized Access',
      'no_data_available': 'No data available',
      'retry': 'Retry',
      'expense_created': 'Expense created successfully',
      'expense_updated': 'Expense updated successfully',
      'expense_deleted': 'Expense deleted successfully',
      'organization': 'Organization',
      'department': 'Department',
      'selectOrganization': 'Select Organization',
      'selectDepartment': 'Select Department',
      'organizationRequired': 'Please select an organization',
      'departmentRequired': 'Please select a department',
      'regularUser': 'Regular User',
      'adminUser': 'Administrator',
      'userType': 'User Type',
      
      // Admin Group Management
      'admin_group.group_code': 'Group Code',
      'admin_group.group_name': 'Group Name',
      'admin_group.members_count': 'Members',
      'admin_group.copy_code': 'Copy',
      'admin_group.copied': 'Copied!',
      'admin_group.regenerate_code': 'Regenerate',
      'admin_group.remove_member': 'Remove',
      'admin_group.join_group': 'Join Group',
      'admin_group.my_group': 'My Group',
      'admin_group.group_management': 'Group Management',
      'admin_group.enter_group_code': 'Enter group code',
      'admin_group.group_code_hint': '6 characters',
      'admin_group.get_from_admin': 'Get this code from your admin',
      'admin_group.share_with_team': 'Share this code with your team members',
      'admin_group.confirm_remove': 'Are you sure you want to remove this member from the group?',
      'admin_group.confirm_remove_title': 'Remove Member',
      'admin_group.confirm_regenerate': 'Regenerating will invalidate the old code. Continue?',
      'admin_group.joined_at': 'Joined',
      'admin_group.admin_contact': 'Admin',
      'admin_group.contact_admin_to_leave': 'Contact your admin to leave the group',
      'admin_group.admin_badge': 'Admin',
      'admin_group.cannot_remove_self': 'You cannot remove yourself from the group',
      'admin_group.search_members': 'Search members...',
      'admin_group.filter_by_department': 'Filter by Department',
      'admin_group.all_departments': 'All Departments',
      'admin_group.no_members_found': 'No members found matching your filters',
      'admin_group.no_members_yet': 'No members in this group yet',
      'admin_group.loading_members': 'Loading members...',
      'admin_group.clear_filters': 'Clear Filters',
      'admin_group.code_too_short': 'Code must be 6 characters',
      'admin_group.code_too_long': 'Code must be exactly 6 characters',
      'admin_group.code_invalid_chars': 'Code must contain only letters and numbers',
      'admin_group.code_required': 'Group code is required',
      'admin_group.code_must_be_6': 'Code must be exactly 6 characters',
      'admin_group.code_requirements': 'Code Requirements:',
      'admin_group.join_instructions': 'Enter the 6-character group code provided by your admin to join their group.',
      'admin_group.join_help': 'Don\'t have a code? Contact your admin.',
      
      // Success messages
      'admin_group.code_copied': 'Group code copied to clipboard',
      'admin_group.member_removed': 'Member removed successfully',
      'admin_group.code_regenerated': 'Group code regenerated successfully',
      'admin_group.joined_group': 'Successfully joined the group',
      
      // Error messages
      'admin_group.invalid_code': 'The selected group code is invalid',
      'admin_group.already_in_group': 'You are already in a group',
      'admin_group.admin_cannot_join': 'Admins cannot join other groups',
      'admin_group.member_not_found': 'User not found or not in your group',
      
      // Profile Page
      'member_since': 'Member since',
      'edit_profile': 'Edit Profile',
      'edit_profile_title': 'Edit Profile',
      'profile_picture_updated': 'Profile picture updated successfully',
      'failed_to_load_profile': 'Failed to load profile',
      'group_management': 'Group Management',
      'my_group': 'My Group',
      'database_management': 'Database Management',
      'logout_confirm_title': 'Logout',
      'logout_confirm_message': 'Are you sure you want to logout?',
      'choose_from_gallery': 'Choose from Gallery',
      'failed_to_pick_image': 'Failed to pick image',
      
      // Profile Statistics
      'statistics': 'Statistics',
      'total_expenses_count': 'Total Expenses',
      'total_transfers_count': 'Total Transfers',
      'total_incoming_count': 'Total Incoming',
      'total_exchanges_count': 'Total Exchanges',
      'total_transactions': 'Total Transactions',
      'account_age': 'Account Age',
      'last_activity': 'Last Activity',
      
      // Audit Logs
      'audit_logs': 'Audit Logs',
      'feature_not_available': 'Feature Not Available',
      'audit_logs_admin_only': 'Audit logs are only available in the admin version.',
      'access_denied': 'Access Denied',
      'admin_privileges_required': 'Admin privileges required to view audit logs.',
      'no_audit_logs_found': 'No audit logs found',
      'audit_log_details': 'Audit Log Details',
      'action': 'Action',
      'entity_type': 'Entity Type',
      'entity_id': 'Entity ID',
      'user_id': 'User ID',
      'ip_address': 'IP Address',
      'user_agent': 'User Agent',
      'changes': 'Changes',
      'created_at': 'Created At',
      
      // Exchange Feature
      'create_exchange': 'Create Exchange',
      'select_transfer': 'Select Transfer',
      'no_transfers_available': 'No transfers available from admin',
      'transfer_balance': 'Transfer Balance',
      'original_amount': 'Original',
      'exchanged': 'Exchanged',
      'remaining': 'Remaining',
      'exchange_details': 'Exchange Details',
      'amount_syp': 'Amount in SYP',
      'exchange_created_success': 'Exchange created successfully!',
      'please_select_transfer': 'Please select a transfer first',
      'amount_exceeds_balance': 'Amount exceeds remaining balance',
      'no_exchanges_yet': 'No exchanges yet',
      'create_first_exchange': 'Create your first exchange from a transfer',
      'exchange_date': 'Exchange Date',
      'you_will_receive': 'You will receive',
      'select_date': 'Select Date',
      'amount_usd_required': 'Amount in USD is required',
      'exchange_rate_required': 'Exchange rate is required',
      'notes': 'Notes',
      'optional': 'Optional',
      'please_enter_amount': 'Please enter amount',
      'invalid_amount': 'Invalid amount',
      'please_enter_rate': 'Please enter exchange rate',
      'invalid_rate': 'Invalid exchange rate',
      'recipient': 'Recipient',
      'rate': 'Rate',
      'no_data_available': 'No data available',
      
      // Admin Group - Additional
      'admin_group.no_group_found': 'No group found',
      'admin_group.not_in_group': 'You are not in a group',
      'admin_group.not_in_group_desc': 'Join a group using a code provided by your admin to access shared financial data.',
      'admin_group.join_description': 'Enter the group code provided by your admin to join their group and access shared financial data.',
      'admin_group.help_title': 'Need Help?',
      'admin_group.help_1': 'The group code is 6 characters long',
      'admin_group.help_2': 'Get the code from your admin',
      'admin_group.help_3': 'You can only be in one group at a time',
      'admin_group.help_4': 'Contact your admin if you need to leave a group',
      
      // Export Page
      'expenses_list_title': 'Expenses List',
      'sum': 'SUM',
      'export_error': 'Export error',
      'no_expenses_to_export': 'No expenses to export',
      'no_invoices_to_export': 'No invoices to export',
      
      // Filters
      'filter_by_date': 'Filter by Date',
      'filter_by_user': 'Filter by User',
      'all_dates': 'All Dates',
      'all_users': 'All Users',
      'custom_range': 'Custom Range',
      'clear_filters': 'Clear Filters',
      
      // Database Management
      'clear_all_data': 'Clear All Data',
      'clear_all_data_warning': 'This will delete ALL data from the database including:\n\n• All expenses\n• All transfers\n• All incoming transactions\n• All fund box records\n• All exchanges\n\nThis action cannot be undone!',
      'delete_all_data': 'Delete All Data',
      'all_data_cleared': '✓ All data cleared successfully',
      'error_clearing_data': 'Error clearing data',
      'error_loading_stats': 'Error loading stats',
      'go_back': 'Go Back',
      
      // Common UI
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'warning': 'Warning',
      'info': 'Info',
      'close': 'Close',
      'ok': 'OK',
      'confirm': 'Confirm',
      'back': 'Back',
      'continue': 'Continue',
      'submit': 'Submit',
      'update': 'Update',
      'refresh': 'Refresh',
      'filter': 'Filter',
      'sort': 'Sort',
      'clear': 'Clear',
      'apply': 'Apply',
      'reset': 'Reset',
      'select': 'Select',
      'selected': 'Selected',
      'none': 'None',
      'other': 'Other',
      'more': 'More',
      'less': 'Less',
      'show_more': 'Show More',
      'show_less': 'Show Less',
      'view_all': 'View All',
      'view_details': 'View Details',
      'details': 'Details',
      'settings': 'Settings',
      
      // SuperAdmin Expenses Page
      'filter_by_group': 'Filter by Group',
      'all_groups': 'All Groups',
      'grand_total': 'Grand Total',
      'expense_count': 'Expense Count',
      'pending': 'Pending',
      'approved': 'Approved',
      'rejected': 'Rejected',
      'error_loading_data': 'Error Loading Data',
      'no_expenses_found': 'No expenses found',
      'load_more': 'Load More',
      'no_description': 'No description',
      'help': 'Help',
      'about': 'About',
      'version': 'Version',
      'language': 'Language',
      'theme': 'Theme',
      'light': 'Light',
      'dark': 'Dark',
      'system': 'System',
      
      // SuperAdmin Registration
      'superadmin_registration_success': 'SuperAdmin Registration Successful',
      'group_code_generated': 'Group Code Generated',
      'share_with_admins': 'Share this code with your admins to allow them to join your group',
      'copy_group_code': 'Copy Group Code',
      
      // SuperAdmin Cash Page
      'outgoing_transfers': 'Outgoing Transfers',
      'create_outgoing_transfer': 'Create Outgoing Transfer',
      
      // SuperAdmin Expenses Page
      'expense_overview': 'Expense Overview',
      'admin_group_summary': 'Admin Group Summary',
      'view_group_details': 'View Group Details',
      'total_expenses': 'Total Expenses',
      'pending_expenses': 'Pending Expenses',
      'approved_expenses': 'Approved Expenses',
      'rejected_expenses': 'Rejected Expenses',
    },
    'ar': {
      'app_title': 'تطبيق المالية',
      'cash': 'النقد',
      'convert': 'تصريف',
      'expenses': 'المصاريف',
      'export': 'تصدير',
      'fund_box_usd': 'الصندوق (دولار)',
      'set_fund_balance': 'تعيين رصيد الصندوق (دولار)',
      'cancel': 'إلغاء',
      'save': 'حفظ',
      'transfer': 'تحويل',
      'transfers': 'التحويلات',
      'new_transfer': 'تحويل جديد',
      'transfer_created': 'تم إنشاء التحويل بنجاح',
      'transfer_deleted': 'تم حذف التحويل بنجاح',
      'recipient_name': 'اسم المستلم',
      'create_outgoing_transfer': 'إنشاء تحويل صادر',
      'outgoing_transfers': 'التحويلات الصادرة',
      'no_outgoing_transfers': 'لا توجد تحويلات صادرة بعد',
      'no_admin_members_available': 'لا يوجد أعضاء مسؤولين متاحين',
      'fund_box_balance': 'رصيد الصندوق',
      'please_fill_all_fields': 'يرجى ملء جميع الحقول المطلوبة',
      'amount_usd': 'المبلغ بالدولار',
      'converted_amount': 'المبلغ المصرف (دولار ← ليرة سورية)',
      'exchange_rate': 'سعر الصرف (دولار ← ليرة سورية)',
      'converted_total_syp': 'الإجمالي المحول (ليرة سورية)',
      'create': 'إنشاء',
      'edit_conversion': 'تعديل التحويل',
      'edit_transfer_conversion': 'تعديل تحويل الحوالة',
      'refund_delete': 'استرداد وحذف',
      'delete': 'حذف',
      'no_syp_recorded': 'لا يوجد ليرة سورية مسجلة',
      'converted_amount_error': 'لا يمكن أن يتجاوز المبلغ المحول إجمالي مبلغ التحويل',
      'usd_syp_rate': 'سعر الدولار ← الليرة السورية',
      'usd': 'دولار',
      'syp': 'ليرة سورية',
      'try': 'ليرة تركية',
      'currency': 'العملة',
      'all': 'الكل',
      'add_expense': 'إضافة فاتورة',
      'new_expense': 'فاتورة جديدة',
      'edit_expense': 'تعديل الفاتورة',
      'item_description': 'وصف العنصر *',
      'expense_date': 'تاريخ الفاتورة',
      'price_usd': 'السعر بالدولار',
      'price_syp': 'السعر بالسوري',
      'price_try': 'السعر بالتركي',
      'invoice_status': 'حالة الفاتورة',
      'invoice_available': 'فاتورة متوفرة',
      'no_invoice_available': 'لا توجد فاتورة',
      'no_file_selected': 'لم يتم اختيار ملف',
      'upload': 'رفع',
      'edit': 'تعديل',
      'date': 'التاريخ',
      'today': 'اليوم',
      'this_week': 'هذا الأسبوع',
      'this_month': 'هذا الشهر',
      'custom': 'مخصص',
      'export_pdf': 'تصدير PDF',
      'export_excel': 'تصدير Excel',
      'expenses_list': 'قائمة الفواتير',
      'description': 'الوصف',
      'invoice': 'فاتورة',
      'yes': 'نعم',
      'no': 'لا',
      'outgoing': 'الصادر',
      'incoming': 'الوارد',
      'add_incoming': 'إضافة وارد',
      'new_incoming': 'وارد جديد',
      'edit_incoming': 'تعديل الوارد',
      'transaction_date': 'تاريخ المعاملة',
      'search': 'بحث',
      'search_by_name': 'البحث باسم المستلم',
      'this_year': 'هذه السنة',
      'summary': 'المجموع',
      'total': 'الإجمالي',
      'take_photo': 'التقاط صورة',
      'from_gallery': 'من المعرض',
      'photo_saved': 'تم حفظ الصورة بنجاح',
      'no_camera': 'لا توجد كاميرا متاحة',
      'export_cash': 'تصدير النقد',
      'export_invoices': 'تصدير الفواتير',
      'add_exchange': 'إضافة صرف',
      'exchange_history': 'سجل الصرف',
      'no_exchanges': 'لا يوجد سجل صرف',
      'cash_transactions': 'معاملات النقد',
      'invoice_images': 'صور الفواتير',
      'no_invoice_images': 'لا توجد صور فواتير',
      'welcome': 'مرحباً',
      'login': 'تسجيل الدخول',
      'register': 'إنشاء حساب جديد',
      'username': 'اسم المستخدم',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'confirm_password': 'تأكيد كلمة المرور',
      'forgot_password': 'نسيت كلمة المرور؟',
      'remember_me': 'تذكرني',
      'logout': 'تسجيل الخروج',
      'profile': 'الملف الشخصي',
      'account_settings': 'إعدادات الحساب',
      'change_password': 'تغيير كلمة المرور',
      'invalid_credentials': 'بيانات الدخول غير صحيحة',
      'registration_success': 'تم إنشاء الحساب بنجاح',
      'weak_password': 'كلمة المرور ضعيفة',
      'email_already_exists': 'البريد الإلكتروني مستخدم بالفعل',
      'username_already_exists': 'اسم المستخدم مستخدم بالفعل',
      'welcome_back': 'مرحباً بعودتك!',
      'sign_in_to_continue': 'سجل الدخول للمتابعة',
      'create_your_account': 'إنشاء حساب جديد',
      'fill_details_to_start': 'املأ البيانات للبدء',
      'dont_have_account': 'ليس لديك حساب؟',
      'already_have_account': 'لديك حساب بالفعل؟',
      'sign_up': 'إنشاء حساب',
      'password_requirements': 'يجب أن تحتوي كلمة المرور على 8 أحرف على الأقل، حرف كبير، حرف صغير، ورقم',
      'manage_finances': 'إدارة أموالك بسهولة وأمان',
      'skip': 'تخطي',
      'next': 'التالي',
      'get_started': 'ابدأ الآن',
      'onboarding_cash_management_title': 'إدارة النقد',
      'onboarding_cash_management_desc': 'تتبع رصيد صندوقك، إدارة التحويلات، ومراقبة المعاملات الواردة في مكان واحد.',
      'onboarding_expenses_title': 'تتبع المصاريف',
      'onboarding_expenses_desc': 'سجل وصنف مصاريفك مع دعم مسح الفواتير لتوثيق سهل.',
      'onboarding_transfers_title': 'تحويل الأموال',
      'onboarding_transfers_desc': 'أرسل الأموال مع تحويل العملات التلقائي وتتبع أسعار الصرف.',
      'onboarding_exports_title': 'التصدير والتقارير',
      'onboarding_exports_desc': 'أنشئ تقارير PDF و Excel لبياناتك المالية مع فلاتر قابلة للتخصيص.',
      'view_tutorial': 'عرض الدليل',
      'syncing': 'جاري المزامنة...',
      'sync_completed': 'تمت المزامنة بنجاح',
      'sync_failed': 'فشلت المزامنة',
      'retry_sync': 'إعادة المحاولة',
      'sync_retry': 'إعادة المحاولة',
      'sync_all': 'مزامنة الكل',
      'sync_in_progress': 'المزامنة قيد التنفيذ',
      'admin_dashboard': 'لوحة تحكم المدير',
      'statistics': 'الإحصائيات',
      'total_users': 'إجمالي المستخدمين',
      'total_expenses': 'إجمالي الفواتير',
      'pending_sync': 'في انتظار المزامنة',
      'total_amount': 'المبلغ الإجمالي',
      'recent_user_expenses': 'فواتير المستخدمين الأخيرة',
      'user_activity_summary': 'ملخص نشاط المستخدمين',
      'created_by': 'أنشئ بواسطة',
      'unknown_user': 'مستخدم غير معروف',
      'no_expenses_yet': 'لا توجد فواتير بعد',
      'no_user_activity': 'لا يوجد نشاط للمستخدمين',
      'sync_pending': 'قيد الانتظار',
      'sync_syncing': 'جاري المزامنة',
      'sync_synced': 'تمت المزامنة',
      'sync_status': 'حالة المزامنة',
      'all_users': 'جميع المستخدمين',
      'all_statuses': 'جميع الحالات',
      'user': 'المستخدم',
      'filter_by_user': 'تصفية حسب المستخدم',
      'filter_by_recipient': 'تصفية حسب المستلم',
      'total_syp': 'الإجمالي بالليرة السورية',
      'must_select_same_user': 'يجب أن تختار نفس المستخدم لسجل الصرافة والمصاريف حتى يتم تصدير الملف',
      'export_exchanges': 'تصدير الصرافة',
      'combined_export': 'تصدير مجمع',
      'export_user_data': 'تصدير بيانات المستخدم',
      'please_select_user': 'الرجاء اختيار مستخدم أولاً',
      'export_error': 'خطأ في التصدير',
      'view_invoice': 'عرض الفاتورة',
      'no_invoice_image': 'لا توجد صورة فاتورة',
      'failed_to_load_image': 'فشل تحميل الصورة',
      'invoice_image': 'صورة الفاتورة',
      'unauthorized_access': 'وصول غير مصرح به',
      'no_data_available': 'لا توجد بيانات متاحة',
      'retry': 'إعادة المحاولة',
      'expense_created': 'تم إنشاء الفاتورة بنجاح',
      'expense_updated': 'تم تحديث الفاتورة بنجاح',
      'expense_deleted': 'تم حذف الفاتورة بنجاح',
      'organization': 'المنظمة',
      'department': 'القسم',
      'selectOrganization': 'اختر المنظمة',
      'selectDepartment': 'اختر القسم',
      'organizationRequired': 'الرجاء اختيار المنظمة',
      'departmentRequired': 'الرجاء اختيار القسم',
      'regularUser': 'مستخدم عادي',
      'adminUser': 'مدير',
      'userType': 'نوع المستخدم',
      
      // Admin Group Management
      'admin_group.group_code': 'رمز المجموعة',
      'admin_group.group_name': 'اسم المجموعة',
      'admin_group.members_count': 'الأعضاء',
      'admin_group.copy_code': 'نسخ',
      'admin_group.copied': 'تم النسخ!',
      'admin_group.regenerate_code': 'إعادة إنشاء',
      'admin_group.remove_member': 'إزالة',
      'admin_group.join_group': 'الانضمام للمجموعة',
      'admin_group.my_group': 'مجموعتي',
      'admin_group.group_management': 'إدارة المجموعة',
      'admin_group.enter_group_code': 'أدخل رمز المجموعة',
      'admin_group.group_code_hint': '6 أحرف',
      'admin_group.get_from_admin': 'احصل على هذا من المسؤول',
      'admin_group.share_with_team': 'شارك هذا الرمز مع أعضاء فريقك',
      'admin_group.confirm_remove': 'هل أنت متأكد من إزالة هذا العضو من المجموعة؟',
      'admin_group.confirm_remove_title': 'إزالة عضو',
      'admin_group.confirm_regenerate': 'إعادة الإنشاء ستلغي الرمز القديم. هل تريد المتابعة؟',
      'admin_group.joined_at': 'انضم في',
      'admin_group.admin_contact': 'المسؤول',
      'admin_group.contact_admin_to_leave': 'اتصل بالمسؤول لمغادرة المجموعة',
      'admin_group.admin_badge': 'مدير',
      'admin_group.cannot_remove_self': 'لا يمكنك إزالة نفسك من المجموعة',
      'admin_group.search_members': 'البحث عن الأعضاء...',
      'admin_group.filter_by_department': 'تصفية حسب القسم',
      'admin_group.all_departments': 'جميع الأقسام',
      'admin_group.no_members_found': 'لم يتم العثور على أعضاء مطابقين للفلاتر',
      'admin_group.no_members_yet': 'لا يوجد أعضاء في هذه المجموعة بعد',
      'admin_group.loading_members': 'جاري تحميل الأعضاء...',
      'admin_group.clear_filters': 'مسح الفلاتر',
      'admin_group.code_too_short': 'يجب أن يكون الرمز 6 أحرف',
      'admin_group.code_too_long': 'يجب أن يكون الرمز 6 أحرف بالضبط',
      'admin_group.code_invalid_chars': 'يجب أن يحتوي الرمز على أحرف وأرقام فقط',
      'admin_group.code_required': 'رمز المجموعة مطلوب',
      'admin_group.code_must_be_6': 'يجب أن يكون الرمز 6 أحرف بالضبط',
      'admin_group.code_requirements': 'متطلبات الرمز:',
      'admin_group.join_instructions': 'أدخل رمز المجموعة المكون من 6 أحرف المقدم من المسؤول للانضمام إلى مجموعته.',
      'admin_group.join_help': 'ليس لديك رمز؟ اتصل بالمسؤول.',
      
      // Success messages
      'admin_group.code_copied': 'تم نسخ رمز المجموعة',
      'admin_group.member_removed': 'تمت إزالة العضو بنجاح',
      'admin_group.code_regenerated': 'تم إعادة إنشاء رمز المجموعة بنجاح',
      'admin_group.joined_group': 'تم الانضمام للمجموعة بنجاح',
      
      // Error messages
      'admin_group.invalid_code': 'رمز المجموعة المحدد غير صالح',
      'admin_group.already_in_group': 'أنت بالفعل في مجموعة',
      'admin_group.admin_cannot_join': 'لا يمكن للمسؤولين الانضمام لمجموعات أخرى',
      'admin_group.member_not_found': 'المستخدم غير موجود أو ليس في مجموعتك',
      
      // Profile Page
      'member_since': 'عضو منذ',
      'edit_profile': 'تعديل الملف الشخصي',
      'edit_profile_title': 'تعديل الملف الشخصي',
      'profile_picture_updated': 'تم تحديث صورة الملف الشخصي بنجاح',
      'failed_to_load_profile': 'فشل تحميل الملف الشخصي',
      'group_management': 'إدارة المجموعة',
      'my_group': 'مجموعتي',
      'database_management': 'إدارة قاعدة البيانات',
      'logout_confirm_title': 'تسجيل الخروج',
      'logout_confirm_message': 'هل أنت متأكد من تسجيل الخروج؟',
      'choose_from_gallery': 'اختر من المعرض',
      'failed_to_pick_image': 'فشل اختيار الصورة',
      
      // Profile Statistics
      'statistics': 'الإحصائيات',
      'total_expenses_count': 'إجمالي الفواتير',
      'total_transfers_count': 'إجمالي التحويلات',
      'total_incoming_count': 'إجمالي الوارد',
      'total_exchanges_count': 'إجمالي الصرف',
      'total_transactions': 'إجمالي المعاملات',
      'account_age': 'عمر الحساب',
      'last_activity': 'آخر نشاط',
      
      // Audit Logs
      'audit_logs': 'سجلات التدقيق',
      'feature_not_available': 'الميزة غير متاحة',
      'audit_logs_admin_only': 'سجلات التدقيق متاحة فقط في نسخة المدير.',
      'access_denied': 'تم رفض الوصول',
      'admin_privileges_required': 'مطلوب صلاحيات المدير لعرض سجلات التدقيق.',
      'no_audit_logs_found': 'لم يتم العثور على سجلات تدقيق',
      'audit_log_details': 'تفاصيل سجل التدقيق',
      'action': 'الإجراء',
      'entity_type': 'نوع الكيان',
      'entity_id': 'معرف الكيان',
      'user_id': 'معرف المستخدم',
      'ip_address': 'عنوان IP',
      'user_agent': 'وكيل المستخدم',
      'changes': 'التغييرات',
      'created_at': 'تم الإنشاء في',
      
      // Exchange Feature
      'create_exchange': 'إنشاء صرف',
      'select_transfer': 'اختر التحويل',
      'no_transfers_available': 'لا توجد تحويلات متاحة من المدير',
      'transfer_balance': 'رصيد التحويل',
      'original_amount': 'الأصلي',
      'exchanged': 'المصروف',
      'remaining': 'المتبقي',
      'exchange_details': 'تفاصيل الصرف',
      'amount_syp': 'المبلغ بالليرة السورية',
      'exchange_created_success': 'تم إنشاء الصرف بنجاح!',
      'please_select_transfer': 'الرجاء اختيار تحويل أولاً',
      'amount_exceeds_balance': 'المبلغ يتجاوز الرصيد المتبقي',
      'no_exchanges_yet': 'لا يوجد صرف بعد',
      'create_first_exchange': 'أنشئ أول صرف من تحويل',
      'exchange_date': 'تاريخ الصرف',
      'you_will_receive': 'سوف تستلم',
      'select_date': 'اختر التاريخ',
      'amount_usd_required': 'المبلغ بالدولار مطلوب',
      'exchange_rate_required': 'سعر الصرف مطلوب',
      'notes': 'ملاحظات',
      'optional': 'اختياري',
      'please_enter_amount': 'الرجاء إدخال المبلغ',
      'invalid_amount': 'مبلغ غير صالح',
      'please_enter_rate': 'الرجاء إدخال سعر الصرف',
      'invalid_rate': 'سعر صرف غير صالح',
      'recipient': 'المستلم',
      'rate': 'السعر',
      'no_data_available': 'لا توجد بيانات متاحة',
      
      // Admin Group - Additional
      'admin_group.no_group_found': 'لم يتم العثور على مجموعة',
      'admin_group.not_in_group': 'أنت لست في مجموعة',
      'admin_group.not_in_group_desc': 'انضم إلى مجموعة باستخدام رمز مقدم من المسؤول للوصول إلى البيانات المالية المشتركة.',
      'admin_group.join_description': 'أدخل رمز المجموعة المقدم من المسؤول للانضمام إلى مجموعته والوصول إلى البيانات المالية المشتركة.',
      'admin_group.help_title': 'تحتاج مساعدة؟',
      'admin_group.help_1': 'رمز المجموعة يتكون من 6 أحرف',
      'admin_group.help_2': 'احصل على الرمز من المسؤول',
      'admin_group.help_3': 'يمكنك أن تكون في مجموعة واحدة فقط في وقت واحد',
      'admin_group.help_4': 'اتصل بالمسؤول إذا كنت بحاجة لمغادرة المجموعة',
      
      // Export Page
      'expenses_list_title': 'قائمة الفواتير',
      'sum': 'المجموع',
      'export_error': 'خطأ في التصدير',
      'no_expenses_to_export': 'لا توجد فواتير للتصدير',
      'no_invoices_to_export': 'لا توجد فواتير للتصدير',
      
      // Filters
      'filter_by_date': 'تصفية حسب التاريخ',
      'filter_by_user': 'تصفية حسب المستخدم',
      'all_dates': 'كل التواريخ',
      'all_users': 'كل المستخدمين',
      'custom_range': 'نطاق مخصص',
      'clear_filters': 'مسح التصفية',
      
      // Database Management
      'clear_all_data': 'مسح جميع البيانات',
      'clear_all_data_warning': 'سيؤدي هذا إلى حذف جميع البيانات من قاعدة البيانات بما في ذلك:\n\n• جميع الفواتير\n• جميع التحويلات\n• جميع المعاملات الواردة\n• جميع سجلات الصندوق\n• جميع عمليات الصرف\n\nلا يمكن التراجع عن هذا الإجراء!',
      'delete_all_data': 'حذف جميع البيانات',
      'all_data_cleared': '✓ تم مسح جميع البيانات بنجاح',
      'error_clearing_data': 'خطأ في مسح البيانات',
      'error_loading_stats': 'خطأ في تحميل الإحصائيات',
      'go_back': 'رجوع',
      
      // Common UI
      'loading': 'جاري التحميل...',
      'error': 'خطأ',
      'success': 'نجح',
      'warning': 'تحذير',
      'info': 'معلومات',
      'close': 'إغلاق',
      'ok': 'موافق',
      'confirm': 'تأكيد',
      'back': 'رجوع',
      'continue': 'متابعة',
      'submit': 'إرسال',
      'update': 'تحديث',
      'refresh': 'تحديث',
      'filter': 'تصفية',
      'sort': 'ترتيب',
      'clear': 'مسح',
      'apply': 'تطبيق',
      'reset': 'إعادة تعيين',
      'select': 'اختر',
      'selected': 'محدد',
      'none': 'لا شيء',
      'other': 'آخر',
      'more': 'المزيد',
      'less': 'أقل',
      'show_more': 'عرض المزيد',
      'show_less': 'عرض أقل',
      'view_all': 'عرض الكل',
      'view_details': 'عرض التفاصيل',
      'details': 'التفاصيل',
      'settings': 'الإعدادات',
      
      // SuperAdmin Expenses Page
      'filter_by_group': 'تصفية حسب المجموعة',
      'all_groups': 'جميع المجموعات',
      'grand_total': 'الإجمالي الكلي',
      'expense_count': 'عدد الفواتير',
      'pending': 'قيد الانتظار',
      'approved': 'موافق عليها',
      'rejected': 'مرفوضة',
      'error_loading_data': 'خطأ في تحميل البيانات',
      'no_expenses_found': 'لم يتم العثور على فواتير',
      'load_more': 'تحميل المزيد',
      'no_description': 'لا يوجد وصف',
      'help': 'مساعدة',
      'about': 'حول',
      'version': 'الإصدار',
      'language': 'اللغة',
      'theme': 'المظهر',
      'light': 'فاتح',
      'dark': 'داكن',
      'system': 'النظام',
      
      // SuperAdmin Registration
      'superadmin_registration_success': 'تم تسجيل المدير الأعلى بنجاح',
      'group_code_generated': 'تم إنشاء رمز المجموعة',
      'share_with_admins': 'شارك هذا الرمز مع المسؤولين للسماح لهم بالانضمام إلى مجموعتك',
      'copy_group_code': 'نسخ رمز المجموعة',
      
      // SuperAdmin Cash Page
      'outgoing_transfers': 'التحويلات الصادرة',
      'create_outgoing_transfer': 'إنشاء تحويل صادر',
      
      // SuperAdmin Expenses Page
      'expense_overview': 'نظرة عامة على الفواتير',
      'admin_group_summary': 'ملخص مجموعة المسؤولين',
      'view_group_details': 'عرض تفاصيل المجموعة',
      'total_expenses': 'إجمالي الفواتير',
      'pending_expenses': 'الفواتير قيد الانتظار',
      'approved_expenses': 'الفواتير الموافق عليها',
      'rejected_expenses': 'الفواتير المرفوضة',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Authentication getters
  String? get welcome => translate('welcome');
  String? get login => translate('login');
  String? get register => translate('register');
  String? get username => translate('username');
  String? get email => translate('email');
  String? get password => translate('password');
  String? get confirmPassword => translate('confirm_password');
  String? get forgotPassword => translate('forgot_password');
  String? get rememberMe => translate('remember_me');
  String? get logout => translate('logout');
  String? get profile => translate('profile');
  String? get accountSettings => translate('account_settings');
  String? get changePassword => translate('change_password');
  
  // Authentication error messages
  String? get invalidCredentials => translate('invalid_credentials');
  String? get registrationSuccess => translate('registration_success');
  String? get weakPassword => translate('weak_password');
  String? get emailAlreadyExists => translate('email_already_exists');
  String? get usernameAlreadyExists => translate('username_already_exists');
  
  // Authentication UI messages
  String? get welcomeBack => translate('welcome_back');
  String? get signInToContinue => translate('sign_in_to_continue');
  String? get createYourAccount => translate('create_your_account');
  String? get fillDetailsToStart => translate('fill_details_to_start');
  String? get dontHaveAccount => translate('dont_have_account');
  String? get alreadyHaveAccount => translate('already_have_account');
  String? get signUp => translate('sign_up');
  String? get passwordRequirements => translate('password_requirements');
  String? get manageFinances => translate('manage_finances');
  
  // Onboarding getters
  String? get skip => translate('skip');
  String? get next => translate('next');
  String? get getStarted => translate('get_started');
  String? get onboardingCashManagementTitle => translate('onboarding_cash_management_title');
  String? get onboardingCashManagementDesc => translate('onboarding_cash_management_desc');
  String? get onboardingExpensesTitle => translate('onboarding_expenses_title');
  String? get onboardingExpensesDesc => translate('onboarding_expenses_desc');
  String? get onboardingTransfersTitle => translate('onboarding_transfers_title');
  String? get onboardingTransfersDesc => translate('onboarding_transfers_desc');
  String? get onboardingExportsTitle => translate('onboarding_exports_title');
  String? get onboardingExportsDesc => translate('onboarding_exports_desc');
  String? get viewTutorial => translate('view_tutorial');
  
  // Organizational hierarchy getters
  String? get organization => translate('organization');
  String? get department => translate('department');
  String? get selectOrganization => translate('selectOrganization');
  String? get selectDepartment => translate('selectDepartment');
  String? get organizationRequired => translate('organizationRequired');
  String? get departmentRequired => translate('departmentRequired');
  String? get regularUser => translate('regularUser');
  String? get adminUser => translate('adminUser');
  String? get userType => translate('userType');
  
  // Admin Group Management getters
  String? get adminGroupCode => translate('admin_group.group_code');
  String? get adminGroupName => translate('admin_group.group_name');
  String? get adminGroupMembersCount => translate('admin_group.members_count');
  String? get adminGroupCopyCode => translate('admin_group.copy_code');
  String? get adminGroupCopied => translate('admin_group.copied');
  String? get adminGroupRegenerateCode => translate('admin_group.regenerate_code');
  String? get adminGroupRemoveMember => translate('admin_group.remove_member');
  String? get adminGroupJoinGroup => translate('admin_group.join_group');
  String? get adminGroupMyGroup => translate('admin_group.my_group');
  String? get adminGroupManagement => translate('admin_group.group_management');
  String? get adminGroupEnterCode => translate('admin_group.enter_group_code');
  String? get adminGroupCodeHint => translate('admin_group.group_code_hint');
  String? get adminGroupGetFromAdmin => translate('admin_group.get_from_admin');
  String? get adminGroupShareWithTeam => translate('admin_group.share_with_team');
  String? get adminGroupConfirmRemove => translate('admin_group.confirm_remove');
  String? get adminGroupConfirmRemoveTitle => translate('admin_group.confirm_remove_title');
  String? get adminGroupConfirmRegenerate => translate('admin_group.confirm_regenerate');
  String? get adminGroupJoinedAt => translate('admin_group.joined_at');
  String? get adminGroupAdminContact => translate('admin_group.admin_contact');
  String? get adminGroupContactAdminToLeave => translate('admin_group.contact_admin_to_leave');
  String? get adminGroupAdminBadge => translate('admin_group.admin_badge');
  String? get adminGroupCannotRemoveSelf => translate('admin_group.cannot_remove_self');
  String? get adminGroupSearchMembers => translate('admin_group.search_members');
  String? get adminGroupFilterByDepartment => translate('admin_group.filter_by_department');
  String? get adminGroupAllDepartments => translate('admin_group.all_departments');
  String? get adminGroupNoMembersFound => translate('admin_group.no_members_found');
  String? get adminGroupNoMembersYet => translate('admin_group.no_members_yet');
  String? get adminGroupLoadingMembers => translate('admin_group.loading_members');
  String? get adminGroupClearFilters => translate('admin_group.clear_filters');
  String? get adminGroupCodeTooShort => translate('admin_group.code_too_short');
  String? get adminGroupCodeTooLong => translate('admin_group.code_too_long');
  String? get adminGroupCodeInvalidChars => translate('admin_group.code_invalid_chars');
  String? get adminGroupCodeRequired => translate('admin_group.code_required');
  String? get adminGroupCodeMustBe6 => translate('admin_group.code_must_be_6');
  String? get adminGroupCodeRequirements => translate('admin_group.code_requirements');
  String? get adminGroupJoinInstructions => translate('admin_group.join_instructions');
  String? get adminGroupJoinHelp => translate('admin_group.join_help');
  
  // Admin Group success messages
  String? get adminGroupCodeCopied => translate('admin_group.code_copied');
  String? get adminGroupMemberRemoved => translate('admin_group.member_removed');
  String? get adminGroupCodeRegenerated => translate('admin_group.code_regenerated');
  String? get adminGroupJoinedGroup => translate('admin_group.joined_group');
  
  // Admin Group error messages
  String? get adminGroupInvalidCode => translate('admin_group.invalid_code');
  String? get adminGroupAlreadyInGroup => translate('admin_group.already_in_group');
  String? get adminGroupAdminCannotJoin => translate('admin_group.admin_cannot_join');
  String? get adminGroupMemberNotFound => translate('admin_group.member_not_found');
  
  // Profile Page getters
  String? get memberSince => translate('member_since');
  String? get editProfile => translate('edit_profile');
  String? get editProfileTitle => translate('edit_profile_title');
  String? get profilePictureUpdated => translate('profile_picture_updated');
  String? get failedToLoadProfile => translate('failed_to_load_profile');
  String? get groupManagement => translate('group_management');
  String? get myGroup => translate('my_group');
  String? get databaseManagement => translate('database_management');
  String? get logoutConfirmTitle => translate('logout_confirm_title');
  String? get logoutConfirmMessage => translate('logout_confirm_message');
  String? get chooseFromGallery => translate('choose_from_gallery');
  String? get failedToPickImage => translate('failed_to_pick_image');
  
  // Profile Statistics getters
  String? get statistics => translate('statistics');
  String? get totalExpensesCount => translate('total_expenses_count');
  String? get totalTransfersCount => translate('total_transfers_count');
  String? get totalIncomingCount => translate('total_incoming_count');
  String? get totalExchangesCount => translate('total_exchanges_count');
  
  // Audit Logs getters
  String? get auditLogs => translate('audit_logs');
  String? get featureNotAvailable => translate('feature_not_available');
  String? get auditLogsAdminOnly => translate('audit_logs_admin_only');
  String? get accessDenied => translate('access_denied');
  String? get adminPrivilegesRequired => translate('admin_privileges_required');
  String? get noAuditLogsFound => translate('no_audit_logs_found');
  String? get auditLogDetails => translate('audit_log_details');
  String? get action => translate('action');
  String? get entityType => translate('entity_type');
  String? get entityId => translate('entity_id');
  String? get userId => translate('user_id');
  String? get ipAddress => translate('ip_address');
  String? get userAgent => translate('user_agent');
  String? get changes => translate('changes');
  String? get createdAt => translate('created_at');
  
  // Exchange Feature getters
  String? get createExchange => translate('create_exchange');
  String? get selectTransfer => translate('select_transfer');
  String? get noTransfersAvailable => translate('no_transfers_available');
  String? get transferBalance => translate('transfer_balance');
  String? get originalAmount => translate('original_amount');
  String? get exchanged => translate('exchanged');
  String? get remaining => translate('remaining');
  String? get exchangeDetails => translate('exchange_details');
  String? get amountSyp => translate('amount_syp');
  String? get exchangeCreatedSuccess => translate('exchange_created_success');
  String? get pleaseSelectTransfer => translate('please_select_transfer');
  String? get amountExceedsBalance => translate('amount_exceeds_balance');
  String? get noExchangesYet => translate('no_exchanges_yet');
  String? get createFirstExchange => translate('create_first_exchange');
  String? get exchangeDate => translate('exchange_date');
  String? get youWillReceive => translate('you_will_receive');
  String? get selectDate => translate('select_date');
  String? get amountUsdRequired => translate('amount_usd_required');
  String? get exchangeRateRequired => translate('exchange_rate_required');
  String? get notes => translate('notes');
  String? get optional => translate('optional');
  
  // Export Page getters
  String? get expensesListTitle => translate('expenses_list_title');
  String? get sum => translate('sum');
  String? get exportError => translate('export_error');
  
  // Common UI getters
  String? get loading => translate('loading');
  String? get error => translate('error');
  String? get success => translate('success');
  String? get warning => translate('warning');
  String? get info => translate('info');
  String? get close => translate('close');
  String? get ok => translate('ok');
  String? get confirm => translate('confirm');
  String? get back => translate('back');
  String? get continueText => translate('continue');
  String? get submit => translate('submit');
  String? get update => translate('update');
  String? get refresh => translate('refresh');
  String? get filter => translate('filter');
  String? get sort => translate('sort');
  String? get clear => translate('clear');
  String? get apply => translate('apply');
  String? get reset => translate('reset');
  String? get select => translate('select');
  String? get selected => translate('selected');
  String? get none => translate('none');
  String? get other => translate('other');
  String? get more => translate('more');
  String? get less => translate('less');
  String? get showMore => translate('show_more');
  String? get showLess => translate('show_less');
  String? get viewAll => translate('view_all');
  String? get viewDetails => translate('view_details');
  String? get details => translate('details');
  String? get settings => translate('settings');
  String? get help => translate('help');
  String? get about => translate('about');
  String? get version => translate('version');
  String? get language => translate('language');
  String? get theme => translate('theme');
  String? get light => translate('light');
  String? get dark => translate('dark');
  String? get system => translate('system');
  
  // SuperAdmin Registration getters
  String? get superadminRegistrationSuccess => translate('superadmin_registration_success');
  String? get groupCodeGenerated => translate('group_code_generated');
  String? get shareWithAdmins => translate('share_with_admins');
  String? get copyGroupCode => translate('copy_group_code');
  
  // SuperAdmin Cash Page getters
  String? get outgoingTransfers => translate('outgoing_transfers');
  String? get createOutgoingTransfer => translate('create_outgoing_transfer');
  
  // SuperAdmin Expenses Page getters
  String? get expenseOverview => translate('expense_overview');
  String? get adminGroupSummary => translate('admin_group_summary');
  String? get viewGroupDetails => translate('view_group_details');
  String? get totalExpenses => translate('total_expenses');
  String? get pendingExpenses => translate('pending_expenses');
  String? get approvedExpenses => translate('approved_expenses');
  String? get rejectedExpenses => translate('rejected_expenses');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
