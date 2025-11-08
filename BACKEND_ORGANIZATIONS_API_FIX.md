# Backend Organizations API Fix

## Problem
The Flutter app is trying to fetch organizations from `/api/v1/organizations` but the endpoint is either:
1. Not accessible without authentication
2. Blocked by CORS
3. Not implemented yet

## Solution

### 1. Create Organizations API Routes (Laravel)

Add these routes to your `routes/api.php`:

```php
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\OrganizationController;

// Public routes (no authentication required for registration)
Route::prefix('v1')->group(function () {
    // Organizations - Public for registration
    Route::get('/organizations', [OrganizationController::class, 'index']);
    Route::get('/organizations/{id}/departments', [OrganizationController::class, 'departments']);
});
```

### 2. Create Organization Controller

Create `app/Http/Controllers/Api/OrganizationController.php`:

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Organization;
use Illuminate\Http\JsonResponse;

class OrganizationController extends Controller
{
    /**
     * Get all organizations
     * Public endpoint for registration
     */
    public function index(): JsonResponse
    {
        $organizations = Organization::select('id', 'name')
            ->orderBy('name')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $organizations
        ]);
    }

    /**
     * Get departments for a specific organization
     * Public endpoint for registration
     */
    public function departments(int $id): JsonResponse
    {
        $organization = Organization::findOrFail($id);
        
        $departments = $organization->departments()
            ->select('id', 'organization_id', 'name')
            ->orderBy('name')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $departments
        ]);
    }
}
```

### 3. Create Organization Model (if not exists)

Create `app/Models/Organization.php`:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Organization extends Model
{
    protected $fillable = [
        'name',
    ];

    /**
     * Get the departments for the organization
     */
    public function departments(): HasMany
    {
        return $this->hasMany(Department::class);
    }

    /**
     * Get the users for the organization
     */
    public function users(): HasMany
    {
        return $this->hasMany(User::class);
    }
}
```

### 4. Create Department Model (if not exists)

Create `app/Models/Department.php`:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Department extends Model
{
    protected $fillable = [
        'organization_id',
        'name',
    ];

    /**
     * Get the organization that owns the department
     */
    public function organization(): BelongsTo
    {
        return $this->belongsTo(Organization::class);
    }

    /**
     * Get the users for the department
     */
    public function users(): HasMany
    {
        return $this->hasMany(User::class);
    }
}
```

### 5. Create Database Migration

Create migration: `php artisan make:migration create_organizations_and_departments_tables`

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Create organizations table
        Schema::create('organizations', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->timestamps();
        });

        // Create departments table
        Schema::create('departments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->constrained()->onDelete('cascade');
            $table->string('name');
            $table->timestamps();
        });

        // Add organization_id and department_id to users table
        Schema::table('users', function (Blueprint $table) {
            $table->foreignId('organization_id')->nullable()->constrained()->onDelete('set null');
            $table->foreignId('department_id')->nullable()->constrained()->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['organization_id']);
            $table->dropForeign(['department_id']);
            $table->dropColumn(['organization_id', 'department_id']);
        });

        Schema::dropIfExists('departments');
        Schema::dropIfExists('organizations');
    }
};
```

### 6. Create Seeder for Initial Data

Create seeder: `php artisan make:seeder OrganizationSeeder`

```php
<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Organization;
use App\Models\Department;

class OrganizationSeeder extends Seeder
{
    public function run(): void
    {
        // Create default organization
        $org1 = Organization::create([
            'name' => 'هيئة الاتصالات',
        ]);

        // Create departments for organization 1
        Department::create([
            'organization_id' => $org1->id,
            'name' => 'إدارة المعلوماتية',
        ]);

        Department::create([
            'organization_id' => $org1->id,
            'name' => 'إدارة الموارد البشرية',
        ]);

        Department::create([
            'organization_id' => $org1->id,
            'name' => 'إدارة المالية',
        ]);

        // Add more organizations if needed
        $org2 = Organization::create([
            'name' => 'وزارة التعليم',
        ]);

        Department::create([
            'organization_id' => $org2->id,
            'name' => 'قسم التطوير',
        ]);
    }
}
```

### 7. Update CORS Configuration

Update `config/cors.php` to allow requests from your Flutter app:

```php
<?php

return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],
    'allowed_methods' => ['*'],
    'allowed_origins' => ['*'], // In production, specify your app's domain
    'allowed_origins_patterns' => [],
    'allowed_headers' => ['*'],
    'exposed_headers' => [],
    'max_age' => 0,
    'supports_credentials' => true,
];
```

### 8. Update User Registration to Include Organization

Update your `AuthController` register method:

```php
public function register(Request $request)
{
    $validated = $request->validate([
        'name' => 'required|string|max:255',
        'email' => 'required|string|email|max:255|unique:users',
        'password' => 'required|string|min:8',
        'organization_id' => 'required|exists:organizations,id',
        'department_id' => 'nullable|exists:departments,id',
        'role' => 'required|in:user,admin',
    ]);

    $user = User::create([
        'name' => $validated['name'],
        'email' => $validated['email'],
        'password' => Hash::make($validated['password']),
        'organization_id' => $validated['organization_id'],
        'department_id' => $validated['department_id'],
        'role' => $validated['role'],
    ]);

    $token = $user->createToken('auth_token')->plainTextToken;

    return response()->json([
        'success' => true,
        'data' => [
            'user' => $user,
            'token' => $token,
        ],
    ], 201);
}
```

### 9. Run Migrations and Seeders

```bash
# Run migrations
php artisan migrate

# Run seeder
php artisan db:seed --class=OrganizationSeeder

# Or add to DatabaseSeeder and run all seeders
php artisan db:seed
```

### 10. Test the Endpoints

Test with curl or Postman:

```bash
# Get organizations
curl http://192.168.137.1:8000/api/v1/organizations

# Get departments for organization 1
curl http://192.168.137.1:8000/api/v1/organizations/1/departments
```

Expected responses:

**Organizations:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "هيئة الاتصالات"
    },
    {
      "id": 2,
      "name": "وزارة التعليم"
    }
  ]
}
```

**Departments:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "organization_id": 1,
      "name": "إدارة المعلوماتية"
    },
    {
      "id": 2,
      "organization_id": 1,
      "name": "إدارة الموارد البشرية"
    }
  ]
}
```

## Verification

After implementing these changes:

1. Restart your Laravel server
2. Hot restart your Flutter app
3. Navigate to the registration page
4. The organizations dropdown should now show real data from your API
5. When you select an organization, departments should load automatically

## Notes

- These endpoints are public (no authentication required) to allow users to register
- In production, consider rate limiting these endpoints to prevent abuse
- The Flutter app has a fallback mechanism that shows "Default Organization" if the API fails
- Once the backend is fixed, the real organizations will load automatically
