# Post-Authentication Fixes Needed

## ✅ Working
- Registration ✅
- Login ✅

## ❌ Issues to Fix

### 1. Profile Page Error
**Error:** `ProfileRepositoryImpl is not registered inside GetIt`

**Cause:** ProfileRepository not registered in dependency injection

**Fix:** Already registered in `injection_container.dart` - need to restart app

### 2. Logout After Registration Doesn't Work
**Cause:** State management issue after registration

**Fix:** Need to properly clear auth state

### 3. User Flavor Shows Cash Page
**Issue:** Cash module should be hidden in user flavor

**Expected:** User flavor should NOT show Cash/Cashbox pages

### 4. App Title Shows "Finance Admin" in User Flavor
**Issue:** Wrong app name displayed

**Expected:** Should show "Finance App" or "Finance User"

### 5. Expenses Don't Show After Creation
**Issue:** Created expenses don't appear in list or database

**Cause:** API call might be failing or response not handled

### 6. User Filter in Expenses (User Flavor)
**Issue:** User flavor shows user filter dropdown

**Expected:** User filter should only appear in Admin flavor

## Quick Fixes

### Fix 1: Restart App
The ProfileRepository IS registered, just need to restart:

```bash
# Stop the app (Ctrl+C)
# Then run again
flutter run --flavor user --dart-define=API_BASE_URL=http://192.168.137.1:8000
```

### Fix 2-6: Code fixes needed

These require code changes which I'll provide in separate files.

## Priority Order

1. **Restart app** - Fixes profile issue
2. **Fix flavor configuration** - Hides Cash page in user flavor
3. **Fix app title** - Shows correct name
4. **Fix expenses** - Makes CRUD work
5. **Fix logout** - Clears state properly
6. **Fix filters** - Hides admin-only features

---

**Status:** Registration/Login working ✅  
**Next:** Apply fixes for remaining issues
