# API Documentation Setup

This document describes the OpenAPI/Swagger documentation setup for the Finance Backend API.

## Overview

The API documentation is generated using L5-Swagger (darkaonline/l5-swagger) package, which provides OpenAPI 3.0 specification and Swagger UI interface.

## Configuration

### Environment Variables

Add these to your `.env` file:

```env
L5_SWAGGER_GENERATE_ALWAYS=true
L5_SWAGGER_CONST_HOST=http://localhost:8000/api/v1
L5_SWAGGER_USE_ABSOLUTE_PATH=true
L5_SWAGGER_OPERATIONS_SORT=alpha
L5_SWAGGER_UI_DOC_EXPANSION=list
L5_SWAGGER_UI_FILTERS=true
L5_SWAGGER_UI_PERSIST_AUTHORIZATION=true
```

### Configuration File

The L5-Swagger configuration is located at `config/l5-swagger.php`. Key settings:

- **Documentation Route**: `/api/documentation`
- **API Docs JSON**: `storage/api-docs/api-docs.json`
- **Annotations Path**: `app/` directory
- **Security**: Laravel Sanctum bearer token authentication

## Generating Documentation

### Manual Generation

To manually generate the API documentation:

```bash
php artisan l5-swagger:generate
```

### Automatic Generation

When `L5_SWAGGER_GENERATE_ALWAYS=true` in your `.env`, documentation is regenerated on each request (recommended for development only).

For production, set `L5_SWAGGER_GENERATE_ALWAYS=false` and generate documentation during deployment.

## Accessing Documentation

Once generated, access the Swagger UI at:

```
http://localhost:8000/api/documentation
```

## Documentation Structure

### Base Configuration

The base OpenAPI configuration is in `app/Http/Controllers/Controller.php`:
- API version and description
- Server configuration
- Security schemes (Sanctum)
- API tags

### Schema Definitions

Common schemas are defined in `app/Http/Controllers/Schemas/OpenApiSchemas.php`:
- User
- Expense
- Transfer
- Exchange
- Incoming
- FundBox
- AuditLog
- PaginationMeta
- ErrorResponse
- SuccessResponse

### Endpoint Documentation

Each controller contains OpenAPI annotations for its endpoints:

#### Authentication (`AuthController`)
- POST `/auth/register` - Register new user
- POST `/auth/login` - Login user
- POST `/auth/logout` - Logout user
- POST `/auth/refresh` - Refresh token
- POST `/auth/forgot-password` - Send password reset link
- POST `/auth/reset-password` - Reset password
- GET `/auth/me` - Get authenticated user

#### Expenses (`ExpenseController`)
- GET `/expenses` - List expenses (with filters)
- POST `/expenses` - Create expense
- GET `/expenses/{id}` - Get expense
- PUT `/expenses/{id}` - Update expense
- DELETE `/expenses/{id}` - Delete expense
- POST `/expenses/{id}/invoice` - Upload invoice
- GET `/expenses/{id}/invoice` - Download invoice
- DELETE `/expenses/{id}/invoice` - Delete invoice

#### Transfers (`TransferController`)
- GET `/transfers` - List transfers
- POST `/transfers` - Create transfer
- GET `/transfers/{id}` - Get transfer
- PUT `/transfers/{id}` - Update transfer
- DELETE `/transfers/{id}` - Delete transfer
- POST `/transfers/{id}/exchange` - Add exchange data

#### Incoming (`IncomingController`)
- GET `/incoming` - List incoming funds
- POST `/incoming` - Create incoming
- GET `/incoming/{id}` - Get incoming
- PUT `/incoming/{id}` - Update incoming
- DELETE `/incoming/{id}` - Delete incoming

#### Fund Box (`FundBoxController`) - Admin Only
- GET `/fund-box` - Get fund box balance
- PUT `/fund-box` - Update fund box balance

#### Admin Dashboard (`AdminDashboardController`) - Admin Only
- GET `/admin/dashboard/stats` - Get overall statistics
- GET `/admin/dashboard/users` - Get user activity list
- GET `/admin/dashboard/expenses` - Get expense summaries
- GET `/admin/dashboard/analytics` - Get analytics

#### Files (`FileController`)
- POST `/files/upload` - Upload file
- GET `/files/{id}` - Download file
- DELETE `/files/{id}` - Delete file

#### Sync (`SyncController`)
- POST `/sync/batch` - Batch sync records
- GET `/sync/changes` - Get changes since timestamp
- POST `/sync/resolve` - Resolve sync conflicts

#### User Profile (`UserProfileController`)
- GET `/profile` - Get user profile
- PUT `/profile` - Update profile
- PUT `/profile/password` - Change password
- DELETE `/profile` - Delete account

#### Export (`ExportController`)
- POST `/export/expenses/pdf` - Export expenses to PDF
- POST `/export/expenses/excel` - Export expenses to Excel
- GET `/export/{id}/download` - Download export

#### Audit Logs (`AuditLogController`) - Admin Only
- GET `/audit-logs` - List audit logs
- GET `/audit-logs/{id}` - Get audit log

## Authentication in Swagger UI

To test authenticated endpoints in Swagger UI:

1. First, use the `/auth/login` or `/auth/register` endpoint to get a token
2. Copy the token from the response
3. Click the "Authorize" button at the top of the Swagger UI
4. Enter the token in the format: `Bearer YOUR_TOKEN_HERE`
5. Click "Authorize"
6. Now you can test all authenticated endpoints

## Adding New Endpoints

When adding new endpoints, follow these steps:

1. Add OpenAPI annotations to the controller method using PHPDoc comments
2. Use the `@OA\` annotations for OpenAPI specification
3. Include:
   - Path and HTTP method
   - Tags for grouping
   - Summary and description
   - Security requirements (if authenticated)
   - Request body schema (for POST/PUT)
   - Response schemas for all status codes
   - Parameters (query, path, header)

Example:

```php
/**
 * @OA\Get(
 *     path="/example",
 *     tags={"Example"},
 *     summary="Example endpoint",
 *     description="Detailed description",
 *     security={{"sanctum":{}}},
 *     @OA\Parameter(
 *         name="param",
 *         in="query",
 *         required=false,
 *         @OA\Schema(type="string")
 *     ),
 *     @OA\Response(
 *         response=200,
 *         description="Success",
 *         @OA\JsonContent(ref="#/components/schemas/SuccessResponse")
 *     )
 * )
 */
public function example(Request $request): JsonResponse
{
    // Implementation
}
```

4. Regenerate documentation: `php artisan l5-swagger:generate`

## Troubleshooting

### Documentation Not Generating

1. Check that annotations are properly formatted
2. Ensure the `storage/api-docs` directory is writable
3. Clear cache: `php artisan cache:clear`
4. Regenerate: `php artisan l5-swagger:generate`

### Swagger UI Not Loading

1. Check that the route is accessible: `/api/documentation`
2. Verify `config/l5-swagger.php` is properly configured
3. Check browser console for JavaScript errors

### Authentication Not Working

1. Ensure you're using the correct format: `Bearer TOKEN`
2. Verify the token is valid and not expired
3. Check that the endpoint has `security={{"sanctum":{}}}` annotation

## Production Deployment

For production:

1. Set `L5_SWAGGER_GENERATE_ALWAYS=false` in `.env`
2. Generate documentation during deployment: `php artisan l5-swagger:generate`
3. Consider restricting access to `/api/documentation` route
4. Update `L5_SWAGGER_CONST_HOST` to your production URL

## References

- [L5-Swagger Documentation](https://github.com/DarkaOnLine/L5-Swagger)
- [OpenAPI 3.0 Specification](https://swagger.io/specification/)
- [Swagger UI](https://swagger.io/tools/swagger-ui/)
