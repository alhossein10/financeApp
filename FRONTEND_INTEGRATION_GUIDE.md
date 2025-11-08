# Frontend Integration Guide - SuperAdmin and Multi-Currency Balance System

## Overview

This guide provides comprehensive instructions for integrating the new SuperAdmin and Multi-Currency Balance features into your Flutter frontend application.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Authentication Flow](#authentication-flow)
3. [API Endpoints Reference](#api-endpoints-reference)
4. [Data Models](#data-models)
5. [State Management](#state-management)
6. [UI/UX Recommendations](#uiux-recommendations)
7. [Error Handling](#error-handling)
8. [Complete Example Flows](#complete-example-flows)

---

## Architecture Overview

### User Roles Hierarchy

```
SuperAdmin
  ├── Admin Group 1
  │   ├── Admin 1
  │   │   └── Users (in Admin 1's group)
  │   └── Admin 2
  │       └── Users (in Admin 2's group)
  └── Admin Group 2
      └── Admin 3
          └── Users (in Admin 3's group)
```

### Transfer Flow

- **SuperAdmin → Admin**: SuperAdmin transfers funds to admins in their superAdmin group
- **Admin → User**: Admins transfer funds to users in their admin group
- **User**: Regular users cannot initiate transfers (except to themselves if needed)

### Balance Box System

Every user (SuperAdmin, Admin, User) has a multi-currency balance box:
- `balance_usd`: USD balance
- `balance_syp`: SYP (Syrian Pounds) balance  
- `balance_try`: TRY (Turkish Lira) balance

Balance updates automatically when:
- **Transfers received**: Increases USD balance
- **Exchanges made**: Decreases USD, increases target currency (SYP or TRY)
- **Expenses created**: Decreases balance in expense currency

### Performance Optimizations

The API includes several performance optimizations for large datasets:

- **Pagination Limits**: Maximum `per_page` is **100 items**. Requests for more than 100 will be automatically limited to 100.
- **Response Compression**: JSON responses over 1KB are automatically compressed with gzip. HTTP clients typically handle this automatically.
- **Caching**: Frequently accessed data is cached to improve response times.

---

## Authentication Flow

### Registration

#### SuperAdmin Registration

```dart
POST /api/v1/auth/register
{
  "name": "Super Admin",
  "email": "superadmin@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "role": "superAdmin",
  "organization_name": "Main Organization"
}

Response:
{
  "success": true,
  "data": {
    "user": { ... },
    "token": "...",
    "super_admin_group": {
      "id": 1,
      "group_code": "123456",
      "group_name": "Main Organization - Super Admin"
    }
  }
}
```

#### Admin Registration (with SuperAdmin Group Code)

```dart
POST /api/v1/auth/register
{
  "name": "Admin User",
  "email": "admin@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "role": "admin",
  "organization_name": "Main Organization",
  "super_admin_group_code": "123456"  // SuperAdmin's group code
}

Response:
{
  "success": true,
  "data": {
    "user": { ... },
    "token": "...",
    "admin_group": {
      "id": 1,
      "group_code": "789012",
      "group_name": "Main Organization - Admin User"
    }
  }
}
```

#### Regular User Registration

```dart
POST /api/v1/auth/register
{
  "name": "Regular User",
  "email": "user@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "role": "user",
  "organization_name": "Main Organization",
  "department_name": "Finance",
  "group_code": "789012"  // Admin's group code (optional)
}
```

### Login

All users use the same login endpoint:

```dart
POST /api/v1/auth/login
{
  "email": "user@example.com",
  "password": "password123"
}

Response:
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "name": "User Name",
      "email": "user@example.com",
      "role": "admin|user|superAdmin",
      "super_admin_group_id": null,  // For admins joined to superAdmin group
      "admin_group_id": null,  // For users in admin groups
      ...
    },
    "token": "...",
    "token_type": "Bearer",
    "expires_in": 2592000
  }
}
```

---

## API Endpoints Reference

### Base URL

```
https://your-api-domain.com/api/v1
```

All endpoints require authentication via Bearer token in the Authorization header.

### SuperAdmin Endpoints

#### Get Analytics

```dart
GET /super-admin/analytics?period=15days|month|all

Headers:
Authorization: Bearer {token}

Response:
{
  "success": true,
  "data": {
    "period": "15days",
    "start_date": "2025-10-21",
    "end_date": "2025-11-05",
    "admin_groups": [
      {
        "admin_group": {
          "id": 1,
          "name": "Admin Group 1",
          "code": "789012",
          "admin_user": {
            "id": 2,
            "name": "Admin Name",
            "email": "admin@example.com"
          }
        },
        "transfers": {
          "count": 15,
          "total_usd": 5000.00
        },
        "expenses": {
          "count": 45,
          "total_usd": 2500.00,
          "total_syp": 29000000.00,
          "total_try": 85000.00
        }
      }
    ]
  }
}
```

### Balance Box Endpoints

#### Get All Balances

```dart
GET /fund-box

Headers:
Authorization: Bearer {token}

Response:
{
  "success": true,
  "data": {
    "id": 1,
    "balance_usd": 1000.00,
    "balance_syp": 11600000.00,
    "balance_try": 35000.00,
    "last_calculated_at": "2025-11-05T10:00:00Z",
    "updated_at": "2025-11-05T10:00:00Z"
  }
}
```

#### Get Balance for Specific Currency

```dart
GET /fund-box?currency=USD|SYP|TRY

Response:
{
  "success": true,
  "data": {
    "currency": "USD",
    "balance": 1000.00
  }
}
```

### Exchange Endpoints

#### Create Exchange (Balance-Based)

```dart
POST /exchanges

Headers:
Authorization: Bearer {token}
Content-Type: application/json

Body:
{
  "transfer_id": null,  // Optional - for audit trail only
  "target_currency": "SYP",  // Required: "SYP" or "TRY"
  "amount_usd": 100.00,  // Amount from total balance box USD
  "exchange_rate": 11600.00,  // Manual entry
  "exchange_date": "2025-11-05",
  "notes": "Daily expenses exchange"
}

Response:
{
  "message": "Exchange created successfully",
  "data": {
    "id": 1,
    "transfer_id": null,
    "user_id": 1,
    "amount_usd": "100.00",
    "exchange_rate": "11600.00",
    "target_currency": "SYP",
    "amount_syp": "1160000.00",
    "amount_try": null,
    "exchange_date": "2025-11-05",
    "notes": "Daily expenses exchange"
  }
}
```

**Important Notes:**
- `transfer_id` is now **optional** (can be null)
- Exchange is based on **total balance box USD**, not transfer balance
- Balance box automatically updated: USD decreases, target currency increases

#### Get Exchange History with Currency Filter

```dart
GET /exchanges?currency=all|SYP|TRY

Response:
{
  "message": "Exchanges retrieved successfully",
  "data": [
    {
      "id": 1,
      "target_currency": "SYP",
      "amount_usd": "100.00",
      "amount_syp": "1160000.00",
      "exchange_rate": "11600.00",
      "exchange_date": "2025-11-05",
      ...
    },
    {
      "id": 2,
      "target_currency": "TRY",
      "amount_usd": "50.00",
      "amount_try": "1750.00",
      "exchange_rate": "35.00",
      "exchange_date": "2025-11-04",
      ...
    }
  ]
}
```

### Expense Endpoints

#### List Expenses (with Pagination)

```dart
GET /expenses?per_page=15&page=1

Query Parameters:
- per_page: Items per page (default: 15, maximum: 100)
- page: Page number (default: 1)
- expense_date_from: Filter from date (YYYY-MM-DD)
- expense_date_to: Filter to date (YYYY-MM-DD)
- search: Search in description
- has_invoice: Filter by invoice presence (true/false)

Response:
{
  "success": true,
  "data": [
    {
      "id": 1,
      "description": "Office supplies",
      "price_usd": 50.00,
      "price_syp": null,
      "price_try": null,
      "expense_date": "2025-11-05",
      ...
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 15,
    "total": 45,
    "last_page": 3
  }
}
```

**Note**: Maximum `per_page` is 100. Requests for more than 100 will be automatically limited to 100.

#### Create Expense (with Balance Validation)

```dart
POST /expenses

Headers:
Authorization: Bearer {token}
Content-Type: multipart/form-data

Body:
{
  "description": "Office supplies",
  "price_usd": 50.00,  // Optional - one of price_usd, price_syp, or price_try required
  "price_syp": null,   // Optional
  "price_try": null,   // Optional
  "expense_date": "2025-11-05",
  "photo": <file>  // Optional
}

Response:
{
  "success": true,
  "data": {
    "id": 1,
    "description": "Office supplies",
    "price_usd": "50.00",
    "price_syp": null,
    "price_try": null,
    "expense_date": "2025-11-05",
    ...
  }
}
```

**Important Notes:**
- Expense creation **validates sufficient balance** before allowing
- Balance box **automatically decreases** in the expense currency
- If insufficient balance, returns error: `"Insufficient USD balance. Available: X USD"`

### Transfer Endpoints

#### Create Transfer (SuperAdmin to Admin)

```dart
POST /transfers

Headers:
Authorization: Bearer {token}  // SuperAdmin token

Body:
{
  "recipient_user_id": 2,  // Admin user ID
  "recipient_name": "Admin Name",
  "amount_usd": 1000.00,
  "transfer_date": "2025-11-05",
  "notes": "Monthly allocation"
}

Response:
{
  "success": true,
  "data": {
    "id": 1,
    "recipient_user_id": 2,
    "amount_usd": "1000.00",
    ...
  }
}
```

**Important Notes:**
- SuperAdmin can only transfer to **admins in their superAdmin group**
- Admin can only transfer to **users in their admin group**
- Recipient's balance box **automatically increases** by transfer amount (USD)

### Incoming Endpoints

#### Create Incoming (Blocked for Admins)

```dart
POST /incoming

Headers:
Authorization: Bearer {token}

Body:
{
  "description": "Client payment",
  "amount_usd": 500.00,
  "incoming_date": "2025-11-05"
}

Response for Admin:
{
  "success": false,
  "message": "Admins cannot create incoming records. They receive funds from superAdmin transfers."
}
```

**Important Notes:**
- **Regular users** and **superAdmin** can create incoming
- **Admins** are **blocked** from creating incoming
- Admins receive funds via transfers from superAdmin

---

## Data Models

### User Model

```dart
class User {
  final int id;
  final String name;
  final String email;
  final String role; // 'superAdmin', 'admin', or 'user'
  final int? superAdminGroupId; // For admins joined to superAdmin group
  final int? adminGroupId; // For users in admin groups
  final String organizationName;
  final String? departmentName;
  
  bool get isSuperAdmin => role == 'superAdmin';
  bool get isAdmin => role == 'admin';
  bool get isUser => role == 'user';
}
```

### Balance Box Model

```dart
class BalanceBox {
  final int id;
  final int userId;
  final double balanceUsd;
  final double balanceSyp;
  final double balanceTry;
  final DateTime? lastCalculatedAt;
  final DateTime updatedAt;
}
```

### Exchange Model

```dart
class Exchange {
  final int id;
  final int? transferId; // Optional - can be null
  final int userId;
  final String targetCurrency; // 'SYP' or 'TRY'
  final double amountUsd;
  final double exchangeRate;
  final double? amountSyp; // null if targetCurrency is TRY
  final double? amountTry; // null if targetCurrency is SYP
  final DateTime exchangeDate;
  final String? notes;
}
```

### Expense Model

```dart
class Expense {
  final int id;
  final int userId;
  final String description;
  final double? priceUsd;
  final double? priceSyp;
  final double? priceTry;
  final DateTime expenseDate;
  final bool hasInvoice;
  final String? invoicePath;
  // ...
}
```

### SuperAdmin Analytics Model

```dart
class SuperAdminAnalytics {
  final String period; // '15days', 'month', 'all'
  final DateTime? startDate;
  final DateTime endDate;
  final List<AdminGroupAnalytics> adminGroups;
}

class AdminGroupAnalytics {
  final AdminGroupInfo adminGroup;
  final TransferStats transfers;
  final ExpenseStats expenses;
}

class AdminGroupInfo {
  final int id;
  final String name;
  final String code;
  final AdminUser adminUser;
}

class TransferStats {
  final int count;
  final double totalUsd;
}

class ExpenseStats {
  final int count;
  final double totalUsd;
  final double totalSyp;
  final double totalTry;
}
```

---

## State Management

### Recommended: Bloc Pattern

#### Balance Box Bloc

```dart
// Events
abstract class BalanceBoxEvent {}
class LoadBalanceBox extends BalanceBoxEvent {}
class RefreshBalanceBox extends BalanceBoxEvent {}

// States
abstract class BalanceBoxState {}
class BalanceBoxInitial extends BalanceBoxState {}
class BalanceBoxLoading extends BalanceBoxState {}
class BalanceBoxLoaded extends BalanceBoxState {
  final BalanceBox balanceBox;
  BalanceBoxLoaded(this.balanceBox);
}
class BalanceBoxError extends BalanceBoxState {
  final String message;
  BalanceBoxError(this.message);
}

// Bloc
class BalanceBoxBloc extends Bloc<BalanceBoxEvent, BalanceBoxState> {
  final BalanceBoxRepository repository;
  
  BalanceBoxBloc(this.repository) : super(BalanceBoxInitial()) {
    on<LoadBalanceBox>(_onLoadBalanceBox);
    on<RefreshBalanceBox>(_onRefreshBalanceBox);
  }
  
  Future<void> _onLoadBalanceBox(
    LoadBalanceBox event,
    Emitter<BalanceBoxState> emit,
  ) async {
    emit(BalanceBoxLoading());
    try {
      final balanceBox = await repository.getBalanceBox();
      emit(BalanceBoxLoaded(balanceBox));
    } catch (e) {
      emit(BalanceBoxError(e.toString()));
    }
  }
  
  // ... refresh handler
}
```

#### Exchange Bloc

```dart
// Events
abstract class ExchangeEvent {}
class CreateExchange extends ExchangeEvent {
  final String targetCurrency; // 'SYP' or 'TRY'
  final double amountUsd;
  final double exchangeRate;
  final DateTime exchangeDate;
  final String? notes;
  final int? transferId; // Optional
}
class LoadExchanges extends ExchangeEvent {
  final String? currency; // 'all', 'SYP', or 'TRY'
}

// States and Bloc implementation...
```

---

## UI/UX Recommendations

### 1. Balance Box Display

#### Multi-Currency Tabs

```dart
class BalanceBoxWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BalanceBoxBloc, BalanceBoxState>(
      builder: (context, state) {
        if (state is BalanceBoxLoaded) {
          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(
                  tabs: [
                    Tab(text: 'USD \$${state.balanceBox.balanceUsd.toStringAsFixed(2)}'),
                    Tab(text: 'SYP ${state.balanceBox.balanceSyp.toStringAsFixed(2)}'),
                    Tab(text: 'TRY ${state.balanceBox.balanceTry.toStringAsFixed(2)}'),
                  ],
                ),
                TabBarView(
                  children: [
                    CurrencyBalanceView(state.balanceBox.balanceUsd, 'USD'),
                    CurrencyBalanceView(state.balanceBox.balanceSyp, 'SYP'),
                    CurrencyBalanceView(state.balanceBox.balanceTry, 'TRY'),
                  ],
                ),
              ],
            ),
          );
        }
        return CircularProgressIndicator();
      },
    );
  }
}
```

#### Card-Based Display

```dart
class BalanceBoxCards extends StatelessWidget {
  final BalanceBox balanceBox;
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: BalanceCard(
            currency: 'USD',
            balance: balanceBox.balanceUsd,
            color: Colors.green,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: BalanceCard(
            currency: 'SYP',
            balance: balanceBox.balanceSyp,
            color: Colors.blue,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: BalanceCard(
            currency: 'TRY',
            balance: balanceBox.balanceTry,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }
}
```

### 2. Exchange Creation Flow

#### Step-by-Step Exchange Form

```dart
class CreateExchangePage extends StatefulWidget {
  @override
  State<CreateExchangePage> createState() => _CreateExchangePageState();
}

class _CreateExchangePageState extends State<CreateExchangePage> {
  String? selectedCurrency; // 'SYP' or 'TRY'
  double? amountUsd;
  double? exchangeRate;
  double? availableUsd;
  
  @override
  void initState() {
    super.initState();
    // Load current USD balance
    context.read<BalanceBoxBloc>().add(LoadBalanceBox());
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BalanceBoxBloc, BalanceBoxState>(
      builder: (context, state) {
        if (state is BalanceBoxLoaded) {
          availableUsd = state.balanceBox.balanceUsd;
        }
        return Scaffold(
          appBar: AppBar(title: Text('Create Exchange')),
          body: Form(
            child: Column(
              children: [
                // Currency Selection
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Target Currency'),
                  items: ['SYP', 'TRY'].map((currency) {
                    return DropdownMenuItem(
                      value: currency,
                      child: Text(currency),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedCurrency = value),
                ),
                
                // Available Balance Display
                if (availableUsd != null)
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text('Available USD Balance'),
                          Text(
                            '\$${availableUsd!.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Amount Input
                TextFormField(
                  decoration: InputDecoration(labelText: 'Amount (USD)'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setState(() {
                    amountUsd = double.tryParse(value);
                  }),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Amount is required';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Amount must be greater than 0';
                    }
                    if (availableUsd != null && amount > availableUsd!) {
                      return 'Insufficient balance. Available: \$${availableUsd!.toStringAsFixed(2)}';
                    }
                    return null;
                  },
                ),
                
                // Exchange Rate Input
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Exchange Rate (1 USD = X ${selectedCurrency ?? "Currency"})',
                    helperText: 'Enter current exchange rate manually',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setState(() {
                    exchangeRate = double.tryParse(value);
                  }),
                ),
                
                // Preview
                if (amountUsd != null && exchangeRate != null && selectedCurrency != null)
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text('Exchange Preview'),
                          Text('USD: \$${amountUsd!.toStringAsFixed(2)}'),
                          Text('Rate: ${exchangeRate!.toStringAsFixed(2)}'),
                          Text(
                            '$selectedCurrency: ${(amountUsd! * exchangeRate!).toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Submit Button
                ElevatedButton(
                  onPressed: _canSubmit() ? _submitExchange : null,
                  child: Text('Create Exchange'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  bool _canSubmit() {
    return selectedCurrency != null &&
           amountUsd != null &&
           amountUsd! > 0 &&
           exchangeRate != null &&
           exchangeRate! > 0 &&
           availableUsd != null &&
           amountUsd! <= availableUsd!;
  }
  
  void _submitExchange() {
    context.read<ExchangeBloc>().add(CreateExchange(
      targetCurrency: selectedCurrency!,
      amountUsd: amountUsd!,
      exchangeRate: exchangeRate!,
      exchangeDate: DateTime.now(),
      transferId: null, // Optional - can be null for balance-based exchange
    ));
  }
}
```

### 3. SuperAdmin Analytics Dashboard

```dart
class SuperAdminAnalyticsPage extends StatefulWidget {
  @override
  State<SuperAdminAnalyticsPage> createState() => _SuperAdminAnalyticsPageState();
}

class _SuperAdminAnalyticsPageState extends State<SuperAdminAnalyticsPage> {
  String selectedPeriod = 'month'; // '15days', 'month', 'all'
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Analytics Dashboard')),
      body: Column(
        children: [
          // Period Filter
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: '15days', label: Text('15 Days')),
              ButtonSegment(value: 'month', label: Text('Month')),
              ButtonSegment(value: 'all', label: Text('All Time')),
            ],
            selected: {selectedPeriod},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                selectedPeriod = newSelection.first;
              });
              context.read<SuperAdminAnalyticsBloc>().add(
                LoadAnalytics(period: selectedPeriod),
              );
            },
          ),
          
          // Analytics List
          Expanded(
            child: BlocBuilder<SuperAdminAnalyticsBloc, SuperAdminAnalyticsState>(
              builder: (context, state) {
                if (state is SuperAdminAnalyticsLoaded) {
                  return ListView.builder(
                    itemCount: state.analytics.adminGroups.length,
                    itemBuilder: (context, index) {
                      final groupAnalytics = state.analytics.adminGroups[index];
                      return AdminGroupAnalyticsCard(groupAnalytics);
                    },
                  );
                }
                return CircularProgressIndicator();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AdminGroupAnalyticsCard extends StatelessWidget {
  final AdminGroupAnalytics analytics;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              analytics.adminGroup.name,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('Code: ${analytics.adminGroup.code}'),
            Text('Admin: ${analytics.adminGroup.adminUser.name}'),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Transfers',
                  count: analytics.transfers.count,
                  total: analytics.transfers.totalUsd,
                  currency: 'USD',
                ),
                _StatItem(
                  label: 'Expenses',
                  count: analytics.expenses.count,
                  totalUsd: analytics.expenses.totalUsd,
                  totalSyp: analytics.expenses.totalSyp,
                  totalTry: analytics.expenses.totalTry,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### 4. Admin Registration with SuperAdmin Group Code

```dart
class AdminRegistrationPage extends StatefulWidget {
  @override
  State<AdminRegistrationPage> createState() => _AdminRegistrationPageState();
}

class _AdminRegistrationPageState extends State<AdminRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _superAdminGroupCodeController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Registration')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Standard registration fields...
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            // ... email, password, etc.
            
            // SuperAdmin Group Code (Optional but recommended)
            TextFormField(
              controller: _superAdminGroupCodeController,
              decoration: InputDecoration(
                labelText: 'SuperAdmin Group Code (Optional)',
                helperText: 'Enter the code provided by your SuperAdmin',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!RegExp(r'^\d{4,6}$').hasMatch(value)) {
                    return 'Code must be 4-6 digits';
                  }
                }
                return null;
              },
            ),
            
            ElevatedButton(
              onPressed: _submitRegistration,
              child: Text('Register as Admin'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _submitRegistration() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(RegisterEvent(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        role: 'admin',
        organizationName: _organizationController.text,
        superAdminGroupCode: _superAdminGroupCodeController.text.isEmpty
            ? null
            : _superAdminGroupCodeController.text,
      ));
    }
  }
}
```

---

## Error Handling

### Common Error Scenarios

#### 1. Insufficient Balance

```dart
try {
  await exchangeRepository.createExchange(exchangeData);
} on ApiException catch (e) {
  if (e.message.contains('Insufficient USD balance')) {
    showErrorSnackBar(
      'Insufficient balance. Available: ${e.availableBalance} USD',
    );
  }
}
```

#### 2. Admin Cannot Create Incoming

```dart
try {
  await incomingRepository.createIncoming(incomingData);
} on ApiException catch (e) {
  if (e.message.contains('Admins cannot create incoming')) {
    showErrorSnackBar(
      'Admins receive funds from superAdmin transfers only.',
    );
  }
}
```

#### 3. Invalid SuperAdmin Group Code

```dart
try {
  await authRepository.register(registrationData);
} on ValidationException catch (e) {
  if (e.errors.containsKey('super_admin_group_code')) {
    showErrorSnackBar(
      'Invalid superAdmin group code. Please check with your SuperAdmin.',
    );
  }
}
```

### Error Widget

```dart
class ErrorHandler {
  static void handleApiError(BuildContext context, dynamic error) {
    String message = 'An error occurred';
    
    if (error is ApiException) {
      message = error.message;
    } else if (error is ValidationException) {
      message = error.errors.values.first.first;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
  }
}
```

---

## Complete Example Flows

### Flow 1: SuperAdmin Setup and Admin Registration

1. **SuperAdmin registers** → Receives superAdmin group code
2. **SuperAdmin shares code** with admins
3. **Admin registers** with superAdmin group code
4. **Admin receives** admin group code
5. **Admin shares admin group code** with users

### Flow 2: Transfer and Exchange Flow

1. **SuperAdmin transfers** $1000 to Admin
   - Admin's balance_usd increases by $1000
2. **Admin transfers** $500 to User
   - User's balance_usd increases by $500
3. **User exchanges** $100 USD to SYP at rate 11,600
   - User's balance_usd decreases by $100
   - User's balance_syp increases by 1,160,000
4. **User creates expense** of 50,000 SYP
   - User's balance_syp decreases by 50,000

### Flow 3: Multi-Currency Expense

1. **User has balances**:
   - USD: $500
   - SYP: 1,000,000
   - TRY: 15,000
2. **User creates expense** with price_usd: $50
   - Balance validation: $500 >= $50 ✓
   - Expense created
   - Balance_usd decreases to $450
3. **User creates expense** with price_try: 5,000
   - Balance validation: 15,000 >= 5,000 ✓
   - Expense created
   - Balance_try decreases to 10,000

### Flow 4: SuperAdmin Analytics

1. **SuperAdmin views analytics** for "month" period
2. **System aggregates** data per admin group:
   - Admin Group 1: 15 transfers ($5000), 45 expenses ($2500 USD, $29M SYP)
   - Admin Group 2: 8 transfers ($2000), 20 expenses ($1200 USD)
3. **SuperAdmin sees** aggregated numbers only (no detailed transactions)

---

## Package Recommendations

```yaml
dependencies:
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  dio: ^5.4.0
  shared_preferences: ^2.2.2
  intl: ^0.18.1  # For currency formatting
  flutter_form_builder: ^9.1.1
  image_picker: ^1.0.5  # For expense photos
```

---

## HTTP Client Setup

```dart
class ApiClient {
  static Dio createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://your-api-domain.com/api/v1',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Accept-Encoding': 'gzip, deflate', // Enable response compression
      },
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
    ));
    
    // Add auth interceptor
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = AuthService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Handle logout
          AuthService.logout();
        }
        return handler.next(error);
      },
    ));
    
    return dio;
  }
}
```

**Note**: Response compression is handled automatically by Dio. The `Accept-Encoding` header enables gzip compression for responses over 1KB.

---

## Testing Checklist

- [ ] SuperAdmin registration and group code generation
- [ ] Admin registration with superAdmin group code
- [ ] Balance box multi-currency display
- [ ] Exchange creation (balance-based, no transfer required)
- [ ] Exchange history filtering (all, SYP, TRY)
- [ ] Expense creation with balance validation
- [ ] Transfer flow: SuperAdmin → Admin → User
- [ ] Admin blocked from creating incoming
- [ ] SuperAdmin analytics with period filters
- [ ] Currency formatting (USD, SYP, TRY)
- [ ] Error handling for insufficient balance
- [ ] Real-time balance updates after transactions

---

## Next Steps

1. Implement data models in your Flutter app
2. Set up API client with authentication
3. Create Bloc/Provider for state management
4. Build UI components following recommendations
5. Test all flows thoroughly
6. Handle edge cases and errors gracefully

For questions or issues, refer to the API documentation or contact the backend team.

