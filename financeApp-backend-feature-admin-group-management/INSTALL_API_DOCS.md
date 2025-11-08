# API Documentation Installation Instructions

## Step 1: Install L5-Swagger Package

The L5-Swagger package has been added to `composer.json`. To install it, run:

```bash
composer update darkaonline/l5-swagger
```

Or install all dependencies:

```bash
composer install
```

## Step 2: Publish L5-Swagger Assets (Optional)

If you want to customize the Swagger UI views:

```bash
php artisan vendor:publish --provider="L5Swagger\L5SwaggerServiceProvider"
```

This will publish:
- Configuration file (already created manually at `config/l5-swagger.php`)
- Views to `resources/views/vendor/l5-swagger`

## Step 3: Create Storage Directory

Ensure the storage directory for API docs exists and is writable:

```bash
mkdir -p storage/api-docs
chmod -R 775 storage/api-docs
```

On Windows:
```cmd
mkdir storage\api-docs
```

## Step 4: Generate API Documentation

Generate the OpenAPI specification:

```bash
php artisan l5-swagger:generate
```

This will create `storage/api-docs/api-docs.json` with the complete API specification.

## Step 5: Update Environment Variables

Add these to your `.env` file (already in `.env.example`):

```env
L5_SWAGGER_GENERATE_ALWAYS=true
L5_SWAGGER_CONST_HOST=http://localhost:8000/api/v1
L5_SWAGGER_USE_ABSOLUTE_PATH=true
L5_SWAGGER_OPERATIONS_SORT=alpha
L5_SWAGGER_UI_DOC_EXPANSION=list
L5_SWAGGER_UI_FILTERS=true
L5_SWAGGER_UI_PERSIST_AUTHORIZATION=true
```

## Step 6: Access Documentation

Start your Laravel development server:

```bash
php artisan serve
```

Then access the Swagger UI at:

```
http://localhost:8000/api/documentation
```

## Verification

To verify the installation:

1. Check that the package is installed:
   ```bash
   composer show darkaonline/l5-swagger
   ```

2. Check that the artisan command is available:
   ```bash
   php artisan list | grep l5-swagger
   ```

   You should see:
   - `l5-swagger:generate` - Generate API documentation
   - `l5-swagger:publish` - Publish config and views

3. Generate documentation:
   ```bash
   php artisan l5-swagger:generate
   ```

4. Check that the JSON file was created:
   ```bash
   ls -la storage/api-docs/api-docs.json
   ```

## Troubleshooting

### Package Not Found

If you get "Package not found" error:

```bash
composer clear-cache
composer update
```

### Permission Denied

If you get permission errors on the storage directory:

```bash
chmod -R 775 storage
chown -R www-data:www-data storage  # Linux/Mac
```

### Class Not Found

If you get "Class L5Swagger\Generator not found":

1. Clear config cache:
   ```bash
   php artisan config:clear
   ```

2. Regenerate autoload files:
   ```bash
   composer dump-autoload
   ```

3. Verify the package is installed:
   ```bash
   composer show darkaonline/l5-swagger
   ```

## What's Already Configured

The following files have been created/configured:

1. **composer.json** - Package dependency added
2. **config/l5-swagger.php** - Complete L5-Swagger configuration
3. **app/Http/Controllers/Controller.php** - Base OpenAPI annotations
4. **app/Http/Controllers/Schemas/OpenApiSchemas.php** - Common schema definitions
5. **.env.example** - Environment variable examples
6. **README_API_DOCUMENTATION.md** - Complete documentation guide

The following controllers have OpenAPI annotations:

- ✅ AuthController - All authentication endpoints
- ✅ ExpenseController - Expense management (index method documented)
- ✅ TransferController - Transfer management (index method documented)
- ✅ IncomingController - Incoming funds (index method documented)
- ✅ FundBoxController - Fund box management (all methods documented)
- ✅ AdminDashboardController - Admin dashboard (stats method documented)
- ✅ SyncController - Data synchronization (batchSync documented)
- ✅ UserProfileController - User profile (show method documented)
- ✅ ExportController - Data export (exportExpensesToPdf documented)
- ✅ AuditLogController - Audit logs (index method documented)
- ✅ FileController - File management (upload method documented)

## Next Steps

After installation, you can:

1. Add more detailed annotations to remaining controller methods
2. Customize the Swagger UI theme
3. Add example requests/responses
4. Configure authentication flows
5. Add API versioning documentation

Refer to `README_API_DOCUMENTATION.md` for detailed usage instructions.
