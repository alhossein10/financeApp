# Laravel Sanctum Installation Instructions

## Overview
Task 1 of the finance backend API implementation requires Laravel Sanctum for API token authentication. Due to SSL certificate issues during the automated installation, Sanctum needs to be installed manually.

## Manual Installation Steps

### 1. Install Laravel Sanctum via Composer

Run the following command in your terminal:

```bash
composer require laravel/sanctum
```

If you encounter SSL certificate errors, try one of these solutions:

**Option A: Disable SSL verification temporarily (not recommended for production)**
```bash
composer config -g -- disable-tls true
composer require laravel/sanctum
composer config -g -- disable-tls false
```

**Option B: Update your CA certificates**
- Windows: Download and install the latest CA certificates from https://curl.se/docs/caextract.html
- Update your php.ini file to point to the certificate bundle

**Option C: Use a different network or VPN**
Sometimes corporate networks or firewalls cause SSL issues.

### 2. Verify Installation

After successful installation, verify that Sanctum is installed:

```bash
composer show laravel/sanctum
```

### 3. Run Migrations

Once Sanctum is installed, run the migrations to create the necessary database tables:

```bash
php artisan migrate
```

This will create:
- `personal_access_tokens` table (for Sanctum tokens)
- Add `role` column to `users` table
- Add `deleted_at` column to `users` table (soft deletes)

## What Has Been Configured

The following components have already been set up:

### 1. User Model (`app/Models/User.php`)
- Added `HasApiTokens` trait from Sanctum
- Added `SoftDeletes` trait
- Added `role` to fillable attributes
- Added `isAdmin()` and `isUser()` helper methods

### 2. Middleware
- **EnsureUserIsAdmin** (`app/Http/Middleware/EnsureUserIsAdmin.php`): Checks if the authenticated user has admin role
- **EnsureUserIsAuthenticated** (`app/Http/Middleware/EnsureUserIsAuthenticated.php`): Ensures the user is authenticated

### 3. Middleware Aliases (in `bootstrap/app.php`)
- `auth.api`: Maps to EnsureUserIsAuthenticated middleware
- `admin`: Maps to EnsureUserIsAdmin middleware

### 4. Authentication Guard (in `config/auth.php`)
- Added `sanctum` guard configuration

### 5. Sanctum Configuration (`config/sanctum.php`)
- Token expiration: 43200 minutes (30 days)
- Stateful domains configured for local development

### 6. Environment Variables (`.env` and `.env.example`)
```
SANCTUM_STATEFUL_DOMAINS=localhost,localhost:3000,127.0.0.1,127.0.0.1:8000
SANCTUM_TOKEN_EXPIRATION=43200
```

### 7. Database Migrations
- `2019_12_14_000001_create_personal_access_tokens_table.php`: Creates Sanctum's token table
- `2025_10_21_165816_add_role_to_users_table.php`: Adds role and soft deletes to users table

### 8. API Routes (`routes/api.php`)
- Created with a sample authenticated route

## Testing the Setup

After installing Sanctum and running migrations, you can test the setup:

1. Create a test user with admin role:
```php
php artisan tinker
>>> $user = \App\Models\User::create([
    'name' => 'Admin User',
    'email' => 'admin@example.com',
    'password' => bcrypt('password'),
    'role' => 'admin'
]);
>>> $token = $user->createToken('test-token')->plainTextToken;
>>> echo $token;
```

2. Test the API endpoint:
```bash
curl -H "Authorization: Bearer YOUR_TOKEN_HERE" http://localhost:8000/api/user
```

## Next Steps

Once Sanctum is installed and migrations are run, you can proceed to Task 2: "Implement authentication endpoints and services"

## Requirements Satisfied

This implementation satisfies the following requirements from the specification:
- **Requirement 1.1**: User authentication with token-based system
- **Requirement 1.2**: Token generation with 30-day expiration
- **Requirement 1.3**: Unauthorized access returns 401 response
- **Requirement 1.4**: Admin role information in authentication

## Troubleshooting

### Issue: "Class 'Laravel\Sanctum\HasApiTokens' not found"
**Solution**: Sanctum is not installed. Follow the manual installation steps above.

### Issue: "Table 'personal_access_tokens' doesn't exist"
**Solution**: Run `php artisan migrate` to create the required tables.

### Issue: Middleware not working
**Solution**: Clear the application cache:
```bash
php artisan config:clear
php artisan cache:clear
php artisan route:clear
```
