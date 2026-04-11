# Testing Procedures

## Overview

This document outlines comprehensive testing procedures for the multi-flavor Finance application. It covers unit testing, widget testing, integration testing, and manual testing for all three flavors.

## Table of Contents

1. [Testing Strategy](#testing-strategy)
2. [Test Environment Setup](#test-environment-setup)
3. [Unit Testing](#unit-testing)
4. [Widget Testing](#widget-testing)
5. [Integration Testing](#integration-testing)
6. [Flavor-Specific Testing](#flavor-specific-testing)
7. [Manual Testing](#manual-testing)
8. [Performance Testing](#performance-testing)
9. [Security Testing](#security-testing)
10. [Test Reporting](#test-reporting)

## Testing Strategy

### Testing Pyramid

```
        /\
       /  \
      / E2E \
     /--------\
    /          \
   / Integration \
  /--------------\
 /                \
/   Unit Tests     \
--------------------
```

### Coverage Goals

- **Unit Tests**: 80% code coverage
- **Widget Tests**: All critical UI components
- **Integration Tests**: All major user flows
- **Manual Tests**: All flavors and features

### Test Types

1. **Unit Tests**: Test individual functions and classes
2. **Widget Tests**: Test UI components in isolation
3. **Integration Tests**: Test complete user flows
4. **Manual Tests**: Exploratory and acceptance testing

## Test Environment Setup

### Prerequisites

```bash
# Install Flutter
flutter --version

# Install dependencies
flutter pub get

# Verify test setup
flutter test --version
```

### Test Dependencies

Add to `pubspec.yaml`:
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0
  build_runner: ^2.4.0
  integration_test:
    sdk: flutter
  flutter_driver:
    sdk: flutter
```

### Mock Data Setup

Create test fixtures in `test/fixtures/`:
```
test/
├── fixtures/
│   ├── user_fixture.dart
│   ├── fund_box_fixture.dart
│   ├── transfer_fixture.dart
│   ├── exchange_fixture.dart
│   └── expense_fixture.dart
```

## Unit Testing

### Running Unit Tests

```bash
# Run all unit tests
flutter test

# Run specific test file
flutter test test/core/services/balance_verification_service_test.dart

# Run with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Unit Test Structure

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BalanceVerificationService', () {
    late BalanceVerificationService service;
    
    setUp(() {
      service = BalanceVerificationService();
    });
    
    tearDown(() {
      // Cleanup
    });
    
    test('verifyBalance returns true when sufficient balance', () async {
      // Arrange
      final userId = 'user123';
      final currency = 'USD';
      final amount = 100.0;
      
      // Act
      final result = await service.verifyBalance(
        userId: userId,
        currency: currency,
        amount: amount,
      );
      
      // Assert
      expect(result, isTrue);
    });
    
    test('verifyBalance throws InsufficientBalanceException', () async {
      // Arrange
      final userId = 'user123';
      final currency = 'USD';
      final amount = 1000.0;
      
      // Act & Assert
      expect(
        () => service.verifyBalance(
          userId: userId,
          currency: currency,
          amount: amount,
        ),
        throwsA(isA<InsufficientBalanceException>()),
      );
    });
  });
}
```

### Critical Unit Tests

**1. Data Models**
- JSON serialization/deserialization
- Field validation
- Null safety

**2. Services**
- Balance verification
- Filter persistence
- Image upload
- Offline queue

**3. BLoCs**
- State transitions
- Event handling
- Error handling

**4. Utilities**
- Currency formatting
- Date formatting
- Validation functions

## Widget Testing

### Running Widget Tests

```bash
# Run all widget tests
flutter test test/widgets/

# Run specific widget test
flutter test test/widgets/expense_form_test.dart

# Run with verbose output
flutter test --verbose
```

### Widget Test Structure

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ExpenseForm validates required fields', (tester) async {
    // Arrange
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpenseForm(),
        ),
      ),
    );
    
    // Act
    await tester.tap(find.text('Save'));
    await tester.pump();
    
    // Assert
    expect(find.text('Description is required'), findsOneWidget);
    expect(find.text('Amount is required'), findsOneWidget);
  });
  
  testWidgets('ExpenseForm submits with valid data', (tester) async {
    // Arrange
    bool submitted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpenseForm(
            onSubmit: (_) => submitted = true,
          ),
        ),
      ),
    );
    
    // Act
    await tester.enterText(
      find.byType(TextField).first,
      'Office Supplies',
    );
    await tester.enterText(
      find.byType(TextField).at(1),
      '100',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    
    // Assert
    expect(submitted, isTrue);
  });
}
```

### Critical Widget Tests

**1. Forms**
- Field validation
- Submit behavior
- Error display
- Loading states

**2. Lists**
- Item rendering
- Empty states
- Loading states
- Pull to refresh

**3. Navigation**
- Flavor-specific navigation
- Route guards
- Deep linking

**4. Dialogs**
- Display correctly
- User interactions
- Dismiss behavior

## Integration Testing

### Running Integration Tests

```bash
# Run integration tests
flutter test integration_test/

# Run on device
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart

# Run specific flavor
flutter drive \
  --flavor superadmin \
  --target=integration_test/superadmin_flow_test.dart
```

### Integration Test Structure

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Superadmin Registration Flow', () {
    testWidgets('Complete registration and receive group code', (tester) async {
      // Launch app
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      
      // Navigate to registration
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();
      
      // Fill registration form
      await tester.enterText(
        find.byKey(Key('name_field')),
        'Test Superadmin',
      );
      await tester.enterText(
        find.byKey(Key('email_field')),
        'superadmin@test.com',
      );
      await tester.enterText(
        find.byKey(Key('password_field')),
        'password123',
      );
      
      // Submit
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle(Duration(seconds: 5));
      
      // Verify success dialog with group code
      expect(find.text('Registration Successful'), findsOneWidget);
      expect(find.textContaining('Group Code:'), findsOneWidget);
      
      // Verify group code is 6 characters
      final groupCodeText = find.byKey(Key('group_code')).evaluate().first.widget as Text;
      expect(groupCodeText.data?.length, equals(6));
    });
  });
}
```

### Critical Integration Tests

**1. Authentication Flows**
- Superadmin registration with group code generation
- Admin registration with join code
- User registration with join code
- Login and logout

**2. Financial Operations**
- Create transfer → Balance updates
- Create exchange → Balance updates
- Create expense → Balance verification

**3. Group Management**
- Join group flow
- View members
- Remove member
- Regenerate code

**4. Export Flows**
- Apply filters
- Export to PDF
- Export to Excel
- Export invoice images

## Flavor-Specific Testing

### Testing Each Flavor

**Superadmin Flavor**:
```bash
flutter test --dart-define=FLAVOR=superadmin
flutter drive --flavor superadmin --target=integration_test/superadmin_test.dart
```

**Admin Flavor**:
```bash
flutter test --dart-define=FLAVOR=admin
flutter drive --flavor admin --target=integration_test/admin_test.dart
```

**User Flavor**:
```bash
flutter test --dart-define=FLAVOR=user
flutter drive --flavor user --target=integration_test/user_test.dart
```

### Flavor Test Checklist

For each flavor, verify:

**Navigation**:
- [ ] Correct navigation items displayed
- [ ] Correct default home page
- [ ] Hidden features not accessible

**Features**:
- [ ] Feature flags work correctly
- [ ] Role-specific features available
- [ ] Restricted features hidden

**Data Visibility**:
- [ ] Correct data scope displayed
- [ ] Cannot access unauthorized data
- [ ] Filters work correctly

**Registration**:
- [ ] Correct registration flow
- [ ] Group code handling (if applicable)
- [ ] Success dialog appropriate

## Manual Testing

### Manual Test Plan

#### Pre-Test Setup

1. Install all three flavor APKs on test device
2. Prepare test accounts:
   - 1 Superadmin account
   - 2 Admin accounts
   - 3 User accounts
3. Note group codes for testing
4. Prepare test data (receipts, amounts, etc.)

#### Superadmin Manual Tests

**Registration & Login**:
- [ ] Register new Superadmin
- [ ] Receive and copy group code
- [ ] Login with credentials
- [ ] Logout and login again

**Group Management**:
- [ ] View Admin list
- [ ] View Admin details
- [ ] Regenerate group code
- [ ] Remove Admin from group

**Financial Box**:
- [ ] View multi-currency balances
- [ ] Add incoming USD
- [ ] Verify balance updates

**Transfers**:
- [ ] Create transfer to Admin
- [ ] View transfer history
- [ ] Filter by Admin
- [ ] Filter by date
- [ ] Export to PDF

**Analytics**:
- [ ] View global summary
- [ ] View Admin group analytics
- [ ] Filter by period
- [ ] Filter by Admin group
- [ ] Export to PDF
- [ ] Export to Excel

**Profile**:
- [ ] View profile information
- [ ] Update profile
- [ ] Change password
- [ ] Change language
- [ ] Logout

#### Admin Manual Tests

**Registration & Login**:
- [ ] Register with Superadmin code
- [ ] Receive Admin group code
- [ ] Login with credentials
- [ ] Logout and login again

**Group Management**:
- [ ] View User list
- [ ] View User details
- [ ] Regenerate group code
- [ ] Remove User from group

**Financial Box**:
- [ ] View multi-currency balances
- [ ] View incoming transfers from Superadmin
- [ ] Create transfer to User
- [ ] View outgoing transfers
- [ ] Filter transfers
- [ ] Export transfers

**Exchange**:
- [ ] Create USD to SYP exchange
- [ ] Create USD to TRY exchange
- [ ] View Exchange Log
- [ ] View own exchanges
- [ ] View User exchanges
- [ ] Filter by currency
- [ ] Filter by user
- [ ] Export to PDF

**Expenses**:
- [ ] Create expense with invoice photo
- [ ] Create expense without photo
- [ ] View own expenses
- [ ] View User expenses
- [ ] Preview invoice photos
- [ ] Filter by date
- [ ] Filter by currency
- [ ] Filter by user

**Export**:
- [ ] Export expenses to PDF
- [ ] Export expenses to Excel
- [ ] Export invoice images to PDF
- [ ] Verify filters apply to export

**Profile**:
- [ ] Upload profile picture
- [ ] View profile information
- [ ] Update profile
- [ ] Change password
- [ ] Change language
- [ ] Logout

#### User Manual Tests

**Registration & Login**:
- [ ] Register with Admin code
- [ ] Login with credentials
- [ ] Logout and login again

**Home (Financial Box)**:
- [ ] View multi-currency balances
- [ ] View incoming transfers from Admin
- [ ] Refresh data

**Exchange**:
- [ ] Create USD to SYP exchange
- [ ] Create USD to TRY exchange
- [ ] View Exchange Log (own only)
- [ ] Filter by currency
- [ ] Export to PDF

**Expenses**:
- [ ] Create expense with invoice photo
- [ ] Create expense without photo
- [ ] View own expenses only
- [ ] Preview invoice photos
- [ ] Filter by date
- [ ] Filter by currency

**Export**:
- [ ] Export expenses to PDF
- [ ] Export expenses to Excel
- [ ] Export invoice images to PDF
- [ ] Verify only own data exported

**Profile**:
- [ ] Upload profile picture
- [ ] View group information
- [ ] Update profile
- [ ] Change password
- [ ] Change language
- [ ] Logout

### Cross-Flavor Tests

**Data Visibility**:
- [ ] Superadmin sees Admin data
- [ ] Superadmin doesn't see User data directly
- [ ] Admin sees User data in group
- [ ] Admin doesn't see other Admin data
- [ ] User sees only own data
- [ ] User doesn't see other User data

**Group Hierarchy**:
- [ ] Superadmin → Admin relationship works
- [ ] Admin → User relationship works
- [ ] Group codes work correctly
- [ ] Remove member works at each level

**Balance Flow**:
- [ ] Superadmin adds incoming → Balance increases
- [ ] Superadmin transfers to Admin → Balances update
- [ ] Admin transfers to User → Balances update
- [ ] Exchange updates correct currency balance
- [ ] Expense deducts from correct currency

## Performance Testing

### Load Testing

Test with large datasets:
- [ ] 100+ expenses
- [ ] 50+ transfers
- [ ] 30+ exchanges
- [ ] 20+ group members

Verify:
- [ ] Lists scroll smoothly
- [ ] Pagination works correctly
- [ ] Search/filter is responsive
- [ ] Export completes successfully

### Memory Testing

Monitor memory usage:
```bash
flutter run --profile
# Use DevTools to monitor memory
```

Check for:
- [ ] Memory leaks
- [ ] Excessive memory usage
- [ ] Proper disposal of resources

### Network Testing

Test under various conditions:
- [ ] Fast WiFi
- [ ] Slow 3G
- [ ] Intermittent connection
- [ ] Offline mode
- [ ] Connection recovery

## Security Testing

### Authentication Security

- [ ] Tokens stored securely
- [ ] Auto-logout after inactivity
- [ ] Password requirements enforced
- [ ] Session management works

### Data Security

- [ ] HTTPS used for all requests
- [ ] Sensitive data encrypted
- [ ] No data leakage in logs
- [ ] Proper data clearing on logout

### Authorization Testing

- [ ] Role-based access enforced
- [ ] Cannot access unauthorized endpoints
- [ ] Cannot view unauthorized data
- [ ] Feature flags respected

## Test Reporting

### Test Report Template

```markdown
# Test Report

**Date**: [Date]
**Tester**: [Name]
**App Version**: [Version]
**Flavor**: [Superadmin/Admin/User]

## Summary
- Total Tests: [Number]
- Passed: [Number]
- Failed: [Number]
- Blocked: [Number]

## Test Results

### Authentication
- [x] Registration: PASS
- [x] Login: PASS
- [ ] Logout: FAIL - [Description]

### [Feature Area]
- [x] [Test Case]: PASS
- [ ] [Test Case]: FAIL - [Description]

## Issues Found

### Issue 1
- **Severity**: High/Medium/Low
- **Description**: [Description]
- **Steps to Reproduce**: [Steps]
- **Expected**: [Expected behavior]
- **Actual**: [Actual behavior]
- **Screenshots**: [Attach if applicable]

## Recommendations
- [Recommendation 1]
- [Recommendation 2]
```

### Coverage Report

Generate coverage report:
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

Review coverage:
- [ ] Overall coverage > 80%
- [ ] Critical paths covered
- [ ] Edge cases tested
- [ ] Error handling tested

## Continuous Integration

### CI/CD Pipeline

Example GitHub Actions workflow:

```yaml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run unit tests
        run: flutter test --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v2
        with:
          files: coverage/lcov.info
      
      - name: Run integration tests
        run: flutter drive --target=integration_test/app_test.dart
```

## Best Practices

1. **Write Tests First**: TDD approach when possible
2. **Keep Tests Fast**: Unit tests should run in seconds
3. **Isolate Tests**: Each test should be independent
4. **Use Descriptive Names**: Test names should describe what they test
5. **Test Edge Cases**: Don't just test happy paths
6. **Mock External Dependencies**: Use mocks for API calls
7. **Clean Up**: Always clean up resources in tearDown
8. **Regular Testing**: Run tests before every commit
9. **Review Coverage**: Aim for high coverage on critical code
10. **Document Tests**: Add comments for complex test logic

---

**Version**: 1.0  
**Last Updated**: November 2024
