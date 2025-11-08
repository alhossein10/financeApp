# Finance Management API

A comprehensive RESTful API backend for a dual-version Flutter finance management application. Built with Laravel 11, this API provides secure authentication, financial data management, file storage, and synchronization capabilities.

## Features

- **Authentication & Authorization**: Laravel Sanctum-based API token authentication with role-based access control (Admin/User)
- **Admin Group Management**: Create and manage user groups with unique invitation codes, organization-based access control
- **Expense Management**: Track expenses with multi-currency support (USD, SYP, TRY) and invoice attachments
- **Transfer Management**: Record money transfers with optional currency exchange information
- **Incoming Funds**: Track incoming money transactions
- **Fund Box**: Centralized balance management (Admin only)
- **Admin Dashboard**: Comprehensive statistics and analytics
- **Data Synchronization**: Batch sync with conflict resolution for mobile apps
- **File Storage**: Secure file upload/download with image compression
- **Data Export**: Generate PDF and Excel reports
- **Audit Logging**: Complete activity tracking for security and compliance
- **Email Notifications**: Automated notifications for key events
- **API Documentation**: OpenAPI 3.0 specification with Swagger UI

## Requirements

- PHP 8.2 or higher
- Composer
- MySQL 8.0+ or PostgreSQL
- Node.js & NPM (for asset compilation)
- Redis (optional, for caching and queues)

## Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd finance-backend-api
```

### 2. Install Dependencies

```bash
composer install
npm install
```

### 3. Environment Configuration

Copy the example environment file and configure your settings:

```bash
copy .env.example .env
```

Edit `.env` and configure the following:

```env
# Application
APP_NAME="Finance Management API"
APP_ENV=local
APP_DEBUG=true
APP_URL=http://localhost

# Database
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=finance_backend
DB_USERNAME=root
DB_PASSWORD=

# Mail Configuration
MAIL_MAILER=log
MAIL_FROM_ADDRESS=noreply@financeapi.com
MAIL_FROM_NAME="${APP_NAME}"

# Queue Configuration
QUEUE_CONNECTION=database

# Cache Configuration
CACHE_STORE=database

# Sanctum Configuration
SANCTUM_STATEFUL_DOMAINS=localhost,127.0.0.1
```

### 4. Generate Application Key

```bash
php artisan key:generate
```

### 5. Run Database Migrations

```bash
php artisan migrate
```

### 6. Seed the Database (Optional)

For development, seed the database with sample data:

```bash
php artisan db:seed --class=DevelopmentSeeder
```

This creates:
- Admin user: `admin@example.com` / `password`
- Regular user: `user@example.com` / `password`
- Sample expenses, transfers, and incoming transactions

### 7. Generate API Documentation

```bash
php artisan openapi:generate
```

### 8. Start the Development Server

```bash
php artisan serve
```

The API will be available at `http://localhost:8000`

### 9. Start Queue Worker (Optional)

For background jobs (exports, emails):

```bash
php artisan queue:work
```

Or on Windows:

```bash
run-queue-worker.bat
```

### 10. Start Task Scheduler (Optional)

For scheduled tasks (cleanup jobs):

```bash
php artisan schedule:work
```

Or on Windows:

```bash
run-scheduler.bat
```

## API Documentation

### Accessing Documentation

Once the server is running, access the API documentation at:

- **Swagger UI**: `http://localhost:8000/api/documentation`
- **OpenAPI JSON**: `http://localhost:8000/api/documentation` (returns JSON spec)
- **Quick Start Guide**: See [API_DOCUMENTATION_QUICK_START.md](API_DOCUMENTATION_QUICK_START.md)
- **Complete Documentation**: See [API_DOCUMENTATION_SUMMARY.md](API_DOCUMENTATION_SUMMARY.md)

### API Versioning

The API uses URL-based versioning:

- **Current Version**: v1
- **Base URL**: `http://localhost:8000/api/v1`
- **Supported Versions**: v1

All endpoints are prefixed with `/api/v1/`. For example:
- Authentication: `POST /api/v1/auth/login`
- Expenses: `GET /api/v1/expenses`

## Authentication

The API uses Laravel Sanctum for token-based authentication.

### Registration

```bash
POST /api/v1/auth/register
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "password_confirmation": "password123"
}
```

### Login

```bash
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}
```

Response:

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "role": "user"
    },
    "token": "1|abc123...",
    "token_type": "Bearer",
    "expires_in": 2592000
  }
}
```

### Using the Token

Include the token in the `Authorization` header for all authenticated requests:

```bash
GET /api/v1/expenses
Authorization: Bearer 1|abc123...
```

### Logout

```bash
POST /api/v1/auth/logout
Authorization: Bearer 1|abc123...
```

## Example API Calls

### Create an Expense

```bash
POST /api/v1/expenses
Authorization: Bearer 1|abc123...
Content-Type: application/json

{
  "description": "Office supplies",
  "price_usd": 50.00,
  "price_syp": 125000.00,
  "expense_date": "2025-10-22",
  "has_invoice": false
}
```

### Upload Invoice

```bash
POST /api/v1/expenses/1/invoice
Authorization: Bearer 1|abc123...
Content-Type: multipart/form-data

file: [binary file data]
```

### List Expenses

```bash
GET /api/v1/expenses?page=1&per_page=15&start_date=2025-10-01&end_date=2025-10-31
Authorization: Bearer 1|abc123...
```

### Create a Transfer

```bash
POST /api/v1/transfers
Authorization: Bearer 1|abc123...
Content-Type: application/json

{
  "recipient_name": "Jane Smith",
  "amount_usd": 100.00,
  "transfer_date": "2025-10-22",
  "notes": "Payment for services"
}
```

### Add Exchange to Transfer

```bash
POST /api/v1/transfers/1/exchange
Authorization: Bearer 1|abc123...
Content-Type: application/json

{
  "converted_amount_syp": 250000.00,
  "exchange_rate_usd_to_syp": 2500.00,
  "exchange_date": "2025-10-22"
}
```

### Export Expenses to PDF

```bash
POST /api/v1/export/expenses/pdf
Authorization: Bearer 1|abc123...
Content-Type: application/json

{
  "start_date": "2025-10-01",
  "end_date": "2025-10-31"
}
```

Response:

```json
{
  "success": true,
  "message": "Export queued successfully",
  "data": {
    "export_id": 1,
    "status": "processing"
  }
}
```

### Download Export

```bash
GET /api/v1/export/1/download
Authorization: Bearer 1|abc123...
```

## Rate Limiting

The API implements rate limiting to prevent abuse:

- **Public endpoints** (register, forgot password): 5 requests per minute
- **Login endpoint**: 5 requests per minute
- **Authenticated endpoints**: 60 requests per minute

When rate limit is exceeded, the API returns a `429 Too Many Requests` response with a `Retry-After` header.

## Error Handling

All errors follow a consistent JSON format:

```json
{
  "success": false,
  "message": "Human-readable error message",
  "errors": {
    "field_name": ["Validation error message"]
  },
  "error_code": "SPECIFIC_ERROR_CODE",
  "timestamp": "2025-10-22T10:30:00Z"
}
```

### HTTP Status Codes

- `200 OK` - Successful GET, PUT requests
- `201 Created` - Successful POST requests
- `204 No Content` - Successful DELETE requests
- `400 Bad Request` - Invalid request data
- `401 Unauthorized` - Missing or invalid authentication
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `409 Conflict` - Sync conflict detected
- `422 Unprocessable Entity` - Validation errors
- `429 Too Many Requests` - Rate limit exceeded
- `500 Internal Server Error` - Server errors

## Testing

### Run All Tests

```bash
php artisan test
```

### Run Specific Test Suite

```bash
php artisan test --testsuite=Feature
php artisan test --testsuite=Unit
```

### Run Specific Test File

```bash
php artisan test tests/Feature/Auth/LoginTest.php
```

### Run with Coverage

```bash
php artisan test --coverage
```

## Project Structure

```
app/
├── Console/           # Artisan commands
├── Exports/           # Excel export classes
├── Http/
│   ├── Controllers/   # API controllers
│   ├── Middleware/    # Custom middleware
│   └── Requests/      # Form request validators
├── Models/            # Eloquent models
├── Notifications/     # Email notifications
├── Observers/         # Model observers
├── Policies/          # Authorization policies
├── Repositories/      # Data access layer
└── Services/          # Business logic layer

config/                # Configuration files
database/
├── factories/         # Model factories
├── migrations/        # Database migrations
└── seeders/           # Database seeders

routes/
├── api.php            # Main API routes
└── api_v1.php         # Version 1 routes

tests/
├── Feature/           # Feature tests
└── Unit/              # Unit tests
```

## Security

### Best Practices

- All passwords are hashed using bcrypt
- API tokens expire after 30 days
- Rate limiting prevents brute force attacks
- File uploads are validated and sanitized
- SQL injection prevention via Eloquent ORM
- XSS prevention via output escaping
- CSRF protection for state-changing operations
- Audit logging for all critical operations

### Sensitive Operations

Operations like password changes and account deletion require recent authentication (within 15 minutes). Users must re-authenticate before performing these actions.

## Deployment

### Production Checklist

1. Set `APP_ENV=production` and `APP_DEBUG=false` in `.env`
2. Configure production database credentials
3. Set up proper mail driver (SMTP, Mailgun, etc.)
4. Configure Redis for cache and queue
5. Set up SSL/TLS certificate
6. Configure CORS for your Flutter app domains
7. Set up queue workers as system services
8. Configure task scheduler (cron job)
9. Set up database backups
10. Configure error tracking (Sentry, Bugsnag)
11. Set up monitoring and logging

### Optimization

```bash
# Cache configuration
php artisan config:cache

# Cache routes
php artisan route:cache

# Cache views
php artisan view:cache

# Optimize autoloader
composer install --optimize-autoloader --no-dev
```

## Additional Documentation

- [API Documentation Quick Start](API_DOCUMENTATION_QUICK_START.md)
- [API Documentation Summary](API_DOCUMENTATION_SUMMARY.md)
- [Password Reset API](docs/PASSWORD_RESET_API.md)
- [Queue and Scheduler Setup](docs/QUEUE_AND_SCHEDULER_SETUP.md)
- [API Versioning Strategy](docs/API_VERSIONING_STRATEGY.md)

## Support

For issues, questions, or contributions, please contact the development team.

## License

This project is proprietary software. All rights reserved.
