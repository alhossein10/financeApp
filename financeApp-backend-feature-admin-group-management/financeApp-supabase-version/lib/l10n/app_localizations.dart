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
      'recipient_name': 'Recipient name',
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
      'recipient_name': 'اسم المستلم',
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
