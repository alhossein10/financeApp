# Quick Setup Guide - Finance Backend API

## Prerequisites
- PHP 8.2 or higher
- Composer
- MySQL (via XAMPP or standalone)
- Node.js & NPM (for frontend assets)

## Step-by-Step Setup

### 1. Fix Composer SSL Issue (if needed)
If you get SSL certificate errors with Composer, run:
```bash
composer config -g -- disable-tls false
composer config -g -- secure-http false
```

Or temporarily:
```bash
composer install --ignore-platform-reqs
```

### 2. Install PHP Dependencies
```bash
composer install
```

### 3. Setup Environment File
```bash
copy .env.example .env
```

### 4. Generate Application Key
```bash
php artisan key:generate
```

### 5. Configure Database

**Option A: Using XAMPP**
1. Start XAMPP Control Panel
2. Start Apache and MySQL
3. Open phpMyAdmin: http://localhost/phpmyadmin
4. Create a new database named: `finance_backend`

**Option B: Using MySQL directly**
```sql
CREATE DATABASE finance_backend CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

**Update .env file** with your database credentials:
```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=finance_backend
DB_USERNAME=root
DB_PASSWORD=your_password_here
```

### 6. Run Database Migrations
```bash
php artisan migrate
```

### 7. Seed Database (Optional - for testing)
```bash
# Seed with admin user and sample data
php artisan db:seed --class=DevelopmentSeeder

# Or just create admin user
php artisan db:seed --class=AdminUserSeeder
```

**Default Admin Credentials:**
- Email: admin@example.com
- Password: password123

### 8. Create Storage Link
```bash
php artisan storage:link
```

### 9. Install Frontend Dependencies (Optional)
```bash
npm install
npm run build
```

### 10. Generate API Documentation
```bash
php artisan l5-swagger:generate
```

### 11. Start the Server

**Option A: Using PHP Artisan (Recommended for development)**
```bash
php artisan serve
```
Server will run at: http://localhost:8000

**Option B: Using XAMPP Apache**
- Configure Apache to point to your `public` folder
- Access via: http://localhost/finance_backend/public

### 12. Start Queue Worker (Optional - for background jobs)
Open a new terminal:
```bash
php artisan queue:work
```

Or use the batch file:
```bash
run-queue-worker.bat
```

### 13. Start Scheduler (Optional - for scheduled tasks)
Open another terminal:
```bash
php artisan schedule:work
```

Or use the batch file:
```bash
run-scheduler.bat
```

## Testing the API

### Access API Documentation
- Swagger UI: http://localhost:8000/api/documentation
- API Base URL: http://localhost:8000/api/v1

### Test with Postman
1. Import the collection: `postman/Finance-API.postman_collection.json`
2. Import environment: `postman/Finance-API-Local.postman_environment.json`
3. Start testing!

### Quick API Test
```bash
# Register a new user
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Test User\",\"email\":\"test@example.com\",\"password\":\"password123\",\"password_confirmation\":\"password123\"}"
```

## Common Issues & Solutions

### Issue: "Class not found" errors
**Solution:**
```bash
composer dump-autoload
```

### Issue: Permission errors on storage/logs
**Solution:**
```bash
# Windows (run as administrator)
icacls storage /grant Users:F /T
icacls bootstrap/cache /grant Users:F /T
```

### Issue: Database connection refused
**Solution:**
- Make sure MySQL is running in XAMPP
- Check DB credentials in .env file
- Test connection: `php artisan tinker` then `DB::connection()->getPdo();`

### Issue: 500 error on API calls
**Solution:**
```bash
# Clear all caches
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear
```

## Project Structure

```
finance_backend/
├── app/                    # Application code
│   ├── Http/Controllers/   # API Controllers
│   ├── Services/          # Business logic
│   ├── Repositories/      # Data access layer
│   └── Models/            # Eloquent models
├── database/
│   ├── migrations/        # Database migrations
│   └── seeders/          # Database seeders
├── routes/
│   ├── api.php           # API routes (v1)
│   └── api_v1.php        # Version 1 routes
├── tests/                # PHPUnit tests
├── postman/              # Postman collection
└── docs/                 # Documentation

financeApp-supabase-version/  # Flutter mobile app
```

## Available Features

✅ User Authentication (Register, Login, Logout, Password Reset)
✅ Expense Management (CRUD operations)
✅ Income/Incoming Management
✅ Transfer Management
✅ Fund Box Tracking
✅ File Upload/Storage
✅ Data Export (PDF, Excel)
✅ Audit Logging
✅ Admin Dashboard
✅ User Profile Management
✅ Data Synchronization
✅ API Versioning
✅ OpenAPI/Swagger Documentation
✅ Postman Collection

## Next Steps

1. Review the API documentation at `/api/documentation`
2. Test endpoints using Postman collection
3. Check `SETUP_GUIDE.md` for detailed feature documentation
4. Review `API_ENDPOINTS_REFERENCE.md` for all available endpoints
5. Configure email settings in `.env` for notifications
6. Set up queue workers for background processing
7. Configure caching for better performance

## Support

For detailed documentation, check:
- `SETUP_GUIDE.md` - Comprehensive setup guide
- `API_ENDPOINTS_REFERENCE.md` - All API endpoints
- `docs/` folder - Additional documentation
- `postman/README.md` - Postman collection guide

## Production Deployment

Before deploying to production:
1. Set `APP_ENV=production` in `.env`
2. Set `APP_DEBUG=false`
3. Configure proper database credentials
4. Set up proper mail driver (SMTP)
5. Configure queue driver (Redis recommended)
6. Set up SSL certificate
7. Configure proper CORS settings
8. Run `php artisan config:cache`
9. Run `php artisan route:cache`
10. Run `php artisan view:cache`

Enjoy building with the Finance Backend API! 🚀
