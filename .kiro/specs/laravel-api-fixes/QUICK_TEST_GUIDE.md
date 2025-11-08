# Quick Test Guide - Laravel API Integration

## Quick Start

### 1. Backend Setup (5 minutes)
```bash
cd financeApp-backend-main
php artisan serve
```
Backend should be running at: `http://localhost:8000`

### 2. Create Test Accounts (2 minutes)
```bash
# In backend directory
php artisan tinker

# Create admin user
User::create([
    'name' => 'Admin User',
    'email' => 'admin@test.com',
    'password' => bcrypt('password'),
    'role' => 'admin'
]);

# Create regular user
User::create([
    'name' => 'Regular User',
    'email' => 'user@test.com',
    'password' => bcrypt('password'),
    'role' => 'user'
]);
```

### 3. Run Automated API Test (2 minutes)
```bash
# From project root
dart run .kiro/specs/laravel-api-fixes/test_api_endpoints.dart
```

This will test all endpoints and show results.

### 4. Test User Flavor (10 minutes)
```bash
flutter run --flavor user
```

**Quick Test Flow:**
1. Login as `user@test.com` / `password`
2. Create a transfer
3. Create an income
4. Create an expense
5. View profile
6. Try to access admin features (should fail)

### 5. Test Admin Flavor (10 minutes)
```bash
flutter run --flavor admin
```

**Quick Test Flow:**
1. Login as `admin@test.com` / `password`
2. View Admin Dashboard
3. Access Fund Box
4. View Audit Logs
5. Create transactions
6. Export data

### 6. Test Access Control (5 minutes)
```bash
flutter run --flavor admin
```

1. Login as `user@test.com` / `password`
2. Try to access Fund Box → Should show "Access denied"
3. Try to access Admin Dashboard → Should show "Access denied"
4. Try to access Audit Logs → Should show "Access denied"
5. Verify app doesn't crash

## Critical Tests Checklist

### ✅ Must Pass Tests
- [ ] Login works for both users
- [ ] Transfers: Create, Read, Update, Delete
- [ ] Incoming: Create, Read, Update, Delete
- [ ] Expenses: Create, Read, Update, Delete
- [ ] Fund Box: Admin can access, User gets 403
- [ ] Admin Dashboard: Admin can access, User gets 403
- [ ] Field mappings match API spec
- [ ] Dates are YYYY-MM-DD format
- [ ] 403 errors don't crash app

### ⚠️ Important Tests
- [ ] Profile management works
- [ ] Export generates files
- [ ] Offline mode queues items
- [ ] Auto-sync works
- [ ] Pagination loads more items
- [ ] All error codes handled

## Field Mapping Quick Check

### Transfers
```json
{
  "amount": 100.50,
  "from_account": "Savings",    // ✓ Correct
  "to_account": "Checking",     // ✓ Correct
  "date": "2024-01-15",         // ✓ YYYY-MM-DD
  "description": "Test"
}
```

### Incoming
```json
{
  "amount": 500.00,
  "source": "Salary",           // ✓ Correct
  "payment_method": "bank_transfer", // ✓ Correct
  "date": "2024-01-15",         // ✓ YYYY-MM-DD
  "description": "Monthly"
}
```

### Fund Box
```json
{
  "total_balance": 10000.00     // ✓ Correct (not balance_usd)
}
```

### Admin Stats Response
```json
{
  "total_users": 10,            // ✓ Correct
  "total_expenses": 50,         // ✓ Correct
  "total_income": 30,           // ✓ Correct
  "total_transfers": 20,        // ✓ Correct
  "total_amount_expenses": 5000.00,  // ✓ Correct
  "total_amount_income": 3000.00,    // ✓ Correct
  "fund_box_balance": 10000.00       // ✓ Correct
}
```

## Common Issues

### Issue: "Connection refused"
**Solution:** Make sure Laravel backend is running on port 8000

### Issue: "Unauthenticated"
**Solution:** Check token is being sent in Authorization header

### Issue: "403 Forbidden"
**Solution:** This is expected for non-admin users accessing admin endpoints

### Issue: "422 Unprocessable Entity"
**Solution:** Check field names and date format (must be YYYY-MM-DD)

### Issue: "Field not found"
**Solution:** Verify DTO field mappings match API spec exactly

## Quick Postman Test

1. Import collection from `financeApp-backend-main/postman/`
2. Set environment variable `base_url` = `http://localhost:8000/api/v1`
3. Run "Login" request → Copy token
4. Set environment variable `token` = copied token
5. Run all requests in collection
6. Compare responses with app behavior

## Offline Mode Quick Test

1. Run app
2. Enable airplane mode on device
3. Create 3 expenses
4. Verify "Pending sync" indicator shows
5. Disable airplane mode
6. Verify auto-sync triggers
7. Verify items appear on server

## Performance Quick Check

Run these and verify response times:
- Login: < 1 second
- Create expense: < 500ms
- Load expenses list: < 1 second
- Load dashboard: < 2 seconds

## Sign-Off

After completing quick tests:
- [ ] All critical tests pass
- [ ] No crashes or errors
- [ ] Field mappings correct
- [ ] Access control works
- [ ] Ready for full testing

---

**Time Required:** ~30 minutes for quick validation
**Next Step:** Complete full manual testing checklist
