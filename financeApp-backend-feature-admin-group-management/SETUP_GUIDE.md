# Finance Management API - Setup Guide

Complete step-by-step guide to set up and run the Finance Management API.

## Prerequisites

Before you begin, ensure you have the following installed:

- **PHP 8.2 or higher**
  - Check version: `php -v`
  - Download: https://www.php.net/downloads

- **Composer** (PHP dependency manager)
  - Check version: `composer -V`
  - Download: https://getcomposer.org/download/

- **MySQL 8.0+** or **PostgreSQL**
  - MySQL: https://dev.mysql.com/downloads/
  - PostgreSQL: https://www.postgresql.org/download/

- **Node.js & NPM** (for asset compilation)
  - Check version: `node -v` and `npm -v`
  - Download: https://nodejs.org/

- **Git** (for version control)
  - Check version: `git --version`
  - Download: https://git-scm.com/downloads

## Installation Steps

### Step 1: Clone the Repository

```bash
git clone <repository-url>
cd finance-backend-api
```

### Step 2: Install PHP Dependencies

```bash
composer install
```

This will install all Laravel and PHP dependencies defined in `composer.json`.

### Step 3: Install Node Dependencies

```bash
npm install
```

This installs frontend dependencies for asset compilation.

### Step 4: Environment Configuration

#### Copy Environment File

```bash
# Windows
copy .env.example .env

# Linux/Mac
cp .env.example .env
```

#### Configure Environment Variables

Open `.env` in your text editor and configure the following:

**Application Settings**:
```env
APP_NAME="Finance Management API"
APP_ENV=local
APP_DEBUG=true
APP_URL=http://localhost:8000
```

**Database Settings** (MySQL example):
```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=finance_backend
DB_USERNAME=root
DB_PASSWORD=your_password_here
```

**Mail Settings** (for development, use log driver):
```env
MAIL_MAILER=log
MAIL_FROM_ADDRESS=noreply@financeapi.com
MAIL_FROM_NAME="${APP_NAME}"
```

For production, configure SMTP:
```env
MAIL_MAILER=smtp
MAIL_HOST=smtp.mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=your_username
MAIL_PASSWORD=your_password
MAIL_ENCRYPTION=tls
```

**Queue Settings**:
```env
QUEUE_CONNECTION=database
```

**Cache Settings**:
```env
CACHE_STORE=database
```

**Sanctum Settings**:
```env
SANCTUM_STATEFUL_DOMAINS=localhost,127.0.0.1
```

### Step 5: Generate Application Key

```bash
php artisan key:generate
```

This generates a unique encryption key for your application.

### Step 6: Create Database

Create a new database in MySQL:

```sql
CREATE DATABASE finance_backend CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

Or use your database management tool (phpMyAdmin, MySQL Workbench, etc.).

### Step 7: Run Database Migrations

```bash
php artisan migrate
```

This creates all necessary database tables.

### Step 8: Seed the Database (Optional)

For development and testing, seed the database with sample data:

```bash
php artisan db:seed --class=DevelopmentSeeder
```

This creates:
- **Admin user**: 
  - Email: `admin@example.com`
  - Password: `password`
  
- **Regular user**: 
  - Email: `user@example.com`
  - Password: `password`

- Sample expenses, transfers, and incoming transactions

### Step 9: Generate API Documentation

```bash
php artisan openapi:generate
```

This generates the OpenAPI specification for the API documentation.

### Step 10: Compile Assets (Optional)

```bash
npm run build
```

For development with hot reload:
```bash
npm run dev
```

### Step 11: Start the Development Server

```bash
php artisan serve
```

The API will be available at: `http://localhost:8000`

### Step 12: Start Queue Worker (Optional)

For background jobs (exports, emails), open a new terminal and run:

```bash
php artisan queue:work
```

Or on Windows, use the batch file:
```bash
run-queue-worker.bat
```

### Step 13: Start Task Scheduler (Optional)

For scheduled tasks (cleanup jobs), open a new terminal and run:

```bash
php artisan schedule:work
```

Or on Windows, use the batch file:
```bash
run-scheduler.bat
```

## Verification

### Test the API

1. **Check API Status**:
   ```bash
   curl http://localhost:8000/api
   ```

2. **View API Documentation**:
   Open in browser: `http://localhost:8000/api/documentation`

3. **Test Registration**:
   ```bash
   curl -X POST http://localhost:8000/api/v1/auth/register \
     -H "Content-Type: application/json" \
     -d '{
       "name": "Test User",
       "email": "test@example.com",
       "password": "password123",
       "password_confirmation": "password123"
     }'
   ```

4. **Test Login**:
   ```bash
   curl -X POST http://localhost:8000/api/v1/auth/login \
     -H "Content-Type: application/json" \
     -d '{
       "email": "user@example.com",
       "password": "password"
     }'
   ```

### Run Tests

```bash
php artisan test
```

All tests should pass.

## Common Issues and Solutions

### Issue: "Access denied for user"

**Solution**: Check your database credentials in `.env` file. Ensure the database user has proper permissions.

### Issue: "SQLSTATE[HY000] [2002] Connection refused"

**Solution**: Ensure MySQL/PostgreSQL is running. Check the database host and port in `.env`.

### Issue: "Class 'Composer\InstalledVersions' not found"

**Solution**: Run `composer dump-autoload` to regenerate the autoloader.

### Issue: "The stream or file could not be opened"

**Solution**: Set proper permissions for storage and cache directories:

```bash
# Linux/Mac
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

# Windows (run as administrator)
icacls storage /grant Users:F /t
icacls bootstrap\cache /grant Users:F /t
```

### Issue: "419 Page Expired" or CSRF Token Mismatch

**Solution**: For API requests, ensure you're using the correct authentication method (Bearer token) and not relying on session-based CSRF protection.

### Issue: Queue jobs not processing

**Solution**: Ensure the queue worker is running (`php artisan queue:work`). Check the `failed_jobs` table for failed jobs.

## Production Deployment

### Additional Steps for Production

1. **Set Environment to Production**:
   ```env
   APP_ENV=production
   APP_DEBUG=false
   ```

2. **Optimize Application**:
   ```bash
   composer install --optimize-autoloader --no-dev
   php artisan config:cache
   php artisan route:cache
   php artisan view:cache
   ```

3. **Set Up SSL/TLS**:
   Configure your web server (Apache/Nginx) with SSL certificate.

4. **Configure Queue Workers as System Service**:
   Set up Supervisor (Linux) or Windows Service to keep queue workers running.

5. **Set Up Cron Job for Scheduler**:
   ```bash
   * * * * * cd /path-to-your-project && php artisan schedule:run >> /dev/null 2>&1
   ```

6. **Configure Redis** (recommended for production):
   ```env
   CACHE_STORE=redis
   QUEUE_CONNECTION=redis
   SESSION_DRIVER=redis
   
   REDIS_HOST=127.0.0.1
   REDIS_PASSWORD=null
   REDIS_PORT=6379
   ```

7. **Set Up Database Backups**:
   Configure automated daily backups of your database.

8. **Configure Error Tracking**:
   Set up Sentry, Bugsnag, or similar service for error monitoring.

9. **Set Up Monitoring**:
   Configure uptime monitoring and performance tracking.

## Next Steps

- Read the [README.md](README.md) for complete documentation
- Check [API_ENDPOINTS_REFERENCE.md](API_ENDPOINTS_REFERENCE.md) for all available endpoints
- Review [API_DOCUMENTATION_QUICK_START.md](API_DOCUMENTATION_QUICK_START.md) for quick API usage
- See [docs/QUEUE_AND_SCHEDULER_SETUP.md](docs/QUEUE_AND_SCHEDULER_SETUP.md) for queue configuration
- Review [docs/API_VERSIONING_STRATEGY.md](docs/API_VERSIONING_STRATEGY.md) for versioning details

## Support

For issues or questions, please contact the development team or create an issue in the project repository.
