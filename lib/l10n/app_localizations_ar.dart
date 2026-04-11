// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'تطبيق المالية';

  @override
  String get cash => 'الصندوق';

  @override
  String get cash_inbox => 'صندوق الوارد';

  @override
  String get cashInbox => 'صندوق الوارد';

  @override
  String get transfer_to_admin => 'تحويل إلى مسؤول';

  @override
  String get select_admin => 'اختر مسؤول';

  @override
  String get no_admins_available => 'لا يوجد مسؤولون متاحون';

  @override
  String get export_success => 'تم التصدير بنجاح';

  @override
  String get convert => 'تصريف';

  @override
  String get expenses => 'المصاريف';

  @override
  String get export => 'تصدير';

  @override
  String get fundBoxUsd => 'الصندوق (دولار)';

  @override
  String get setFundBalance => 'تعيين رصيد الصندوق (دولار)';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get transfer => 'تحويل';

  @override
  String get transfers => 'التحويلات';

  @override
  String get newTransfer => 'تحويل جديد';

  @override
  String get transferCreated => 'تم إنشاء التحويل بنجاح';

  @override
  String get transferDeleted => 'تم حذف التحويل بنجاح';

  @override
  String get recipientName => 'اسم المستلم';

  @override
  String get selectRecipient => 'اختر المستلم';

  @override
  String get createOutgoingTransfer => 'إنشاء تحويل صادر';

  @override
  String get outgoingTransfers => 'التحويلات الصادرة';

  @override
  String get noOutgoingTransfers => 'لا توجد تحويلات صادرة بعد';

  @override
  String get noAdminMembersAvailable => 'لا يوجد أعضاء مسؤولين متاحين';

  @override
  String get fundBoxBalance => 'رصيد الصندوق';

  @override
  String get loadingBalance => 'جاري تحميل الرصيد...';

  @override
  String get pleaseFillAllFields => 'يرجى ملء جميع الحقول المطلوبة';

  @override
  String get amountUsd => 'المبلغ بالدولار';

  @override
  String get convertedAmount => 'المبلغ المصرف (دولار ← ليرة سورية)';

  @override
  String get exchangeRate => 'سعر الصرف (دولار ← ليرة سورية)';

  @override
  String get convertedTotalSyp => 'الإجمالي المحول (ليرة سورية)';

  @override
  String get create => 'إنشاء';

  @override
  String get editConversion => 'تعديل التحويل';

  @override
  String get editTransferConversion => 'تعديل تحويل الحوالة';

  @override
  String get refundDelete => 'استرداد وحذف';

  @override
  String get delete => 'حذف';

  @override
  String get noSypRecorded => 'لا يوجد ليرة سورية مسجلة';

  @override
  String get convertedAmountError =>
      'لا يمكن أن يتجاوز المبلغ المحول إجمالي مبلغ التحويل';

  @override
  String get usdSypRate => 'سعر الدولار ← الليرة السورية';

  @override
  String get usd => 'دولار';

  @override
  String get syp => 'ليرة سورية';

  @override
  String get currencyTry => 'ليرة تركية';

  @override
  String get currency => 'العملة';

  @override
  String get all => 'الكل';

  @override
  String get addExpense => 'إضافة فاتورة';

  @override
  String get newExpense => 'فاتورة جديدة';

  @override
  String get editExpense => 'تعديل الفاتورة';

  @override
  String get itemDescription => 'وصف العنصر *';

  @override
  String get expenseDate => 'تاريخ الفاتورة';

  @override
  String get priceUsd => 'السعر بالدولار';

  @override
  String get priceSyp => 'السعر بالسوري';

  @override
  String get priceTry => 'السعر بالتركي';

  @override
  String get invoiceStatus => 'حالة الفاتورة';

  @override
  String get invoiceAvailable => 'فاتورة متوفرة';

  @override
  String get noInvoiceAvailable => 'لا توجد فاتورة';

  @override
  String get noFileSelected => 'لم يتم اختيار ملف';

  @override
  String get upload => 'رفع';

  @override
  String get edit => 'تعديل';

  @override
  String get date => 'التاريخ';

  @override
  String get today => 'اليوم';

  @override
  String get thisWeek => 'هذا الأسبوع';

  @override
  String get thisMonth => 'هذا الشهر';

  @override
  String get custom => 'مخصص';

  @override
  String get exportPdf => 'تصدير PDF';

  @override
  String get exportExcel => 'تصدير Excel';

  @override
  String get expensesList => 'قائمة الفواتير';

  @override
  String get description => 'الوصف';

  @override
  String get invoice => 'فاتورة';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get outgoing => 'الصادر';

  @override
  String get incoming => 'الوارد';

  @override
  String get addIncoming => 'إضافة وارد';

  @override
  String get newIncoming => 'وارد جديد';

  @override
  String get editIncoming => 'تعديل الوارد';

  @override
  String get transactionDate => 'تاريخ المعاملة';

  @override
  String get search => 'بحث';

  @override
  String get searchByName => 'البحث باسم المستلم';

  @override
  String get thisYear => 'هذه السنة';

  @override
  String get summary => 'المجموع';

  @override
  String get total => 'الإجمالي';

  @override
  String get totalUsd => 'المجموع بالدولار';

  @override
  String get totalSyp => 'الإجمالي بالليرة السورية';

  @override
  String get totalTry => 'الإجمالي بالليرة التركية';

  @override
  String get takePhoto => 'التقاط صورة';

  @override
  String get fromGallery => 'من المعرض';

  @override
  String get photoSaved => 'تم حفظ الصورة بنجاح';

  @override
  String get noCamera => 'لا توجد كاميرا متاحة';

  @override
  String get exportCash => 'تصدير الصندوق';

  @override
  String get exportInvoices => 'تصدير الفواتير';

  @override
  String get addExchange => 'إضافة صرف';

  @override
  String get exchangeHistory => 'سجل التصريف';

  @override
  String get noExchanges => 'لا يوجد سجل تصريف';

  @override
  String get cashTransactions => 'معاملات الصندوق';

  @override
  String get invoiceImages => 'صور الفواتير';

  @override
  String get noInvoiceImages => 'لا توجد صور فواتير';

  @override
  String get welcome => 'مرحباً';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get register => 'إنشاء حساب جديد';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get rememberMe => 'تذكرني';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get accountSettings => 'إعدادات الحساب';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get invalidCredentials => 'بيانات الدخول غير صحيحة';

  @override
  String get registrationSuccess => 'تم إنشاء الحساب بنجاح';

  @override
  String get weakPassword => 'كلمة المرور ضعيفة';

  @override
  String get emailAlreadyExists => 'البريد الإلكتروني مستخدم بالفعل';

  @override
  String get usernameAlreadyExists => 'اسم المستخدم مستخدم بالفعل';

  @override
  String get welcomeBack => 'مرحباً بعودتك!';

  @override
  String get signInToContinue => 'سجل الدخول للمتابعة';

  @override
  String get createYourAccount => 'إنشاء حساب جديد';

  @override
  String get fillDetailsToStart => 'املأ البيانات للبدء';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get passwordRequirements =>
      'يجب أن تحتوي كلمة المرور على 8 أحرف على الأقل، حرف كبير، حرف صغير، ورقم';

  @override
  String get manageFinances => 'إدارة أموالك بسهولة وأمان';

  @override
  String get skip => 'تخطي';

  @override
  String get next => 'التالي';

  @override
  String get getStarted => 'ابدأ الآن';

  @override
  String get onboardingCashManagementTitle => 'إدارة الصندوق';

  @override
  String get onboardingCashManagementDesc =>
      'تتبع رصيد صندوقك، إدارة التحويلات، ومراقبة المعاملات الواردة في مكان واحد.';

  @override
  String get onboardingExpensesTitle => 'تتبع المصاريف';

  @override
  String get onboardingExpensesDesc =>
      'سجل وصنف مصاريفك مع دعم مسح الفواتير لتوثيق سهل.';

  @override
  String get onboardingTransfersTitle => 'تحويل الأموال';

  @override
  String get onboardingTransfersDesc =>
      'أرسل الأموال مع تحويل العملات التلقائي وتتبع أسعار الصرف.';

  @override
  String get onboardingExportsTitle => 'التصدير والتقارير';

  @override
  String get onboardingExportsDesc =>
      'أنشئ تقارير PDF و Excel لبياناتك المالية مع فلاتر قابلة للتخصيص.';

  @override
  String get viewTutorial => 'عرض الدليل';

  @override
  String get syncing => 'جاري المزامنة...';

  @override
  String get syncCompleted => 'تمت المزامنة بنجاح';

  @override
  String get syncFailed => 'فشلت المزامنة';

  @override
  String get retrySync => 'إعادة المحاولة';

  @override
  String get syncRetry => 'إعادة المحاولة';

  @override
  String get syncAll => 'مزامنة الكل';

  @override
  String get syncInProgress => 'المزامنة قيد التنفيذ';

  @override
  String get adminDashboard => 'لوحة تحكم المدير';

  @override
  String get statistics => 'الإحصائيات';

  @override
  String get totalUsers => 'إجمالي المستخدمين';

  @override
  String get totalExpenses => 'إجمالي الفواتير';

  @override
  String get pendingSync => 'في انتظار المزامنة';

  @override
  String get totalAmount => 'المبلغ الإجمالي';

  @override
  String get recentUserExpenses => 'فواتير المستخدمين الأخيرة';

  @override
  String get userActivitySummary => 'ملخص نشاط المستخدمين';

  @override
  String get createdBy => 'أنشئ بواسطة';

  @override
  String get unknownUser => 'مستخدم غير معروف';

  @override
  String get noExpensesYet => 'لا توجد فواتير بعد';

  @override
  String get noUserActivity => 'لا يوجد نشاط للمستخدمين';

  @override
  String get syncPending => 'قيد الانتظار';

  @override
  String get syncSyncing => 'جاري المزامنة';

  @override
  String get syncSynced => 'تمت المزامنة';

  @override
  String get syncStatus => 'حالة المزامنة';

  @override
  String get allUsers => 'جميع المستخدمين';

  @override
  String get allStatuses => 'جميع الحالات';

  @override
  String get user => 'المستخدم';

  @override
  String get filterByUser => 'تصفية حسب المستخدم';

  @override
  String get filterByRecipient => 'تصفية حسب المستلم';

  @override
  String get mustSelectSameUser =>
      'يجب أن تختار نفس المستخدم لسجل الصرافة والمصاريف حتى يتم تصدير الملف';

  @override
  String get exportExchanges => 'تصدير الصرافة';

  @override
  String get combinedExport => 'تصدير مجمع';

  @override
  String get exportUserData => 'تصدير بيانات المستخدم';

  @override
  String get pleaseSelectUser => 'الرجاء اختيار مستخدم أولاً';

  @override
  String get exportError => 'خطأ في التصدير';

  @override
  String get viewInvoice => 'عرض الفاتورة';

  @override
  String get noInvoiceImage => 'لا توجد صورة فاتورة';

  @override
  String get failedToLoadImage => 'فشل تحميل الصورة';

  @override
  String get invoiceImage => 'صورة الفاتورة';

  @override
  String get unauthorizedAccess => 'وصول غير مصرح به';

  @override
  String get noDataAvailable => 'لا توجد بيانات متاحة';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get expenseCreated => 'تم إنشاء الفاتورة بنجاح';

  @override
  String get expenseUpdated => 'تم تحديث الفاتورة بنجاح';

  @override
  String get expenseDeleted => 'تم حذف الفاتورة بنجاح';

  @override
  String get confirmDelete => 'تأكيد الحذف';

  @override
  String get deleteExpenseConfirmation => 'هل أنت متأكد من حذف هذه الفاتورة؟';

  @override
  String get deleteInvoiceConfirmation => 'هل أنت متأكد من حذف هذه الفاتورة؟';

  @override
  String get deleteInvoice => 'حذف الفاتورة';

  @override
  String get remove => 'إزالة';

  @override
  String get organization => 'المنظمة';

  @override
  String get department => 'القسم';

  @override
  String get selectOrganization => 'اختر المنظمة';

  @override
  String get selectDepartment => 'اختر القسم';

  @override
  String get organizationRequired => 'الرجاء اختيار المنظمة';

  @override
  String get departmentRequired => 'الرجاء اختيار القسم';

  @override
  String get regularUser => 'مستخدم عادي';

  @override
  String get adminUser => 'مدير';

  @override
  String get userType => 'نوع المستخدم';

  @override
  String get groupCode => 'رمز المجموعة';

  @override
  String get groupName => 'اسم المجموعة';

  @override
  String get membersCount => 'الأعضاء';

  @override
  String get copyCode => 'نسخ';

  @override
  String get copied => 'تم النسخ!';

  @override
  String get regenerateCode => 'إعادة إنشاء';

  @override
  String get removeMember => 'إزالة';

  @override
  String get joinGroup => 'الانضمام للمجموعة';

  @override
  String get myGroup => 'مجموعتي';

  @override
  String get groupManagement => 'إدارة المجموعة';

  @override
  String get enterGroupCode => 'أدخل رمز المجموعة';

  @override
  String get groupCodeHint => '6 أحرف';

  @override
  String get getFromAdmin => 'احصل على هذا من المسؤول';

  @override
  String get shareWithTeam => 'شارك هذا الرمز مع أعضاء فريقك';

  @override
  String get confirmRemove => 'هل أنت متأكد من إزالة هذا العضو من المجموعة؟';

  @override
  String get confirmRemoveTitle => 'إزالة عضو';

  @override
  String get confirmRegenerate =>
      'إعادة الإنشاء ستلغي الرمز القديم. هل تريد المتابعة؟';

  @override
  String get joinedAt => 'انضم في';

  @override
  String get adminContact => 'المسؤول';

  @override
  String get contactAdminToLeave => 'اتصل بالمسؤول لمغادرة المجموعة';

  @override
  String get adminBadge => 'مدير';

  @override
  String get cannotRemoveSelf => 'لا يمكنك إزالة نفسك من المجموعة';

  @override
  String get searchMembers => 'البحث عن الأعضاء...';

  @override
  String get filterByDepartment => 'تصفية حسب القسم';

  @override
  String get allDepartments => 'جميع الأقسام';

  @override
  String get noMembersFound => 'لم يتم العثور على أعضاء مطابقين للفلاتر';

  @override
  String get noMembersYet => 'لا يوجد أعضاء في هذه المجموعة بعد';

  @override
  String get loadingMembers => 'جاري تحميل الأعضاء...';

  @override
  String get clearFilters => 'مسح الفلاتر';

  @override
  String get codeTooShort => 'يجب أن يكون الرمز 6 أحرف';

  @override
  String get codeTooLong => 'يجب أن يكون الرمز 6 أحرف بالضبط';

  @override
  String get codeInvalidChars => 'يجب أن يحتوي الرمز على أحرف وأرقام فقط';

  @override
  String get codeRequired => 'رمز المجموعة مطلوب';

  @override
  String get codeMustBe6 => 'يجب أن يكون الرمز 6 أحرف بالضبط';

  @override
  String get codeRequirements => 'متطلبات الرمز:';

  @override
  String get joinInstructions =>
      'أدخل رمز المجموعة المكون من 6 أحرف المقدم من المسؤول للانضمام إلى مجموعته.';

  @override
  String get joinHelp => 'ليس لديك رمز؟ اتصل بالمسؤول.';

  @override
  String get codeCopied => 'تم نسخ رمز المجموعة';

  @override
  String get memberRemoved => 'تمت إزالة العضو بنجاح';

  @override
  String get codeRegenerated => 'تم إعادة إنشاء رمز المجموعة بنجاح';

  @override
  String get joinedGroup => 'تم الانضمام للمجموعة بنجاح';

  @override
  String get invalidCode => 'رمز المجموعة المحدد غير صالح';

  @override
  String get alreadyInGroup => 'أنت بالفعل في مجموعة';

  @override
  String get adminCannotJoin => 'لا يمكن للمسؤولين الانضمام لمجموعات أخرى';

  @override
  String get memberNotFound => 'المستخدم غير موجود أو ليس في مجموعتك';

  @override
  String get memberSince => 'عضو منذ';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get editProfileTitle => 'تعديل الملف الشخصي';

  @override
  String get profilePictureUpdated => 'تم تحديث صورة الملف الشخصي بنجاح';

  @override
  String get failedToLoadProfile => 'فشل تحميل الملف الشخصي';

  @override
  String get databaseManagement => 'إدارة قاعدة البيانات';

  @override
  String get logoutConfirmTitle => 'تسجيل الخروج';

  @override
  String get logoutConfirmMessage => 'هل أنت متأكد من تسجيل الخروج؟';

  @override
  String get chooseFromGallery => 'اختر من المعرض';

  @override
  String get failedToPickImage => 'فشل اختيار الصورة';

  @override
  String get totalExpensesCount => 'إجمالي الفواتير';

  @override
  String get totalTransfersCount => 'إجمالي التحويلات';

  @override
  String get totalIncomingCount => 'إجمالي الوارد';

  @override
  String get totalExchangesCount => 'إجمالي الصرف';

  @override
  String get totalTransactions => 'إجمالي المعاملات';

  @override
  String get accountAge => 'عمر الحساب';

  @override
  String get lastActivity => 'آخر نشاط';

  @override
  String get auditLogs => 'سجلات التدقيق';

  @override
  String get featureNotAvailable => 'الميزة غير متاحة';

  @override
  String get auditLogsAdminOnly => 'سجلات التدقيق متاحة فقط في نسخة المدير.';

  @override
  String get accessDenied => 'تم رفض الوصول';

  @override
  String get adminPrivilegesRequired =>
      'مطلوب صلاحيات المدير لعرض سجلات التدقيق.';

  @override
  String get noAuditLogsFound => 'لم يتم العثور على سجلات تدقيق';

  @override
  String get auditLogDetails => 'تفاصيل سجل التدقيق';

  @override
  String get action => 'الإجراء';

  @override
  String get entityType => 'نوع الكيان';

  @override
  String get entityId => 'معرف الكيان';

  @override
  String get userId => 'معرف المستخدم';

  @override
  String get ipAddress => 'عنوان IP';

  @override
  String get userAgent => 'وكيل المستخدم';

  @override
  String get changes => 'التغييرات';

  @override
  String get createdAt => 'تم الإنشاء في';

  @override
  String get createExchange => 'إنشاء صرف';

  @override
  String get selectTransfer => 'اختر التحويل';

  @override
  String get noTransfersAvailable => 'لا توجد تحويلات متاحة من المدير';

  @override
  String get transferBalance => 'رصيد التحويل';

  @override
  String get originalAmount => 'الأصلي';

  @override
  String get exchanged => 'المصروف';

  @override
  String get remaining => 'المتبقي';

  @override
  String get exchangeDetails => 'تفاصيل الصرف';

  @override
  String get amountSyp => 'المبلغ بالليرة السورية';

  @override
  String get amountTry => 'المبلغ بالليرة التركية';

  @override
  String get exchangeCreatedSuccess => 'تم إنشاء الصرف بنجاح!';

  @override
  String get pleaseSelectTransfer => 'الرجاء اختيار تحويل أولاً';

  @override
  String get amountExceedsBalance => 'المبلغ يتجاوز الرصيد المتبقي';

  @override
  String get noExchangesYet => 'لا يوجد صرف بعد';

  @override
  String get createFirstExchange => 'أنشئ أول صرف من تحويل';

  @override
  String get exchangeDate => 'تاريخ الصرف';

  @override
  String get youWillReceive => 'سوف تستلم';

  @override
  String get selectDate => 'اختر التاريخ';

  @override
  String get amountUsdRequired => 'المبلغ بالدولار مطلوب';

  @override
  String get exchangeRateRequired => 'سعر الصرف مطلوب';

  @override
  String get notes => 'ملاحظات';

  @override
  String get optional => 'اختياري';

  @override
  String get pleaseEnterAmount => 'الرجاء إدخال المبلغ';

  @override
  String get invalidAmount => 'مبلغ غير صالح';

  @override
  String get pleaseEnterRate => 'الرجاء إدخال سعر الصرف';

  @override
  String get invalidRate => 'سعر صرف غير صالح';

  @override
  String get recipient => 'المستلم';

  @override
  String get rate => 'السعر';

  @override
  String get noGroupFound => 'لم يتم العثور على مجموعة';

  @override
  String get notInGroup => 'أنت لست في مجموعة';

  @override
  String get notInGroupDesc =>
      'انضم إلى مجموعة باستخدام رمز مقدم من المسؤول للوصول إلى البيانات المالية المشتركة.';

  @override
  String get joinDescription =>
      'أدخل رمز المجموعة المقدم من المسؤول للانضمام إلى مجموعته والوصول إلى البيانات المالية المشتركة.';

  @override
  String get helpTitle => 'تحتاج مساعدة؟';

  @override
  String get help1 => 'رمز المجموعة يتكون من 6 أحرف';

  @override
  String get help2 => 'احصل على الرمز من المسؤول';

  @override
  String get help3 => 'يمكنك أن تكون في مجموعة واحدة فقط في وقت واحد';

  @override
  String get help4 => 'اتصل بالمسؤول إذا كنت بحاجة لمغادرة المجموعة';

  @override
  String get expensesListTitle => 'قائمة الفواتير';

  @override
  String get sum => 'المجموع';

  @override
  String get noExpensesToExport => 'لا توجد مصروفات للتصدير';

  @override
  String get noInvoicesToExport => 'لا توجد فواتير للتصدير';

  @override
  String get filterByDate => 'تصفية حسب التاريخ';

  @override
  String get allDates => 'كل التواريخ';

  @override
  String get customRange => 'نطاق مخصص';

  @override
  String get clearAllData => 'مسح جميع البيانات';

  @override
  String get clearAllDataWarning =>
      'سيؤدي هذا إلى حذف جميع البيانات من قاعدة البيانات بما في ذلك:\\n\\n• جميع الفواتير\\n• جميع التحويلات\\n• جميع المعاملات الواردة\\n• جميع سجلات الصندوق\\n• جميع عمليات الصرف\\n\\nلا يمكن التراجع عن هذا الإجراء!';

  @override
  String get deleteAllData => 'حذف جميع البيانات';

  @override
  String get allDataCleared => '✓ تم مسح جميع البيانات بنجاح';

  @override
  String get errorClearingData => 'خطأ في مسح البيانات';

  @override
  String get errorLoadingStats => 'خطأ في تحميل الإحصائيات';

  @override
  String get goBack => 'رجوع';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get error => 'خطأ';

  @override
  String get success => 'نجح';

  @override
  String get warning => 'تحذير';

  @override
  String get info => 'معلومات';

  @override
  String get close => 'إغلاق';

  @override
  String get ok => 'موافق';

  @override
  String get confirm => 'تأكيد';

  @override
  String get back => 'رجوع';

  @override
  String get continueButton => 'متابعة';

  @override
  String get submit => 'إرسال';

  @override
  String get update => 'تحديث';

  @override
  String get refresh => 'تحديث';

  @override
  String get filter => 'تصفية';

  @override
  String get sort => 'ترتيب';

  @override
  String get clear => 'مسح';

  @override
  String get apply => 'تطبيق';

  @override
  String get reset => 'إعادة تعيين';

  @override
  String get select => 'اختر';

  @override
  String get selected => 'محدد';

  @override
  String get none => 'لا شيء';

  @override
  String get other => 'آخر';

  @override
  String get more => 'المزيد';

  @override
  String get less => 'أقل';

  @override
  String get showMore => 'عرض المزيد';

  @override
  String get showLess => 'عرض أقل';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get viewDetails => 'عرض التفاصيل';

  @override
  String get details => 'التفاصيل';

  @override
  String get settings => 'الإعدادات';

  @override
  String get filterByGroup => 'تصفية حسب المجموعة';

  @override
  String get allGroups => 'جميع المجموعات';

  @override
  String get grandTotal => 'الإجمالي الكلي';

  @override
  String get expenseCount => 'عدد الفواتير';

  @override
  String get pending => 'قيد الانتظار';

  @override
  String get approved => 'موافق عليها';

  @override
  String get rejected => 'مرفوضة';

  @override
  String get errorLoadingData => 'خطأ في تحميل البيانات';

  @override
  String get noExpensesFound => 'لم يتم العثور على مصروفات';

  @override
  String get loadMore => 'تحميل المزيد';

  @override
  String get noDescription => 'لا يوجد وصف';

  @override
  String get help => 'مساعدة';

  @override
  String get about => 'حول';

  @override
  String get version => 'الإصدار';

  @override
  String get language => 'اللغة';

  @override
  String get theme => 'المظهر';

  @override
  String get light => 'فاتح';

  @override
  String get dark => 'داكن';

  @override
  String get system => 'النظام';

  @override
  String get superadminRegistrationSuccess => 'تم تسجيل المدير الأعلى بنجاح';

  @override
  String get groupCodeGenerated => 'تم إنشاء رمز المجموعة';

  @override
  String get shareWithAdmins =>
      'شارك هذا الرمز مع المسؤولين للسماح لهم بالانضمام إلى مجموعتك';

  @override
  String get copyGroupCode => 'نسخ رمز المجموعة';

  @override
  String get expenseOverview => 'نظرة عامة على الفواتير';

  @override
  String get adminGroupSummary => 'ملخص مجموعة المسؤولين';

  @override
  String get viewGroupDetails => 'عرض تفاصيل المجموعة';

  @override
  String get pendingExpenses => 'الفواتير قيد الانتظار';

  @override
  String get approvedExpenses => 'الفواتير الموافق عليها';

  @override
  String get rejectedExpenses => 'الفواتير المرفوضة';

  @override
  String get updateFundBoxBalances => 'تحديث أرصدة الصندوق';

  @override
  String get errorLoadingFundBox => 'خطأ في تحميل الصندوق';

  @override
  String get loadingFundBox => 'جاري تحميل الصندوق...';

  @override
  String get exportCompletedSuccessfully => 'تم التصدير بنجاح';

  @override
  String get failedToLoadImageError => 'فشل تحميل الصورة';

  @override
  String get sypCurrencyFull => 'ليرة سورية (SYP)';

  @override
  String get tryCurrencyFull => 'ليرة تركية (TRY)';

  @override
  String get fifteenDays => '15 يوم';

  @override
  String get monthPeriod => 'شهر';

  @override
  String get allTime => 'كل الوقت';

  @override
  String get filterByCurrency => 'تصفية حسب العملة';

  @override
  String get noExchangesToExport => 'لا توجد عمليات صرف للتصدير';

  @override
  String get english => 'الإنجليزية';

  @override
  String get arabic => 'العربية';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get languageChanged => 'تم تغيير اللغة بنجاح';

  @override
  String get languageSettings => 'إعدادات اللغة';

  @override
  String get appLanguage => 'لغة التطبيق';

  @override
  String get changeLanguage => 'تغيير اللغة';

  @override
  String get hasInvoice => 'يوجد فاتورة';

  @override
  String get selectDateRange => 'اختر نطاق التاريخ';

  @override
  String get myExpenses => 'مصروفاتي';

  @override
  String get me => 'أنا';

  @override
  String get allCurrencies => 'جميع العملات';

  @override
  String get expenseCreatedSuccessfully => 'تم إنشاء المصروف بنجاح';

  @override
  String get createExpense => 'إنشاء مصروف';

  @override
  String get filters => 'الفلاتر';

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get dateRange => 'نطاق التاريخ';

  @override
  String get errorLoadingExpenses => 'خطأ في تحميل المصروفات';

  @override
  String get createFirstExpense => 'أنشئ مصروفك الأول';

  @override
  String get exportData => 'تصدير البيانات';

  @override
  String get activeFilters => 'الفلاتر النشطة من صفحة المصروفات';

  @override
  String get noFiltersApplied => 'لا توجد فلاتر مطبقة - تصدير جميع المصروفات';

  @override
  String get specificUser => 'مستخدم محدد';

  @override
  String get exportWillApplyFilters => 'سيتم تطبيق الفلاتر من صفحة المصروفات';

  @override
  String get exportOptions => 'خيارات التصدير';

  @override
  String get exportToPdf => 'تصدير إلى PDF';

  @override
  String get exportPdfDescription => 'تصدير المصروفات كملف PDF';

  @override
  String get exportToExcel => 'تصدير إلى Excel';

  @override
  String get exportExcelDescription => 'تصدير المصروفات كجدول بيانات Excel';

  @override
  String get exportInvoiceImages => 'تصدير صور الفواتير';

  @override
  String get exportInvoicesDescription =>
      'تصدير جميع صور الفواتير كملف PDF واحد';

  @override
  String get exportCompleted => 'اكتمل التصدير';

  @override
  String get exportMyExpenses => 'تصدير مصروفاتي';

  @override
  String get exportUserInfo => 'معلومات المستخدم للتصدير';
}
