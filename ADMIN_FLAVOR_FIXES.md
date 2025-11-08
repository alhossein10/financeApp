# Admin Flavor Fixes - Complete

## Issues Fixed

### 1. ✅ Cash Page Hidden in Admin Flavor
**Problem**: Cash page was hidden in admin flavor (should only be hidden in user flavor)
**Solution**: Already correctly configured in `flavor_config.dart`:
- Admin flavor: `enableCashModule: true`
- User flavor: `enableCashModule: false`

The cash page visibility is controlled by user role in `main.dart`, which checks both flavor config AND user role.

### 2. ✅ Admin Registration
**Problem**: Registering in admin flavor created regular users instead of admin users
**Solution**: Added role parameter throughout the registration flow:

**Files Modified**:
- `lib/features/auth/presentation/pages/register_page.dart` - Detects admin flavor and sends role
- `lib/features/auth/presentation/bloc/auth_event.dart` - Added role parameter to AuthRegisterRequested
- `lib/features/auth/presentation/bloc/auth_bloc.dart` - Passes role to usecase
- `lib/features/auth/domain/usecases/register_usecase.dart` - Added role to RegisterParams
- `lib/features/auth/domain/repositories/auth_repository.dart` - Added role parameter
- `lib/features/auth/data/repositories/auth_repository_impl.dart` - Passes role to API
- `lib/features/auth/data/datasources/auth_api_datasource.dart` - Added role parameter
- `lib/core/services/laravel_auth_service.dart` - Sends role to backend

**Backend**: Already supports role parameter in `RegisterRequest.php` and `AuthService.php`

### 3. ✅ Login Error: "type 'Null' is not a subtype of type 'int'"
**Problem**: When logging in with admin user created via Postman, the app crashed because the role field was null
**Solution**: Fixed `UserDto.fromJson` to handle null role:

**File Modified**:
- `lib/core/api/models/user_dto.dart` - Changed `role: json['role'] as String` to `role: (json['role'] as String?) ?? 'user'`

This ensures that if the backend returns null for role, it defaults to 'user' instead of crashing.

## How It Works Now

### Admin Flavor Registration:
1. User opens admin flavor app
2. Registers with email/password
3. App detects `FlavorConfig.instance.isAdmin == true`
4. Sends `role: 'admin'` to backend
5. Backend creates admin user
6. User logs in with admin privileges

### User Flavor Registration:
1. User opens user flavor app
2. Registers with email/password
3. App detects `FlavorConfig.instance.isAdmin == false`
4. Sends `role: 'user'` to backend
5. Backend creates regular user
6. User logs in with limited privileges

### Cash Page Visibility:
- **Admin users**: See cash page (both flavor config and user role allow it)
- **Regular users**: Don't see cash page (flavor config disables it)

## Testing

### Test Admin Registration:
1. Build admin flavor: `flutter run --flavor admin`
2. Register a new account
3. Check backend database - user should have `role = 'admin'`
4. Login - should see admin dashboard and cash page

### Test User Registration:
1. Build user flavor: `flutter run --flavor user`
2. Register a new account
3. Check backend database - user should have `role = 'user'`
4. Login - should NOT see admin dashboard or cash page

### Test Existing Admin Login:
1. Create admin user via Postman or backend
2. Login in admin flavor app
3. Should work without "type 'Null' is not a subtype" error
4. Should see admin dashboard and all features

## Backend Migration Reminder

Don't forget to run the database migration for the expense price_usd fix:
```bash
cd financeApp-backend-main
php artisan migrate
```

This makes `price_usd` nullable so you can create expenses with only SYP or TRY.
