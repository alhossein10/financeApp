// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Finance App';

  @override
  String get cash => 'Cash';

  @override
  String get cash_inbox => 'Cash-Inbox';

  @override
  String get cashInbox => 'Cash-Inbox';

  @override
  String get transfer_to_admin => 'Transfer to Admin';

  @override
  String get select_admin => 'Select Admin';

  @override
  String get no_admins_available => 'No admins available';

  @override
  String get export_success => 'Export successful';

  @override
  String get convert => 'Convert';

  @override
  String get expenses => 'Expenses';

  @override
  String get export => 'Export';

  @override
  String get fundBoxUsd => 'Fund Box (USD)';

  @override
  String get setFundBalance => 'Set Fund Balance (USD)';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get transfer => 'Transfer';

  @override
  String get transfers => 'Transfers';

  @override
  String get newTransfer => 'New Transfer';

  @override
  String get transferCreated => 'Transfer created successfully';

  @override
  String get transferDeleted => 'Transfer deleted successfully';

  @override
  String get recipientName => 'Recipient name';

  @override
  String get selectRecipient => 'Select recipient';

  @override
  String get createOutgoingTransfer => 'Create Outgoing Transfer';

  @override
  String get outgoingTransfers => 'Outgoing Transfers';

  @override
  String get noOutgoingTransfers => 'No outgoing transfers yet';

  @override
  String get noAdminMembersAvailable => 'No admin members available';

  @override
  String get fundBoxBalance => 'Fund Box Balance';

  @override
  String get loadingBalance => 'Loading balance...';

  @override
  String get pleaseFillAllFields => 'Please fill all required fields';

  @override
  String get amountUsd => 'Amount USD';

  @override
  String get convertedAmount => 'Converted Amount (USD → SYP)';

  @override
  String get exchangeRate => 'Exchange Rate (USD → SYP)';

  @override
  String get convertedTotalSyp => 'Converted Total (SYP)';

  @override
  String get create => 'Create';

  @override
  String get editConversion => 'Edit conversion';

  @override
  String get editTransferConversion => 'Edit Transfer Conversion';

  @override
  String get refundDelete => 'Refund and delete';

  @override
  String get delete => 'Delete';

  @override
  String get noSypRecorded => 'No SYP recorded';

  @override
  String get convertedAmountError =>
      'Converted amount cannot exceed total transfer amount';

  @override
  String get usdSypRate => 'USD → SYP rate';

  @override
  String get usd => 'USD';

  @override
  String get syp => 'SYP';

  @override
  String get currencyTry => 'TRY';

  @override
  String get currency => 'Currency';

  @override
  String get all => 'All';

  @override
  String get addExpense => 'Add expense';

  @override
  String get newExpense => 'New Expense';

  @override
  String get editExpense => 'Edit Expense';

  @override
  String get itemDescription => 'Item description *';

  @override
  String get expenseDate => 'Expense Date';

  @override
  String get priceUsd => 'Price USD';

  @override
  String get priceSyp => 'Price SYP';

  @override
  String get priceTry => 'Price TRY';

  @override
  String get invoiceStatus => 'Invoice status';

  @override
  String get invoiceAvailable => 'Invoice available';

  @override
  String get noInvoiceAvailable => 'No invoice available';

  @override
  String get noFileSelected => 'No file selected';

  @override
  String get upload => 'Upload';

  @override
  String get edit => 'Edit';

  @override
  String get date => 'Date';

  @override
  String get today => 'Today';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get custom => 'Custom';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get exportExcel => 'Export Excel';

  @override
  String get expensesList => 'Expenses List';

  @override
  String get description => 'Description';

  @override
  String get invoice => 'Invoice';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get outgoing => 'Outgoing';

  @override
  String get incoming => 'Incoming';

  @override
  String get addIncoming => 'Add Incoming';

  @override
  String get newIncoming => 'New Incoming';

  @override
  String get editIncoming => 'Edit Incoming';

  @override
  String get transactionDate => 'Transaction Date';

  @override
  String get search => 'Search';

  @override
  String get searchByName => 'Search by recipient name';

  @override
  String get thisYear => 'This Year';

  @override
  String get summary => 'Summary';

  @override
  String get total => 'Total';

  @override
  String get totalUsd => 'Total USD';

  @override
  String get totalSyp => 'Total SYP';

  @override
  String get totalTry => 'Total TRY';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get fromGallery => 'From Gallery';

  @override
  String get photoSaved => 'Photo saved successfully';

  @override
  String get noCamera => 'No camera available';

  @override
  String get exportCash => 'Export Cash';

  @override
  String get exportInvoices => 'Export Invoices';

  @override
  String get addExchange => 'Add Exchange';

  @override
  String get exchangeHistory => 'Exchange History';

  @override
  String get noExchanges => 'No exchange history';

  @override
  String get cashTransactions => 'Cash Transactions';

  @override
  String get invoiceImages => 'Invoice Images';

  @override
  String get noInvoiceImages => 'No invoice images found';

  @override
  String get welcome => 'Welcome';

  @override
  String get login => 'Login';

  @override
  String get register => 'Create Account';

  @override
  String get username => 'Username';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get logout => 'Logout';

  @override
  String get profile => 'Profile';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get changePassword => 'Change Password';

  @override
  String get invalidCredentials => 'Invalid credentials';

  @override
  String get registrationSuccess => 'Account created successfully';

  @override
  String get weakPassword => 'Weak password';

  @override
  String get emailAlreadyExists => 'Email already exists';

  @override
  String get usernameAlreadyExists => 'Username already exists';

  @override
  String get welcomeBack => 'Welcome Back!';

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get createYourAccount => 'Create Your Account';

  @override
  String get fillDetailsToStart => 'Fill in the details to get started';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get signUp => 'Sign Up';

  @override
  String get passwordRequirements =>
      'Password must be at least 8 characters with uppercase, lowercase, and number';

  @override
  String get manageFinances => 'Manage your finances easily and securely';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get onboardingCashManagementTitle => 'Cash Management';

  @override
  String get onboardingCashManagementDesc =>
      'Track your fund box balance, manage transfers, and monitor incoming transactions all in one place.';

  @override
  String get onboardingExpensesTitle => 'Expense Tracking';

  @override
  String get onboardingExpensesDesc =>
      'Record and categorize your expenses with invoice scanning support for easy documentation.';

  @override
  String get onboardingTransfersTitle => 'Money Transfers';

  @override
  String get onboardingTransfersDesc =>
      'Send money with automatic currency conversion and exchange rate tracking.';

  @override
  String get onboardingExportsTitle => 'Export & Reports';

  @override
  String get onboardingExportsDesc =>
      'Generate PDF and Excel reports of your financial data with customizable filters.';

  @override
  String get viewTutorial => 'View Tutorial';

  @override
  String get syncing => 'Syncing...';

  @override
  String get syncCompleted => 'Sync completed successfully';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get retrySync => 'Retry Sync';

  @override
  String get syncRetry => 'Retry';

  @override
  String get syncAll => 'Sync All';

  @override
  String get syncInProgress => 'Sync in progress';

  @override
  String get adminDashboard => 'Admin Dashboard';

  @override
  String get statistics => 'Statistics';

  @override
  String get totalUsers => 'Total Users';

  @override
  String get totalExpenses => 'Total Expenses';

  @override
  String get pendingSync => 'Pending Sync';

  @override
  String get totalAmount => 'Total Amount';

  @override
  String get recentUserExpenses => 'Recent User Expenses';

  @override
  String get userActivitySummary => 'User Activity Summary';

  @override
  String get createdBy => 'Created by';

  @override
  String get unknownUser => 'Unknown User';

  @override
  String get noExpensesYet => 'No expenses yet';

  @override
  String get noUserActivity => 'No user activity';

  @override
  String get syncPending => 'Pending';

  @override
  String get syncSyncing => 'Syncing';

  @override
  String get syncSynced => 'Synced';

  @override
  String get syncStatus => 'Sync Status';

  @override
  String get allUsers => 'All Users';

  @override
  String get allStatuses => 'All Statuses';

  @override
  String get user => 'User';

  @override
  String get filterByUser => 'Filter by User';

  @override
  String get filterByRecipient => 'Filter by Recipient';

  @override
  String get mustSelectSameUser =>
      'You must select the same user for exchange history and expenses to export the file';

  @override
  String get exportExchanges => 'Export Exchanges';

  @override
  String get combinedExport => 'Combined Export';

  @override
  String get exportUserData => 'Export User Data';

  @override
  String get pleaseSelectUser => 'Please select a user first';

  @override
  String get exportError => 'Export Error';

  @override
  String get viewInvoice => 'View Invoice';

  @override
  String get noInvoiceImage => 'No invoice image available';

  @override
  String get failedToLoadImage => 'Failed to load image';

  @override
  String get invoiceImage => 'Invoice Image';

  @override
  String get unauthorizedAccess => 'Unauthorized Access';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get retry => 'Retry';

  @override
  String get expenseCreated => 'Expense created successfully';

  @override
  String get expenseUpdated => 'Expense updated successfully';

  @override
  String get expenseDeleted => 'Expense deleted successfully';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get deleteExpenseConfirmation =>
      'Are you sure you want to delete this expense?';

  @override
  String get deleteInvoiceConfirmation =>
      'Are you sure you want to delete this invoice?';

  @override
  String get deleteInvoice => 'Delete Invoice';

  @override
  String get remove => 'Remove';

  @override
  String get organization => 'Organization';

  @override
  String get department => 'Department';

  @override
  String get selectOrganization => 'Select Organization';

  @override
  String get selectDepartment => 'Select Department';

  @override
  String get organizationRequired => 'Please select an organization';

  @override
  String get departmentRequired => 'Please select a department';

  @override
  String get regularUser => 'Regular User';

  @override
  String get adminUser => 'Administrator';

  @override
  String get userType => 'User Type';

  @override
  String get groupCode => 'Group Code';

  @override
  String get groupName => 'Group Name';

  @override
  String get membersCount => 'Members';

  @override
  String get copyCode => 'Copy';

  @override
  String get copied => 'Copied!';

  @override
  String get regenerateCode => 'Regenerate';

  @override
  String get removeMember => 'Remove';

  @override
  String get joinGroup => 'Join Group';

  @override
  String get myGroup => 'My Group';

  @override
  String get groupManagement => 'Group Management';

  @override
  String get enterGroupCode => 'Enter group code';

  @override
  String get groupCodeHint => '6 characters';

  @override
  String get getFromAdmin => 'Get this code from your admin';

  @override
  String get shareWithTeam => 'Share this code with your team members';

  @override
  String get confirmRemove =>
      'Are you sure you want to remove this member from the group?';

  @override
  String get confirmRemoveTitle => 'Remove Member';

  @override
  String get confirmRegenerate =>
      'Regenerating will invalidate the old code. Continue?';

  @override
  String get joinedAt => 'Joined';

  @override
  String get adminContact => 'Admin';

  @override
  String get contactAdminToLeave => 'Contact your admin to leave the group';

  @override
  String get adminBadge => 'Admin';

  @override
  String get cannotRemoveSelf => 'You cannot remove yourself from the group';

  @override
  String get searchMembers => 'Search members...';

  @override
  String get filterByDepartment => 'Filter by Department';

  @override
  String get allDepartments => 'All Departments';

  @override
  String get noMembersFound => 'No members found matching your filters';

  @override
  String get noMembersYet => 'No members in this group yet';

  @override
  String get loadingMembers => 'Loading members...';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get codeTooShort => 'Code must be 6 characters';

  @override
  String get codeTooLong => 'Code must be exactly 6 characters';

  @override
  String get codeInvalidChars => 'Code must contain only letters and numbers';

  @override
  String get codeRequired => 'Group code is required';

  @override
  String get codeMustBe6 => 'Code must be exactly 6 characters';

  @override
  String get codeRequirements => 'Code Requirements:';

  @override
  String get joinInstructions =>
      'Enter the 6-character group code provided by your admin to join their group.';

  @override
  String get joinHelp => 'Don\'t have a code? Contact your admin.';

  @override
  String get codeCopied => 'Group code copied to clipboard';

  @override
  String get memberRemoved => 'Member removed successfully';

  @override
  String get codeRegenerated => 'Group code regenerated successfully';

  @override
  String get joinedGroup => 'Successfully joined the group';

  @override
  String get invalidCode => 'The selected group code is invalid';

  @override
  String get alreadyInGroup => 'You are already in a group';

  @override
  String get adminCannotJoin => 'Admins cannot join other groups';

  @override
  String get memberNotFound => 'User not found or not in your group';

  @override
  String get memberSince => 'Member since';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get profilePictureUpdated => 'Profile picture updated successfully';

  @override
  String get failedToLoadProfile => 'Failed to load profile';

  @override
  String get databaseManagement => 'Database Management';

  @override
  String get logoutConfirmTitle => 'Logout';

  @override
  String get logoutConfirmMessage => 'Are you sure you want to logout?';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get failedToPickImage => 'Failed to pick image';

  @override
  String get totalExpensesCount => 'Total Expenses';

  @override
  String get totalTransfersCount => 'Total Transfers';

  @override
  String get totalIncomingCount => 'Total Incoming';

  @override
  String get totalExchangesCount => 'Total Exchanges';

  @override
  String get totalTransactions => 'Total Transactions';

  @override
  String get accountAge => 'Account Age';

  @override
  String get lastActivity => 'Last Activity';

  @override
  String get auditLogs => 'Audit Logs';

  @override
  String get featureNotAvailable => 'Feature Not Available';

  @override
  String get auditLogsAdminOnly =>
      'Audit logs are only available in the admin version.';

  @override
  String get accessDenied => 'Access Denied';

  @override
  String get adminPrivilegesRequired =>
      'Admin privileges required to view audit logs.';

  @override
  String get noAuditLogsFound => 'No audit logs found';

  @override
  String get auditLogDetails => 'Audit Log Details';

  @override
  String get action => 'Action';

  @override
  String get entityType => 'Entity Type';

  @override
  String get entityId => 'Entity ID';

  @override
  String get userId => 'User ID';

  @override
  String get ipAddress => 'IP Address';

  @override
  String get userAgent => 'User Agent';

  @override
  String get changes => 'Changes';

  @override
  String get createdAt => 'Created At';

  @override
  String get createExchange => 'Create Exchange';

  @override
  String get selectTransfer => 'Select Transfer';

  @override
  String get noTransfersAvailable => 'No transfers available from admin';

  @override
  String get transferBalance => 'Transfer Balance';

  @override
  String get originalAmount => 'Original';

  @override
  String get exchanged => 'Exchanged';

  @override
  String get remaining => 'Remaining';

  @override
  String get exchangeDetails => 'Exchange Details';

  @override
  String get amountSyp => 'Amount in SYP';

  @override
  String get amountTry => 'Amount in TRY';

  @override
  String get exchangeCreatedSuccess => 'Exchange created successfully!';

  @override
  String get pleaseSelectTransfer => 'Please select a transfer first';

  @override
  String get amountExceedsBalance => 'Amount exceeds remaining balance';

  @override
  String get noExchangesYet => 'No exchanges yet';

  @override
  String get createFirstExchange =>
      'Create your first exchange from a transfer';

  @override
  String get exchangeDate => 'Exchange Date';

  @override
  String get youWillReceive => 'You will receive';

  @override
  String get selectDate => 'Select Date';

  @override
  String get amountUsdRequired => 'Amount in USD is required';

  @override
  String get exchangeRateRequired => 'Exchange rate is required';

  @override
  String get notes => 'Notes';

  @override
  String get optional => 'Optional';

  @override
  String get pleaseEnterAmount => 'Please enter amount';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get pleaseEnterRate => 'Please enter exchange rate';

  @override
  String get invalidRate => 'Invalid exchange rate';

  @override
  String get recipient => 'Recipient';

  @override
  String get rate => 'Rate';

  @override
  String get noGroupFound => 'No group found';

  @override
  String get notInGroup => 'You are not in a group';

  @override
  String get notInGroupDesc =>
      'Join a group using a code provided by your admin to access shared financial data.';

  @override
  String get joinDescription =>
      'Enter the group code provided by your admin to join their group and access shared financial data.';

  @override
  String get helpTitle => 'Need Help?';

  @override
  String get help1 => 'The group code is 6 characters long';

  @override
  String get help2 => 'Get the code from your admin';

  @override
  String get help3 => 'You can only be in one group at a time';

  @override
  String get help4 => 'Contact your admin if you need to leave a group';

  @override
  String get expensesListTitle => 'Expenses List';

  @override
  String get sum => 'SUM';

  @override
  String get noExpensesToExport => 'No expenses to export';

  @override
  String get noInvoicesToExport => 'No invoices to export';

  @override
  String get filterByDate => 'Filter by Date';

  @override
  String get allDates => 'All Dates';

  @override
  String get customRange => 'Custom Range';

  @override
  String get clearAllData => 'Clear All Data';

  @override
  String get clearAllDataWarning =>
      'This will delete ALL data from the database including:\\n\\n• All expenses\\n• All transfers\\n• All incoming transactions\\n• All fund box records\\n• All exchanges\\n\\nThis action cannot be undone!';

  @override
  String get deleteAllData => 'Delete All Data';

  @override
  String get allDataCleared => '✓ All data cleared successfully';

  @override
  String get errorClearingData => 'Error clearing data';

  @override
  String get errorLoadingStats => 'Error loading stats';

  @override
  String get goBack => 'Go Back';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get warning => 'Warning';

  @override
  String get info => 'Info';

  @override
  String get close => 'Close';

  @override
  String get ok => 'OK';

  @override
  String get confirm => 'Confirm';

  @override
  String get back => 'Back';

  @override
  String get continueButton => 'Continue';

  @override
  String get submit => 'Submit';

  @override
  String get update => 'Update';

  @override
  String get refresh => 'Refresh';

  @override
  String get filter => 'Filter';

  @override
  String get sort => 'Sort';

  @override
  String get clear => 'Clear';

  @override
  String get apply => 'Apply';

  @override
  String get reset => 'Reset';

  @override
  String get select => 'Select';

  @override
  String get selected => 'Selected';

  @override
  String get none => 'None';

  @override
  String get other => 'Other';

  @override
  String get more => 'More';

  @override
  String get less => 'Less';

  @override
  String get showMore => 'Show More';

  @override
  String get showLess => 'Show Less';

  @override
  String get viewAll => 'View All';

  @override
  String get viewDetails => 'View Details';

  @override
  String get details => 'Details';

  @override
  String get settings => 'Settings';

  @override
  String get filterByGroup => 'Filter by Group';

  @override
  String get allGroups => 'All Groups';

  @override
  String get grandTotal => 'Grand Total';

  @override
  String get expenseCount => 'Expense Count';

  @override
  String get pending => 'Pending';

  @override
  String get approved => 'Approved';

  @override
  String get rejected => 'Rejected';

  @override
  String get errorLoadingData => 'Error Loading Data';

  @override
  String get noExpensesFound => 'No expenses found';

  @override
  String get loadMore => 'Load More';

  @override
  String get noDescription => 'No description';

  @override
  String get help => 'Help';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get superadminRegistrationSuccess =>
      'SuperAdmin Registration Successful';

  @override
  String get groupCodeGenerated => 'Group Code Generated';

  @override
  String get shareWithAdmins =>
      'Share this code with your admins to allow them to join your group';

  @override
  String get copyGroupCode => 'Copy Group Code';

  @override
  String get expenseOverview => 'Expense Overview';

  @override
  String get adminGroupSummary => 'Admin Group Summary';

  @override
  String get viewGroupDetails => 'View Group Details';

  @override
  String get pendingExpenses => 'Pending Expenses';

  @override
  String get approvedExpenses => 'Approved Expenses';

  @override
  String get rejectedExpenses => 'Rejected Expenses';

  @override
  String get updateFundBoxBalances => 'Update Fund Box Balances';

  @override
  String get errorLoadingFundBox => 'Error loading fund box';

  @override
  String get loadingFundBox => 'Loading fund box...';

  @override
  String get exportCompletedSuccessfully => 'Export completed successfully';

  @override
  String get failedToLoadImageError => 'Failed to load image';

  @override
  String get sypCurrencyFull => 'SYP (Syrian Pounds)';

  @override
  String get tryCurrencyFull => 'TRY (Turkish Lira)';

  @override
  String get fifteenDays => '15 Days';

  @override
  String get monthPeriod => 'Month';

  @override
  String get allTime => 'All Time';

  @override
  String get filterByCurrency => 'Filter by Currency';

  @override
  String get noExchangesToExport => 'No exchanges to export';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get languageChanged => 'Language changed successfully';

  @override
  String get languageSettings => 'Language Settings';

  @override
  String get appLanguage => 'App Language';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get hasInvoice => 'Has Invoice';

  @override
  String get selectDateRange => 'Select Date Range';

  @override
  String get myExpenses => 'My Expenses';

  @override
  String get me => 'Me';

  @override
  String get allCurrencies => 'All Currencies';

  @override
  String get expenseCreatedSuccessfully => 'Expense created successfully';

  @override
  String get createExpense => 'Create Expense';

  @override
  String get filters => 'Filters';

  @override
  String get clearAll => 'Clear All';

  @override
  String get dateRange => 'Date Range';

  @override
  String get errorLoadingExpenses => 'Error loading expenses';

  @override
  String get createFirstExpense => 'Create your first expense';

  @override
  String get exportData => 'Export Data';

  @override
  String get activeFilters => 'Active Filters from Expense Page';

  @override
  String get noFiltersApplied => 'No filters applied - exporting all expenses';

  @override
  String get specificUser => 'Specific User';

  @override
  String get exportWillApplyFilters =>
      'Export will apply filters from the Expense page';

  @override
  String get exportOptions => 'Export Options';

  @override
  String get exportToPdf => 'Export to PDF';

  @override
  String get exportPdfDescription => 'Export expenses as a PDF document';

  @override
  String get exportToExcel => 'Export to Excel';

  @override
  String get exportExcelDescription =>
      'Export expenses as an Excel spreadsheet';

  @override
  String get exportInvoiceImages => 'Export Invoice Images';

  @override
  String get exportInvoicesDescription =>
      'Export all invoice photos as a single PDF';

  @override
  String get exportCompleted => 'Export completed';

  @override
  String get exportMyExpenses => 'Export My Expenses';

  @override
  String get exportUserInfo => 'Export User Info';
}
