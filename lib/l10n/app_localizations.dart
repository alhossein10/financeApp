import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Finance App'**
  String get appTitle;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @cash_inbox.
  ///
  /// In en, this message translates to:
  /// **'Cash-Inbox'**
  String get cash_inbox;

  /// No description provided for @cashInbox.
  ///
  /// In en, this message translates to:
  /// **'Cash-Inbox'**
  String get cashInbox;

  /// No description provided for @transfer_to_admin.
  ///
  /// In en, this message translates to:
  /// **'Transfer to Admin'**
  String get transfer_to_admin;

  /// No description provided for @select_admin.
  ///
  /// In en, this message translates to:
  /// **'Select Admin'**
  String get select_admin;

  /// No description provided for @no_admins_available.
  ///
  /// In en, this message translates to:
  /// **'No admins available'**
  String get no_admins_available;

  /// No description provided for @export_success.
  ///
  /// In en, this message translates to:
  /// **'Export successful'**
  String get export_success;

  /// No description provided for @convert.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get convert;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @fundBoxUsd.
  ///
  /// In en, this message translates to:
  /// **'Fund Box (USD)'**
  String get fundBoxUsd;

  /// No description provided for @setFundBalance.
  ///
  /// In en, this message translates to:
  /// **'Set Fund Balance (USD)'**
  String get setFundBalance;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @transfers.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get transfers;

  /// No description provided for @newTransfer.
  ///
  /// In en, this message translates to:
  /// **'New Transfer'**
  String get newTransfer;

  /// No description provided for @transferCreated.
  ///
  /// In en, this message translates to:
  /// **'Transfer created successfully'**
  String get transferCreated;

  /// No description provided for @transferDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transfer deleted successfully'**
  String get transferDeleted;

  /// No description provided for @recipientName.
  ///
  /// In en, this message translates to:
  /// **'Recipient name'**
  String get recipientName;

  /// No description provided for @selectRecipient.
  ///
  /// In en, this message translates to:
  /// **'Select recipient'**
  String get selectRecipient;

  /// No description provided for @createOutgoingTransfer.
  ///
  /// In en, this message translates to:
  /// **'Create Outgoing Transfer'**
  String get createOutgoingTransfer;

  /// No description provided for @outgoingTransfers.
  ///
  /// In en, this message translates to:
  /// **'Outgoing Transfers'**
  String get outgoingTransfers;

  /// No description provided for @noOutgoingTransfers.
  ///
  /// In en, this message translates to:
  /// **'No outgoing transfers yet'**
  String get noOutgoingTransfers;

  /// No description provided for @noAdminMembersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No admin members available'**
  String get noAdminMembersAvailable;

  /// No description provided for @fundBoxBalance.
  ///
  /// In en, this message translates to:
  /// **'Fund Box Balance'**
  String get fundBoxBalance;

  /// No description provided for @loadingBalance.
  ///
  /// In en, this message translates to:
  /// **'Loading balance...'**
  String get loadingBalance;

  /// No description provided for @pleaseFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields'**
  String get pleaseFillAllFields;

  /// No description provided for @amountUsd.
  ///
  /// In en, this message translates to:
  /// **'Amount USD'**
  String get amountUsd;

  /// No description provided for @convertedAmount.
  ///
  /// In en, this message translates to:
  /// **'Converted Amount (USD → SYP)'**
  String get convertedAmount;

  /// No description provided for @exchangeRate.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rate (USD → SYP)'**
  String get exchangeRate;

  /// No description provided for @convertedTotalSyp.
  ///
  /// In en, this message translates to:
  /// **'Converted Total (SYP)'**
  String get convertedTotalSyp;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @editConversion.
  ///
  /// In en, this message translates to:
  /// **'Edit conversion'**
  String get editConversion;

  /// No description provided for @editTransferConversion.
  ///
  /// In en, this message translates to:
  /// **'Edit Transfer Conversion'**
  String get editTransferConversion;

  /// No description provided for @refundDelete.
  ///
  /// In en, this message translates to:
  /// **'Refund and delete'**
  String get refundDelete;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @noSypRecorded.
  ///
  /// In en, this message translates to:
  /// **'No SYP recorded'**
  String get noSypRecorded;

  /// No description provided for @convertedAmountError.
  ///
  /// In en, this message translates to:
  /// **'Converted amount cannot exceed total transfer amount'**
  String get convertedAmountError;

  /// No description provided for @usdSypRate.
  ///
  /// In en, this message translates to:
  /// **'USD → SYP rate'**
  String get usdSypRate;

  /// No description provided for @usd.
  ///
  /// In en, this message translates to:
  /// **'USD'**
  String get usd;

  /// No description provided for @syp.
  ///
  /// In en, this message translates to:
  /// **'SYP'**
  String get syp;

  /// No description provided for @currencyTry.
  ///
  /// In en, this message translates to:
  /// **'TRY'**
  String get currencyTry;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpense;

  /// No description provided for @newExpense.
  ///
  /// In en, this message translates to:
  /// **'New Expense'**
  String get newExpense;

  /// No description provided for @editExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense'**
  String get editExpense;

  /// No description provided for @itemDescription.
  ///
  /// In en, this message translates to:
  /// **'Item description *'**
  String get itemDescription;

  /// No description provided for @expenseDate.
  ///
  /// In en, this message translates to:
  /// **'Expense Date'**
  String get expenseDate;

  /// No description provided for @priceUsd.
  ///
  /// In en, this message translates to:
  /// **'Price USD'**
  String get priceUsd;

  /// No description provided for @priceSyp.
  ///
  /// In en, this message translates to:
  /// **'Price SYP'**
  String get priceSyp;

  /// No description provided for @priceTry.
  ///
  /// In en, this message translates to:
  /// **'Price TRY'**
  String get priceTry;

  /// No description provided for @invoiceStatus.
  ///
  /// In en, this message translates to:
  /// **'Invoice status'**
  String get invoiceStatus;

  /// No description provided for @invoiceAvailable.
  ///
  /// In en, this message translates to:
  /// **'Invoice available'**
  String get invoiceAvailable;

  /// No description provided for @noInvoiceAvailable.
  ///
  /// In en, this message translates to:
  /// **'No invoice available'**
  String get noInvoiceAvailable;

  /// No description provided for @noFileSelected.
  ///
  /// In en, this message translates to:
  /// **'No file selected'**
  String get noFileSelected;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @exportExcel.
  ///
  /// In en, this message translates to:
  /// **'Export Excel'**
  String get exportExcel;

  /// No description provided for @expensesList.
  ///
  /// In en, this message translates to:
  /// **'Expenses List'**
  String get expensesList;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @outgoing.
  ///
  /// In en, this message translates to:
  /// **'Outgoing'**
  String get outgoing;

  /// No description provided for @incoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming'**
  String get incoming;

  /// No description provided for @addIncoming.
  ///
  /// In en, this message translates to:
  /// **'Add Incoming'**
  String get addIncoming;

  /// No description provided for @newIncoming.
  ///
  /// In en, this message translates to:
  /// **'New Incoming'**
  String get newIncoming;

  /// No description provided for @editIncoming.
  ///
  /// In en, this message translates to:
  /// **'Edit Incoming'**
  String get editIncoming;

  /// No description provided for @transactionDate.
  ///
  /// In en, this message translates to:
  /// **'Transaction Date'**
  String get transactionDate;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchByName.
  ///
  /// In en, this message translates to:
  /// **'Search by recipient name'**
  String get searchByName;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @totalUsd.
  ///
  /// In en, this message translates to:
  /// **'Total USD'**
  String get totalUsd;

  /// No description provided for @totalSyp.
  ///
  /// In en, this message translates to:
  /// **'Total SYP'**
  String get totalSyp;

  /// No description provided for @totalTry.
  ///
  /// In en, this message translates to:
  /// **'Total TRY'**
  String get totalTry;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @fromGallery.
  ///
  /// In en, this message translates to:
  /// **'From Gallery'**
  String get fromGallery;

  /// No description provided for @photoSaved.
  ///
  /// In en, this message translates to:
  /// **'Photo saved successfully'**
  String get photoSaved;

  /// No description provided for @noCamera.
  ///
  /// In en, this message translates to:
  /// **'No camera available'**
  String get noCamera;

  /// No description provided for @exportCash.
  ///
  /// In en, this message translates to:
  /// **'Export Cash'**
  String get exportCash;

  /// No description provided for @exportInvoices.
  ///
  /// In en, this message translates to:
  /// **'Export Invoices'**
  String get exportInvoices;

  /// No description provided for @addExchange.
  ///
  /// In en, this message translates to:
  /// **'Add Exchange'**
  String get addExchange;

  /// No description provided for @exchangeHistory.
  ///
  /// In en, this message translates to:
  /// **'Exchange History'**
  String get exchangeHistory;

  /// No description provided for @noExchanges.
  ///
  /// In en, this message translates to:
  /// **'No exchange history'**
  String get noExchanges;

  /// No description provided for @cashTransactions.
  ///
  /// In en, this message translates to:
  /// **'Cash Transactions'**
  String get cashTransactions;

  /// No description provided for @invoiceImages.
  ///
  /// In en, this message translates to:
  /// **'Invoice Images'**
  String get invoiceImages;

  /// No description provided for @noInvoiceImages.
  ///
  /// In en, this message translates to:
  /// **'No invoice images found'**
  String get noInvoiceImages;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get register;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials'**
  String get invalidCredentials;

  /// No description provided for @registrationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully'**
  String get registrationSuccess;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Weak password'**
  String get weakPassword;

  /// No description provided for @emailAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Email already exists'**
  String get emailAlreadyExists;

  /// No description provided for @usernameAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Username already exists'**
  String get usernameAlreadyExists;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Your Account'**
  String get createYourAccount;

  /// No description provided for @fillDetailsToStart.
  ///
  /// In en, this message translates to:
  /// **'Fill in the details to get started'**
  String get fillDetailsToStart;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @passwordRequirements.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters with uppercase, lowercase, and number'**
  String get passwordRequirements;

  /// No description provided for @manageFinances.
  ///
  /// In en, this message translates to:
  /// **'Manage your finances easily and securely'**
  String get manageFinances;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @onboardingCashManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash Management'**
  String get onboardingCashManagementTitle;

  /// No description provided for @onboardingCashManagementDesc.
  ///
  /// In en, this message translates to:
  /// **'Track your fund box balance, manage transfers, and monitor incoming transactions all in one place.'**
  String get onboardingCashManagementDesc;

  /// No description provided for @onboardingExpensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense Tracking'**
  String get onboardingExpensesTitle;

  /// No description provided for @onboardingExpensesDesc.
  ///
  /// In en, this message translates to:
  /// **'Record and categorize your expenses with invoice scanning support for easy documentation.'**
  String get onboardingExpensesDesc;

  /// No description provided for @onboardingTransfersTitle.
  ///
  /// In en, this message translates to:
  /// **'Money Transfers'**
  String get onboardingTransfersTitle;

  /// No description provided for @onboardingTransfersDesc.
  ///
  /// In en, this message translates to:
  /// **'Send money with automatic currency conversion and exchange rate tracking.'**
  String get onboardingTransfersDesc;

  /// No description provided for @onboardingExportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Export & Reports'**
  String get onboardingExportsTitle;

  /// No description provided for @onboardingExportsDesc.
  ///
  /// In en, this message translates to:
  /// **'Generate PDF and Excel reports of your financial data with customizable filters.'**
  String get onboardingExportsDesc;

  /// No description provided for @viewTutorial.
  ///
  /// In en, this message translates to:
  /// **'View Tutorial'**
  String get viewTutorial;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @syncCompleted.
  ///
  /// In en, this message translates to:
  /// **'Sync completed successfully'**
  String get syncCompleted;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncFailed;

  /// No description provided for @retrySync.
  ///
  /// In en, this message translates to:
  /// **'Retry Sync'**
  String get retrySync;

  /// No description provided for @syncRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get syncRetry;

  /// No description provided for @syncAll.
  ///
  /// In en, this message translates to:
  /// **'Sync All'**
  String get syncAll;

  /// No description provided for @syncInProgress.
  ///
  /// In en, this message translates to:
  /// **'Sync in progress'**
  String get syncInProgress;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @totalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get totalUsers;

  /// No description provided for @totalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get totalExpenses;

  /// No description provided for @pendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending Sync'**
  String get pendingSync;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @recentUserExpenses.
  ///
  /// In en, this message translates to:
  /// **'Recent User Expenses'**
  String get recentUserExpenses;

  /// No description provided for @userActivitySummary.
  ///
  /// In en, this message translates to:
  /// **'User Activity Summary'**
  String get userActivitySummary;

  /// No description provided for @createdBy.
  ///
  /// In en, this message translates to:
  /// **'Created by'**
  String get createdBy;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get unknownUser;

  /// No description provided for @noExpensesYet.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get noExpensesYet;

  /// No description provided for @noUserActivity.
  ///
  /// In en, this message translates to:
  /// **'No user activity'**
  String get noUserActivity;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get syncPending;

  /// No description provided for @syncSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get syncSyncing;

  /// No description provided for @syncSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncSynced;

  /// No description provided for @syncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync Status'**
  String get syncStatus;

  /// No description provided for @allUsers.
  ///
  /// In en, this message translates to:
  /// **'All Users'**
  String get allUsers;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All Statuses'**
  String get allStatuses;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @filterByUser.
  ///
  /// In en, this message translates to:
  /// **'Filter by User'**
  String get filterByUser;

  /// No description provided for @filterByRecipient.
  ///
  /// In en, this message translates to:
  /// **'Filter by Recipient'**
  String get filterByRecipient;

  /// No description provided for @mustSelectSameUser.
  ///
  /// In en, this message translates to:
  /// **'You must select the same user for exchange history and expenses to export the file'**
  String get mustSelectSameUser;

  /// No description provided for @exportExchanges.
  ///
  /// In en, this message translates to:
  /// **'Export Exchanges'**
  String get exportExchanges;

  /// No description provided for @combinedExport.
  ///
  /// In en, this message translates to:
  /// **'Combined Export'**
  String get combinedExport;

  /// No description provided for @exportUserData.
  ///
  /// In en, this message translates to:
  /// **'Export User Data'**
  String get exportUserData;

  /// No description provided for @pleaseSelectUser.
  ///
  /// In en, this message translates to:
  /// **'Please select a user first'**
  String get pleaseSelectUser;

  /// No description provided for @exportError.
  ///
  /// In en, this message translates to:
  /// **'Export Error'**
  String get exportError;

  /// No description provided for @viewInvoice.
  ///
  /// In en, this message translates to:
  /// **'View Invoice'**
  String get viewInvoice;

  /// No description provided for @noInvoiceImage.
  ///
  /// In en, this message translates to:
  /// **'No invoice image available'**
  String get noInvoiceImage;

  /// No description provided for @failedToLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get failedToLoadImage;

  /// No description provided for @invoiceImage.
  ///
  /// In en, this message translates to:
  /// **'Invoice Image'**
  String get invoiceImage;

  /// No description provided for @unauthorizedAccess.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized Access'**
  String get unauthorizedAccess;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @expenseCreated.
  ///
  /// In en, this message translates to:
  /// **'Expense created successfully'**
  String get expenseCreated;

  /// No description provided for @expenseUpdated.
  ///
  /// In en, this message translates to:
  /// **'Expense updated successfully'**
  String get expenseUpdated;

  /// No description provided for @expenseDeleted.
  ///
  /// In en, this message translates to:
  /// **'Expense deleted successfully'**
  String get expenseDeleted;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @deleteExpenseConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this expense?'**
  String get deleteExpenseConfirmation;

  /// No description provided for @deleteInvoiceConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this invoice?'**
  String get deleteInvoiceConfirmation;

  /// No description provided for @deleteInvoice.
  ///
  /// In en, this message translates to:
  /// **'Delete Invoice'**
  String get deleteInvoice;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @organization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organization;

  /// No description provided for @department.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get department;

  /// No description provided for @selectOrganization.
  ///
  /// In en, this message translates to:
  /// **'Select Organization'**
  String get selectOrganization;

  /// No description provided for @selectDepartment.
  ///
  /// In en, this message translates to:
  /// **'Select Department'**
  String get selectDepartment;

  /// No description provided for @organizationRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select an organization'**
  String get organizationRequired;

  /// No description provided for @departmentRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a department'**
  String get departmentRequired;

  /// No description provided for @regularUser.
  ///
  /// In en, this message translates to:
  /// **'Regular User'**
  String get regularUser;

  /// No description provided for @adminUser.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get adminUser;

  /// No description provided for @userType.
  ///
  /// In en, this message translates to:
  /// **'User Type'**
  String get userType;

  /// No description provided for @groupCode.
  ///
  /// In en, this message translates to:
  /// **'Group Code'**
  String get groupCode;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// No description provided for @membersCount.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersCount;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyCode;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get copied;

  /// No description provided for @regenerateCode.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get regenerateCode;

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeMember;

  /// No description provided for @joinGroup.
  ///
  /// In en, this message translates to:
  /// **'Join Group'**
  String get joinGroup;

  /// No description provided for @myGroup.
  ///
  /// In en, this message translates to:
  /// **'My Group'**
  String get myGroup;

  /// No description provided for @groupManagement.
  ///
  /// In en, this message translates to:
  /// **'Group Management'**
  String get groupManagement;

  /// No description provided for @enterGroupCode.
  ///
  /// In en, this message translates to:
  /// **'Enter group code'**
  String get enterGroupCode;

  /// No description provided for @groupCodeHint.
  ///
  /// In en, this message translates to:
  /// **'6 characters'**
  String get groupCodeHint;

  /// No description provided for @getFromAdmin.
  ///
  /// In en, this message translates to:
  /// **'Get this code from your admin'**
  String get getFromAdmin;

  /// No description provided for @shareWithTeam.
  ///
  /// In en, this message translates to:
  /// **'Share this code with your team members'**
  String get shareWithTeam;

  /// No description provided for @confirmRemove.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this member from the group?'**
  String get confirmRemove;

  /// No description provided for @confirmRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get confirmRemoveTitle;

  /// No description provided for @confirmRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerating will invalidate the old code. Continue?'**
  String get confirmRegenerate;

  /// No description provided for @joinedAt.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joinedAt;

  /// No description provided for @adminContact.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminContact;

  /// No description provided for @contactAdminToLeave.
  ///
  /// In en, this message translates to:
  /// **'Contact your admin to leave the group'**
  String get contactAdminToLeave;

  /// No description provided for @adminBadge.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminBadge;

  /// No description provided for @cannotRemoveSelf.
  ///
  /// In en, this message translates to:
  /// **'You cannot remove yourself from the group'**
  String get cannotRemoveSelf;

  /// No description provided for @searchMembers.
  ///
  /// In en, this message translates to:
  /// **'Search members...'**
  String get searchMembers;

  /// No description provided for @filterByDepartment.
  ///
  /// In en, this message translates to:
  /// **'Filter by Department'**
  String get filterByDepartment;

  /// No description provided for @allDepartments.
  ///
  /// In en, this message translates to:
  /// **'All Departments'**
  String get allDepartments;

  /// No description provided for @noMembersFound.
  ///
  /// In en, this message translates to:
  /// **'No members found matching your filters'**
  String get noMembersFound;

  /// No description provided for @noMembersYet.
  ///
  /// In en, this message translates to:
  /// **'No members in this group yet'**
  String get noMembersYet;

  /// No description provided for @loadingMembers.
  ///
  /// In en, this message translates to:
  /// **'Loading members...'**
  String get loadingMembers;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @codeTooShort.
  ///
  /// In en, this message translates to:
  /// **'Code must be 6 characters'**
  String get codeTooShort;

  /// No description provided for @codeTooLong.
  ///
  /// In en, this message translates to:
  /// **'Code must be exactly 6 characters'**
  String get codeTooLong;

  /// No description provided for @codeInvalidChars.
  ///
  /// In en, this message translates to:
  /// **'Code must contain only letters and numbers'**
  String get codeInvalidChars;

  /// No description provided for @codeRequired.
  ///
  /// In en, this message translates to:
  /// **'Group code is required'**
  String get codeRequired;

  /// No description provided for @codeMustBe6.
  ///
  /// In en, this message translates to:
  /// **'Code must be exactly 6 characters'**
  String get codeMustBe6;

  /// No description provided for @codeRequirements.
  ///
  /// In en, this message translates to:
  /// **'Code Requirements:'**
  String get codeRequirements;

  /// No description provided for @joinInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-character group code provided by your admin to join their group.'**
  String get joinInstructions;

  /// No description provided for @joinHelp.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have a code? Contact your admin.'**
  String get joinHelp;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Group code copied to clipboard'**
  String get codeCopied;

  /// No description provided for @memberRemoved.
  ///
  /// In en, this message translates to:
  /// **'Member removed successfully'**
  String get memberRemoved;

  /// No description provided for @codeRegenerated.
  ///
  /// In en, this message translates to:
  /// **'Group code regenerated successfully'**
  String get codeRegenerated;

  /// No description provided for @joinedGroup.
  ///
  /// In en, this message translates to:
  /// **'Successfully joined the group'**
  String get joinedGroup;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'The selected group code is invalid'**
  String get invalidCode;

  /// No description provided for @alreadyInGroup.
  ///
  /// In en, this message translates to:
  /// **'You are already in a group'**
  String get alreadyInGroup;

  /// No description provided for @adminCannotJoin.
  ///
  /// In en, this message translates to:
  /// **'Admins cannot join other groups'**
  String get adminCannotJoin;

  /// No description provided for @memberNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found or not in your group'**
  String get memberNotFound;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get memberSince;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @profilePictureUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated successfully'**
  String get profilePictureUpdated;

  /// No description provided for @failedToLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile'**
  String get failedToLoadProfile;

  /// No description provided for @databaseManagement.
  ///
  /// In en, this message translates to:
  /// **'Database Management'**
  String get databaseManagement;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmMessage;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @failedToPickImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image'**
  String get failedToPickImage;

  /// No description provided for @totalExpensesCount.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get totalExpensesCount;

  /// No description provided for @totalTransfersCount.
  ///
  /// In en, this message translates to:
  /// **'Total Transfers'**
  String get totalTransfersCount;

  /// No description provided for @totalIncomingCount.
  ///
  /// In en, this message translates to:
  /// **'Total Incoming'**
  String get totalIncomingCount;

  /// No description provided for @totalExchangesCount.
  ///
  /// In en, this message translates to:
  /// **'Total Exchanges'**
  String get totalExchangesCount;

  /// No description provided for @totalTransactions.
  ///
  /// In en, this message translates to:
  /// **'Total Transactions'**
  String get totalTransactions;

  /// No description provided for @accountAge.
  ///
  /// In en, this message translates to:
  /// **'Account Age'**
  String get accountAge;

  /// No description provided for @lastActivity.
  ///
  /// In en, this message translates to:
  /// **'Last Activity'**
  String get lastActivity;

  /// No description provided for @auditLogs.
  ///
  /// In en, this message translates to:
  /// **'Audit Logs'**
  String get auditLogs;

  /// No description provided for @featureNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Feature Not Available'**
  String get featureNotAvailable;

  /// No description provided for @auditLogsAdminOnly.
  ///
  /// In en, this message translates to:
  /// **'Audit logs are only available in the admin version.'**
  String get auditLogsAdminOnly;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access Denied'**
  String get accessDenied;

  /// No description provided for @adminPrivilegesRequired.
  ///
  /// In en, this message translates to:
  /// **'Admin privileges required to view audit logs.'**
  String get adminPrivilegesRequired;

  /// No description provided for @noAuditLogsFound.
  ///
  /// In en, this message translates to:
  /// **'No audit logs found'**
  String get noAuditLogsFound;

  /// No description provided for @auditLogDetails.
  ///
  /// In en, this message translates to:
  /// **'Audit Log Details'**
  String get auditLogDetails;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @entityType.
  ///
  /// In en, this message translates to:
  /// **'Entity Type'**
  String get entityType;

  /// No description provided for @entityId.
  ///
  /// In en, this message translates to:
  /// **'Entity ID'**
  String get entityId;

  /// No description provided for @userId.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get userId;

  /// No description provided for @ipAddress.
  ///
  /// In en, this message translates to:
  /// **'IP Address'**
  String get ipAddress;

  /// No description provided for @userAgent.
  ///
  /// In en, this message translates to:
  /// **'User Agent'**
  String get userAgent;

  /// No description provided for @changes.
  ///
  /// In en, this message translates to:
  /// **'Changes'**
  String get changes;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// No description provided for @createExchange.
  ///
  /// In en, this message translates to:
  /// **'Create Exchange'**
  String get createExchange;

  /// No description provided for @selectTransfer.
  ///
  /// In en, this message translates to:
  /// **'Select Transfer'**
  String get selectTransfer;

  /// No description provided for @noTransfersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No transfers available from admin'**
  String get noTransfersAvailable;

  /// No description provided for @transferBalance.
  ///
  /// In en, this message translates to:
  /// **'Transfer Balance'**
  String get transferBalance;

  /// No description provided for @originalAmount.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get originalAmount;

  /// No description provided for @exchanged.
  ///
  /// In en, this message translates to:
  /// **'Exchanged'**
  String get exchanged;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @exchangeDetails.
  ///
  /// In en, this message translates to:
  /// **'Exchange Details'**
  String get exchangeDetails;

  /// No description provided for @amountSyp.
  ///
  /// In en, this message translates to:
  /// **'Amount in SYP'**
  String get amountSyp;

  /// No description provided for @amountTry.
  ///
  /// In en, this message translates to:
  /// **'Amount in TRY'**
  String get amountTry;

  /// No description provided for @exchangeCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exchange created successfully!'**
  String get exchangeCreatedSuccess;

  /// No description provided for @pleaseSelectTransfer.
  ///
  /// In en, this message translates to:
  /// **'Please select a transfer first'**
  String get pleaseSelectTransfer;

  /// No description provided for @amountExceedsBalance.
  ///
  /// In en, this message translates to:
  /// **'Amount exceeds remaining balance'**
  String get amountExceedsBalance;

  /// No description provided for @noExchangesYet.
  ///
  /// In en, this message translates to:
  /// **'No exchanges yet'**
  String get noExchangesYet;

  /// No description provided for @createFirstExchange.
  ///
  /// In en, this message translates to:
  /// **'Create your first exchange from a transfer'**
  String get createFirstExchange;

  /// No description provided for @exchangeDate.
  ///
  /// In en, this message translates to:
  /// **'Exchange Date'**
  String get exchangeDate;

  /// No description provided for @youWillReceive.
  ///
  /// In en, this message translates to:
  /// **'You will receive'**
  String get youWillReceive;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @amountUsdRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount in USD is required'**
  String get amountUsdRequired;

  /// No description provided for @exchangeRateRequired.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate is required'**
  String get exchangeRateRequired;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @pleaseEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter amount'**
  String get pleaseEnterAmount;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalidAmount;

  /// No description provided for @pleaseEnterRate.
  ///
  /// In en, this message translates to:
  /// **'Please enter exchange rate'**
  String get pleaseEnterRate;

  /// No description provided for @invalidRate.
  ///
  /// In en, this message translates to:
  /// **'Invalid exchange rate'**
  String get invalidRate;

  /// No description provided for @recipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get recipient;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @noGroupFound.
  ///
  /// In en, this message translates to:
  /// **'No group found'**
  String get noGroupFound;

  /// No description provided for @notInGroup.
  ///
  /// In en, this message translates to:
  /// **'You are not in a group'**
  String get notInGroup;

  /// No description provided for @notInGroupDesc.
  ///
  /// In en, this message translates to:
  /// **'Join a group using a code provided by your admin to access shared financial data.'**
  String get notInGroupDesc;

  /// No description provided for @joinDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter the group code provided by your admin to join their group and access shared financial data.'**
  String get joinDescription;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Need Help?'**
  String get helpTitle;

  /// No description provided for @help1.
  ///
  /// In en, this message translates to:
  /// **'The group code is 6 characters long'**
  String get help1;

  /// No description provided for @help2.
  ///
  /// In en, this message translates to:
  /// **'Get the code from your admin'**
  String get help2;

  /// No description provided for @help3.
  ///
  /// In en, this message translates to:
  /// **'You can only be in one group at a time'**
  String get help3;

  /// No description provided for @help4.
  ///
  /// In en, this message translates to:
  /// **'Contact your admin if you need to leave a group'**
  String get help4;

  /// No description provided for @expensesListTitle.
  ///
  /// In en, this message translates to:
  /// **'Expenses List'**
  String get expensesListTitle;

  /// No description provided for @sum.
  ///
  /// In en, this message translates to:
  /// **'SUM'**
  String get sum;

  /// No description provided for @noExpensesToExport.
  ///
  /// In en, this message translates to:
  /// **'No expenses to export'**
  String get noExpensesToExport;

  /// No description provided for @noInvoicesToExport.
  ///
  /// In en, this message translates to:
  /// **'No invoices to export'**
  String get noInvoicesToExport;

  /// No description provided for @filterByDate.
  ///
  /// In en, this message translates to:
  /// **'Filter by Date'**
  String get filterByDate;

  /// No description provided for @allDates.
  ///
  /// In en, this message translates to:
  /// **'All Dates'**
  String get allDates;

  /// No description provided for @customRange.
  ///
  /// In en, this message translates to:
  /// **'Custom Range'**
  String get customRange;

  /// No description provided for @clearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get clearAllData;

  /// No description provided for @clearAllDataWarning.
  ///
  /// In en, this message translates to:
  /// **'This will delete ALL data from the database including:\\n\\n• All expenses\\n• All transfers\\n• All incoming transactions\\n• All fund box records\\n• All exchanges\\n\\nThis action cannot be undone!'**
  String get clearAllDataWarning;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get deleteAllData;

  /// No description provided for @allDataCleared.
  ///
  /// In en, this message translates to:
  /// **'✓ All data cleared successfully'**
  String get allDataCleared;

  /// No description provided for @errorClearingData.
  ///
  /// In en, this message translates to:
  /// **'Error clearing data'**
  String get errorClearingData;

  /// No description provided for @errorLoadingStats.
  ///
  /// In en, this message translates to:
  /// **'Error loading stats'**
  String get errorLoadingStats;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @less.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get less;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show More'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show Less'**
  String get showLess;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @filterByGroup.
  ///
  /// In en, this message translates to:
  /// **'Filter by Group'**
  String get filterByGroup;

  /// No description provided for @allGroups.
  ///
  /// In en, this message translates to:
  /// **'All Groups'**
  String get allGroups;

  /// No description provided for @grandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get grandTotal;

  /// No description provided for @expenseCount.
  ///
  /// In en, this message translates to:
  /// **'Expense Count'**
  String get expenseCount;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Data'**
  String get errorLoadingData;

  /// No description provided for @noExpensesFound.
  ///
  /// In en, this message translates to:
  /// **'No expenses found'**
  String get noExpensesFound;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load More'**
  String get loadMore;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @superadminRegistrationSuccess.
  ///
  /// In en, this message translates to:
  /// **'SuperAdmin Registration Successful'**
  String get superadminRegistrationSuccess;

  /// No description provided for @groupCodeGenerated.
  ///
  /// In en, this message translates to:
  /// **'Group Code Generated'**
  String get groupCodeGenerated;

  /// No description provided for @shareWithAdmins.
  ///
  /// In en, this message translates to:
  /// **'Share this code with your admins to allow them to join your group'**
  String get shareWithAdmins;

  /// No description provided for @copyGroupCode.
  ///
  /// In en, this message translates to:
  /// **'Copy Group Code'**
  String get copyGroupCode;

  /// No description provided for @expenseOverview.
  ///
  /// In en, this message translates to:
  /// **'Expense Overview'**
  String get expenseOverview;

  /// No description provided for @adminGroupSummary.
  ///
  /// In en, this message translates to:
  /// **'Admin Group Summary'**
  String get adminGroupSummary;

  /// No description provided for @viewGroupDetails.
  ///
  /// In en, this message translates to:
  /// **'View Group Details'**
  String get viewGroupDetails;

  /// No description provided for @pendingExpenses.
  ///
  /// In en, this message translates to:
  /// **'Pending Expenses'**
  String get pendingExpenses;

  /// No description provided for @approvedExpenses.
  ///
  /// In en, this message translates to:
  /// **'Approved Expenses'**
  String get approvedExpenses;

  /// No description provided for @rejectedExpenses.
  ///
  /// In en, this message translates to:
  /// **'Rejected Expenses'**
  String get rejectedExpenses;

  /// No description provided for @updateFundBoxBalances.
  ///
  /// In en, this message translates to:
  /// **'Update Fund Box Balances'**
  String get updateFundBoxBalances;

  /// No description provided for @errorLoadingFundBox.
  ///
  /// In en, this message translates to:
  /// **'Error loading fund box'**
  String get errorLoadingFundBox;

  /// No description provided for @loadingFundBox.
  ///
  /// In en, this message translates to:
  /// **'Loading fund box...'**
  String get loadingFundBox;

  /// No description provided for @exportCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Export completed successfully'**
  String get exportCompletedSuccessfully;

  /// No description provided for @failedToLoadImageError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get failedToLoadImageError;

  /// No description provided for @sypCurrencyFull.
  ///
  /// In en, this message translates to:
  /// **'SYP (Syrian Pounds)'**
  String get sypCurrencyFull;

  /// No description provided for @tryCurrencyFull.
  ///
  /// In en, this message translates to:
  /// **'TRY (Turkish Lira)'**
  String get tryCurrencyFull;

  /// No description provided for @fifteenDays.
  ///
  /// In en, this message translates to:
  /// **'15 Days'**
  String get fifteenDays;

  /// No description provided for @monthPeriod.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get monthPeriod;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @filterByCurrency.
  ///
  /// In en, this message translates to:
  /// **'Filter by Currency'**
  String get filterByCurrency;

  /// No description provided for @noExchangesToExport.
  ///
  /// In en, this message translates to:
  /// **'No exchanges to export'**
  String get noExchangesToExport;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully'**
  String get languageChanged;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get languageSettings;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @hasInvoice.
  ///
  /// In en, this message translates to:
  /// **'Has Invoice'**
  String get hasInvoice;

  /// No description provided for @selectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get selectDateRange;

  /// No description provided for @myExpenses.
  ///
  /// In en, this message translates to:
  /// **'My Expenses'**
  String get myExpenses;

  /// No description provided for @me.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get me;

  /// No description provided for @allCurrencies.
  ///
  /// In en, this message translates to:
  /// **'All Currencies'**
  String get allCurrencies;

  /// No description provided for @expenseCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Expense created successfully'**
  String get expenseCreatedSuccessfully;

  /// No description provided for @createExpense.
  ///
  /// In en, this message translates to:
  /// **'Create Expense'**
  String get createExpense;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRange;

  /// No description provided for @errorLoadingExpenses.
  ///
  /// In en, this message translates to:
  /// **'Error loading expenses'**
  String get errorLoadingExpenses;

  /// No description provided for @createFirstExpense.
  ///
  /// In en, this message translates to:
  /// **'Create your first expense'**
  String get createFirstExpense;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @activeFilters.
  ///
  /// In en, this message translates to:
  /// **'Active Filters from Expense Page'**
  String get activeFilters;

  /// No description provided for @noFiltersApplied.
  ///
  /// In en, this message translates to:
  /// **'No filters applied - exporting all expenses'**
  String get noFiltersApplied;

  /// No description provided for @specificUser.
  ///
  /// In en, this message translates to:
  /// **'Specific User'**
  String get specificUser;

  /// No description provided for @exportWillApplyFilters.
  ///
  /// In en, this message translates to:
  /// **'Export will apply filters from the Expense page'**
  String get exportWillApplyFilters;

  /// No description provided for @exportOptions.
  ///
  /// In en, this message translates to:
  /// **'Export Options'**
  String get exportOptions;

  /// No description provided for @exportToPdf.
  ///
  /// In en, this message translates to:
  /// **'Export to PDF'**
  String get exportToPdf;

  /// No description provided for @exportPdfDescription.
  ///
  /// In en, this message translates to:
  /// **'Export expenses as a PDF document'**
  String get exportPdfDescription;

  /// No description provided for @exportToExcel.
  ///
  /// In en, this message translates to:
  /// **'Export to Excel'**
  String get exportToExcel;

  /// No description provided for @exportExcelDescription.
  ///
  /// In en, this message translates to:
  /// **'Export expenses as an Excel spreadsheet'**
  String get exportExcelDescription;

  /// No description provided for @exportInvoiceImages.
  ///
  /// In en, this message translates to:
  /// **'Export Invoice Images'**
  String get exportInvoiceImages;

  /// No description provided for @exportInvoicesDescription.
  ///
  /// In en, this message translates to:
  /// **'Export all invoice photos as a single PDF'**
  String get exportInvoicesDescription;

  /// No description provided for @exportCompleted.
  ///
  /// In en, this message translates to:
  /// **'Export completed'**
  String get exportCompleted;

  /// No description provided for @exportMyExpenses.
  ///
  /// In en, this message translates to:
  /// **'Export My Expenses'**
  String get exportMyExpenses;

  /// No description provided for @exportUserInfo.
  ///
  /// In en, this message translates to:
  /// **'Export User Info'**
  String get exportUserInfo;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
