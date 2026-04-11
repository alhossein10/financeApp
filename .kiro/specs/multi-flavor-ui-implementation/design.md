# Design Document: Multi-Flavor Application UI Implementation

## Overview

This design document outlines the architecture and implementation approach for the three-flavor Finance application system. The design leverages Flutter's flavor system to create three distinct application experiences (Superadmin, Admin, User) while maximizing code reuse through shared components and services.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Superadmin  │  │    Admin     │  │     User     │      │
│  │   Flavor     │  │   Flavor     │  │   Flavor     │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│         │                  │                  │              │
│         └──────────────────┴──────────────────┘              │
│                            │                                 │
│                  ┌─────────▼─────────┐                       │
│                  │  Shared Widgets   │                       │
│                  │  & Components     │                       │
│                  └─────────┬─────────┘                       │
└────────────────────────────┼─────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────┐
│                     Business Logic Layer                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  BLoC/State  │  │  Use Cases   │  │ Repositories │      │
│  │  Management  │  │              │  │              │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└────────────────────────────┬─────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────┐
│                        Data Layer                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ API Services │  │ Local Cache  │  │ Secure Store │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└───────────────────────────────────────────────────────────────┘
```

### Flavor Configuration

Each flavor will have its own:
- Main entry point (`main_superadmin.dart`, `main_admin.dart`, `main_user.dart`)
- Flavor-specific configuration
- Navigation structure
- Feature flags
- Theme customization

```dart
enum AppFlavor {
  superadmin,
  admin,
  user,
}

class FlavorConfig {
  final AppFlavor flavor;
  final String appName;
  final List<NavigationDestination> navigationItems;
  final Map<String, bool> featureFlags;
  
  // Feature flags examples:
  // - canCreateExpenses
  // - canExchangeCurrency
  // - canExportData
  // - canManageGroup
  // - canViewAnalytics
}
```

## Components and Interfaces

### 1. Authentication Components

#### Registration Flow Component
- **Purpose**: Handle flavor-specific registration flows
- **Variants**:
  - `SuperadminRegistrationPage`: No code input, generates group code
  - `AdminRegistrationPage`: Requires Superadmin join code
  - `UserRegistrationPage`: Requires Admin join code

```dart
abstract class RegistrationPage extends StatefulWidget {
  bool get requiresJoinCode;
  String get joinCodeLabel;
  Future<void> onRegistrationSuccess(AuthResponse response);
}
```

#### Registration Success Dialog
- **Purpose**: Display flavor-specific success messages
- **Variants**:
  - `SuperadminSuccessDialog`: Shows generated group code with copy button
  - `AdminSuccessDialog`: Shows admin group information
  - `UserSuccessDialog`: Shows basic success message

### 2. Navigation Components

#### Flavor-Specific Navigation
- **Purpose**: Provide role-appropriate navigation structure
- **Implementation**: Use `FlavorConfig` to determine visible navigation items

```dart
class AppNavigationBar extends StatelessWidget {
  final AppFlavor flavor;
  
  List<NavigationDestination> _getDestinations() {
    switch (flavor) {
      case AppFlavor.superadmin:
        return [
          NavigationDestination(icon: Icons.group, label: 'Group'),
          NavigationDestination(icon: Icons.account_balance_wallet, label: 'Cash'),
          NavigationDestination(icon: Icons.swap_horiz, label: 'Transfers'),
          NavigationDestination(icon: Icons.analytics, label: 'Analytics'),
          NavigationDestination(icon: Icons.person, label: 'Profile'),
        ];
      case AppFlavor.admin:
        return [
          NavigationDestination(icon: Icons.group, label: 'Group'),
          NavigationDestination(icon: Icons.account_balance_wallet, label: 'Cash'),
          NavigationDestination(icon: Icons.currency_exchange, label: 'Exchange'),
          NavigationDestination(icon: Icons.receipt, label: 'Expenses'),
          NavigationDestination(icon: Icons.download, label: 'Export'),
          NavigationDestination(icon: Icons.person, label: 'Profile'),
        ];
      case AppFlavor.user:
        return [
          NavigationDestination(icon: Icons.home, label: 'Home'),
          NavigationDestination(icon: Icons.currency_exchange, label: 'Exchange'),
          NavigationDestination(icon: Icons.receipt, label: 'Expenses'),
          NavigationDestination(icon: Icons.download, label: 'Export'),
          NavigationDestination(icon: Icons.person, label: 'Profile'),
        ];
    }
  }
}
```

### 3. Group Management Components

#### Superadmin Group Management
- **Components**:
  - `AdminListCard`: Displays Admin profile with avatar, name, email
  - `AdminDetailSheet`: Shows Admin's financial box details
  - `GroupCodeDisplay`: Shows group code with copy functionality

#### Admin Group Management
- **Components**:
  - `UserListCard`: Displays User profile with avatar, name, balances
  - `UserDetailSheet`: Shows User's detailed information
  - `GroupCodeDisplay`: Shows admin group code

### 4. Financial Box Components

#### Multi-Currency Balance Display
```dart
class MultiCurrencyBalanceCard extends StatelessWidget {
  final double balanceUsd;
  final double balanceSyp;
  final double balanceTry;
  final DateTime lastUpdated;
  
  // Displays all three currency balances with appropriate formatting
}
```

#### Balance Verification Service
```dart
class BalanceVerificationService {
  Future<bool> verifyBalance({
    required String userId,
    required String currency,
    required double amount,
  });
  
  Future<Map<String, double>> getCurrentBalances(String userId);
}
```

### 5. Transfer Components

#### Transfer Creation Form
- **Variants**:
  - `SuperadminTransferForm`: Transfer to Admins (USD only)
  - `AdminTransferForm`: Transfer to Users (USD only)

```dart
class TransferForm extends StatefulWidget {
  final AppFlavor flavor;
  final List<User> recipients; // Filtered by role
  
  Future<void> onSubmit(TransferRequest request);
}
```

#### Transfer List with Filters
```dart
class TransferListPage extends StatefulWidget {
  final AppFlavor flavor;
  
  // Filters:
  // - Date range
  // - Recipient (role-specific)
  // - Export to PDF
}
```

### 6. Exchange Components

#### Exchange Creation Form
```dart
class ExchangeForm extends StatefulWidget {
  final String userId;
  final double currentUsdBalance;
  
  // Fields:
  // - Target currency (SYP or TRY)
  // - Amount in USD
  // - Exchange rate OR converted amount
  // - Exchange date
  // - Notes (optional)
  
  Future<void> onSubmit(ExchangeRequest request);
}
```

#### Exchange Log Page
- **Variants**:
  - `AdminExchangeLog`: Shows Admin + all Users in group
  - `UserExchangeLog`: Shows only User's own exchanges

```dart
class ExchangeLogPage extends StatefulWidget {
  final AppFlavor flavor;
  final String userId;
  
  // Features:
  // - Filter by user (Admin only)
  // - Filter by currency (SYP/TRY)
  // - Total exchanged amounts display
  // - Export to PDF
}
```

### 7. Expense Components

#### Expense Creation Form
```dart
class ExpenseForm extends StatefulWidget {
  final String userId;
  final Map<String, double> currentBalances;
  
  // Fields:
  // - Description
  // - Amount (with currency selector: USD/SYP/TRY)
  // - Expense date
  // - Invoice photo (optional)
  
  Future<void> onSubmit(ExpenseRequest request);
}
```

#### Expense List with Filters
- **Variants**:
  - `SuperadminExpenseList`: Grouped by Admin group (read-only)
  - `AdminExpenseList`: Admin + all Users in group
  - `UserExpenseList`: Only User's own expenses

```dart
class ExpenseListPage extends StatefulWidget {
  final AppFlavor flavor;
  final String userId;
  
  // Filters:
  // - Date range
  // - Currency (USD/SYP/TRY)
  // - User (Admin/Superadmin only)
  
  // Features:
  // - Inline invoice preview
  // - Create expense button (hidden for Superadmin)
}
```

#### Invoice Preview Component
```dart
class InvoicePreviewDialog extends StatelessWidget {
  final String imageUrl;
  
  // Features:
  // - Full-screen image display
  // - Zoom controls
  // - Loading indicator
  // - Error handling
}
```

### 8. Export Components

#### Export Options Page
```dart
class ExportPage extends StatefulWidget {
  final AppFlavor flavor;
  final ExpenseFilters activeFilters;
  
  // Export options:
  // - Export to PDF
  // - Export to Excel
  // - Export invoice images to PDF bundle
  
  // All exports apply active filters from Expenses page
}
```

### 9. Analytics Components (Superadmin Only)

#### Global Summary Card
```dart
class GlobalSummaryCard extends StatelessWidget {
  final int totalInvoices;
  final double totalInvoicesValue;
  final int totalTransfers;
  
  // Displays aggregated data across all Admin groups
}
```

#### Admin Group Analytics Card
```dart
class AdminGroupAnalyticsCard extends StatelessWidget {
  final String adminName;
  final int userCount;
  final int invoiceCount;
  final double invoiceValue;
  final int transferCount;
  
  // Displays analytics for a specific Admin group
}
```

### 10. Profile Components

#### Profile Image Upload
```dart
class ProfileImageUpload extends StatefulWidget {
  final String userId;
  final String? currentImageUrl;
  
  // Features:
  // - Select from gallery or camera
  // - Image compression (max 1MB)
  // - Circular avatar display
  // - Upload progress indicator
}
```

## Data Models

### Enhanced User Model
```dart
class User {
  final String id;
  final String name;
  final String email;
  final UserRole role; // superadmin, admin, user
  final String? profileImageUrl;
  final String? organizationName;
  final String? departmentName;
  final String? adminGroupId;
  final String? superadminGroupId;
  final DateTime createdAt;
}
```

### Multi-Currency Fund Box Model
```dart
class FundBox {
  final String id;
  final String userId;
  final double balanceUsd;
  final double balanceSyp;
  final double balanceTry;
  final DateTime lastCalculatedAt;
  final DateTime updatedAt;
}
```

### Exchange Model
```dart
class Exchange {
  final String id;
  final String userId;
  final String? transferId; // Optional link to transfer
  final String targetCurrency; // 'SYP' or 'TRY'
  final double amountUsd;
  final double exchangeRate;
  final double convertedAmount;
  final DateTime exchangeDate;
  final String? notes;
  final DateTime createdAt;
}
```

### Multi-Currency Expense Model
```dart
class Expense {
  final String id;
  final String userId;
  final String description;
  final double? priceUsd;
  final double? priceSyp;
  final double? priceTry;
  final DateTime expenseDate;
  final String? invoicePhotoUrl;
  final bool hasInvoice;
  final DateTime createdAt;
}
```

### Transfer Model
```dart
class Transfer {
  final String id;
  final String senderUserId;
  final String recipientUserId;
  final String recipientName;
  final double amountUsd;
  final DateTime transferDate;
  final String? notes;
  final DateTime createdAt;
}
```

### Group Models
```dart
class SuperadminGroup {
  final String id;
  final String superadminUserId;
  final String groupCode; // 6-digit code
  final String groupName;
  final int membersCount; // Number of Admins
  final bool isActive;
  final DateTime createdAt;
}

class AdminGroup {
  final String id;
  final String adminUserId;
  final String groupCode; // 6-digit code
  final String groupName;
  final int membersCount; // Number of Users
  final bool isActive;
  final DateTime createdAt;
}
```

## Error Handling

### Balance Verification Errors
```dart
class InsufficientBalanceException implements Exception {
  final String currency;
  final double required;
  final double available;
  
  String get message => 
    'Insufficient $currency balance. Required: $required, Available: $available';
}
```

### Group Code Validation Errors
```dart
class InvalidGroupCodeException implements Exception {
  final String code;
  
  String get message => 'Invalid group code: $code';
}
```

### Error Display Strategy
- **Inline errors**: Field validation errors displayed below input fields
- **Snackbar errors**: Operation failures displayed in snackbar with retry option
- **Dialog errors**: Critical errors displayed in dialog with action buttons
- **Offline indicator**: Persistent banner when offline

## Testing Strategy

### Unit Tests
- **Models**: JSON serialization/deserialization
- **Services**: Balance verification, group code validation
- **BLoCs**: State management logic
- **Utilities**: Currency formatting, date formatting

### Widget Tests
- **Registration pages**: All three flavor variants
- **Navigation**: Flavor-specific navigation structures
- **Forms**: Transfer, exchange, expense creation
- **Lists**: Expense list, transfer list, exchange log
- **Filters**: Filter application and persistence

### Integration Tests
- **Authentication flows**: Registration and login for each flavor
- **Financial operations**: Transfer → Balance update → Expense creation
- **Exchange flows**: USD → SYP/TRY exchange with balance updates
- **Group management**: Join group, view members, remove members
- **Export flows**: Apply filters → Export → Download

### Flavor-Specific Tests
- **Superadmin**: Group code generation, Admin management, analytics
- **Admin**: User management, group-wide expense view, exchange log
- **User**: Personal expense tracking, exchange history

## Performance Optimizations

### Image Handling
- Compress images before upload (max 1MB)
- Cache profile images locally
- Lazy load images in lists
- Use thumbnail URLs for list views

### List Performance
- Implement pagination (15 items per page, max 100)
- Use `ListView.builder` for efficient rendering
- Cache list data locally
- Implement pull-to-refresh

### API Optimization
- Batch API requests where possible
- Implement request debouncing for search/filters
- Cache frequently accessed data (balances, user info)
- Use optimistic updates for better UX

### Offline Support
- Cache critical data (balances, recent transactions)
- Queue operations when offline
- Sync automatically when connection restores
- Display offline indicator

## Security Considerations

### Authentication
- Store tokens in secure storage (flutter_secure_storage)
- Implement auto-logout after 30 minutes inactivity
- Require re-authentication for sensitive operations
- Clear all data on logout

### Data Protection
- Encrypt sensitive data at rest
- Use HTTPS for all API calls
- Implement certificate pinning
- Validate all user inputs

### Role-Based Access
- Enforce role checks on client side
- Verify permissions before displaying features
- Hide navigation items based on role
- Validate role on every API request

## Localization

### Supported Languages
- English (en)
- Arabic (ar)

### Implementation
- Use `flutter_localizations` package
- Generate ARB files for translations
- Support RTL layout for Arabic
- Format numbers and dates per locale

### Translation Keys Structure
```
auth.register.title
auth.register.joinCode
auth.register.success.superadmin
auth.register.success.admin
auth.register.success.user
navigation.groupManagement
navigation.cash
navigation.exchange
navigation.expenses
navigation.export
navigation.profile
errors.insufficientBalance
errors.invalidGroupCode
```

## Accessibility

### Screen Reader Support
- Semantic labels for all interactive elements
- Announce state changes
- Provide context for icons

### Visual Accessibility
- Minimum contrast ratio 4.5:1
- Support text scaling up to 200%
- Avoid color-only information
- Provide alternative text for images

### Interaction Accessibility
- Minimum touch target size 48dp
- Keyboard navigation support
- Haptic feedback for actions
- Clear focus indicators

## Deployment Strategy

### Build Variants
```bash
# Superadmin flavor
flutter build apk --flavor superadmin --target lib/main_superadmin.dart

# Admin flavor
flutter build apk --flavor admin --target lib/main_admin.dart

# User flavor
flutter build apk --flavor user --target lib/main_user.dart
```

### App Identifiers
- Superadmin: `com.finance.superadmin`
- Admin: `com.finance.admin`
- User: `com.finance.user`

### Distribution
- Separate APKs for each flavor
- Different app names and icons
- Independent version tracking
- Separate analytics tracking

## Migration Strategy

### Existing Users
- Detect user role on login
- Redirect to appropriate flavor
- Migrate local data if needed
- Provide migration guide

### Data Migration
- Preserve existing expenses, transfers, incoming
- Update models to support multi-currency
- Migrate organization/department to text fields
- Link users to appropriate groups

## Monitoring and Analytics

### Key Metrics
- Registration success rate per flavor
- Balance verification failure rate
- Exchange completion rate
- Export success rate
- API error rates
- App crash rate

### User Analytics
- Feature usage per flavor
- Navigation patterns
- Filter usage
- Export format preferences
- Average session duration

### Performance Metrics
- App launch time
- Page load times
- API response times
- Image load times
- Offline sync success rate
