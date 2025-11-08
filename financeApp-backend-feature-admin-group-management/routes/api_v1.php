<?php

use App\Http\Controllers\AdminDashboardController;
use App\Http\Controllers\AdminGroupController;
use App\Http\Controllers\AuditLogController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ExpenseController;
use App\Http\Controllers\ExportController;
use App\Http\Controllers\FileController;
use App\Http\Controllers\FundBoxController;
use App\Http\Controllers\IncomingController;
use App\Http\Controllers\SyncController;
use App\Http\Controllers\TransferController;
use App\Http\Controllers\UserProfileController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Version 1 Routes
|--------------------------------------------------------------------------
|
| These routes are for API version 1 and are prefixed with /api/v1/
| All routes are loaded with the 'api' middleware group.
|
| Middleware Applied:
| - throttle:public (5 requests/min for public endpoints)
| - throttle:login (5 requests/min for login endpoint)
| - throttle:api (60 requests/min for authenticated endpoints)
| - auth:sanctum (requires valid Sanctum token)
| - admin (requires admin role)
| - validate.file (validates file uploads)
| - recent.auth (requires recent authentication within 15 minutes)
|
*/

/*
|--------------------------------------------------------------------------
| Public Authentication Routes
|--------------------------------------------------------------------------
|
| These routes are publicly accessible and handle user registration,
| login, and password reset functionality. Rate limiting is applied
| to prevent abuse.
|
*/
Route::prefix('auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register'])
        ->middleware('throttle:public')
        ->name('auth.register');
    
    Route::post('/login', [AuthController::class, 'login'])
        ->middleware('throttle:login')
        ->name('auth.login');
    
    Route::post('/forgot-password', [AuthController::class, 'forgotPassword'])
        ->middleware('throttle:public')
        ->name('auth.forgot-password');
    
    Route::post('/reset-password', [AuthController::class, 'resetPassword'])
        ->middleware('throttle:public')
        ->name('auth.reset-password');
});

/*
|--------------------------------------------------------------------------
| Public Organization Routes
|--------------------------------------------------------------------------
|
| These routes provide access to organizational structure data needed
| for user registration. No authentication required.
|
*/
Route::prefix('organizations')->group(function () {
    Route::get('/', [\App\Http\Controllers\OrganizationController::class, 'index'])
        ->middleware('throttle:public')
        ->name('organizations.index');
    
    Route::get('/{id}/departments', [\App\Http\Controllers\OrganizationController::class, 'departments'])
        ->middleware('throttle:public')
        ->name('organizations.departments');
});

/*
|--------------------------------------------------------------------------
| Protected Routes
|--------------------------------------------------------------------------
|
| All routes below require authentication via Laravel Sanctum.
| Rate limiting of 60 requests per minute is applied to all authenticated
| endpoints. Additional middleware may be applied to specific route groups.
|
*/
Route::middleware(['auth:sanctum', 'throttle:api'])->group(function () {
    
    /*
    |--------------------------------------------------------------------------
    | Protected Authentication Routes
    |--------------------------------------------------------------------------
    */
    Route::prefix('auth')->group(function () {
        Route::post('/logout', [AuthController::class, 'logout'])
            ->name('auth.logout');
        
        Route::post('/refresh', [AuthController::class, 'refresh'])
            ->name('auth.refresh');
        
        Route::get('/me', [AuthController::class, 'me'])
            ->name('auth.me');
    });

    /*
    |--------------------------------------------------------------------------
    | Expense Management Routes
    |--------------------------------------------------------------------------
    |
    | CRUD operations for expense records. Users can only access their own
    | expenses, while admins can access all expenses.
    |
    */
    Route::apiResource('expenses', ExpenseController::class);
    
    // Invoice management sub-routes
    Route::prefix('expenses/{expense}')->group(function () {
        Route::post('/invoice', [ExpenseController::class, 'uploadInvoice'])
            ->middleware('validate.file')
            ->name('expenses.invoice.upload');
        
        Route::get('/invoice', [ExpenseController::class, 'downloadInvoice'])
            ->name('expenses.invoice.download');
        
        Route::delete('/invoice', [ExpenseController::class, 'deleteInvoice'])
            ->name('expenses.invoice.delete');
    });
    
    /*
    |--------------------------------------------------------------------------
    | Transfer Management Routes
    |--------------------------------------------------------------------------
    |
    | CRUD operations for transfer records with optional currency exchange
    | information. Users can only access their own transfers.
    |
    */
    Route::apiResource('transfers', TransferController::class);
    
    // Exchange management sub-route
    Route::post('transfers/{transfer}/exchange', [TransferController::class, 'addExchange'])
        ->name('transfers.exchange.store');
    
    /*
    |--------------------------------------------------------------------------
    | Incoming Funds Management Routes
    |--------------------------------------------------------------------------
    |
    | CRUD operations for incoming transaction records. Users can only
    | access their own incoming transactions.
    |
    */
    Route::apiResource('incoming', IncomingController::class);
    
    /*
    |--------------------------------------------------------------------------
    | Fund Box Management Routes (Admin Only)
    |--------------------------------------------------------------------------
    |
    | View and manage the central fund box balance. Only accessible to
    | admin users.
    |
    */
    Route::middleware('admin')->prefix('fund-box')->group(function () {
        Route::get('/', [FundBoxController::class, 'show'])
            ->name('fund-box.show');
        
        Route::put('/', [FundBoxController::class, 'update'])
            ->name('fund-box.update');
    });
    
    /*
    |--------------------------------------------------------------------------
    | Admin Group Management Routes (Admin Only)
    |--------------------------------------------------------------------------
    |
    | Manage admin groups, group codes, and group members. Admins can view
    | their group information, regenerate group codes, and manage members.
    | All routes require admin role.
    |
    */
    Route::middleware('admin')->prefix('admin/group')->group(function () {
        Route::get('/', [AdminGroupController::class, 'getAdminGroup'])
            ->name('admin.group.show');
        
        Route::post('/regenerate', [AdminGroupController::class, 'regenerateGroupCode'])
            ->name('admin.group.regenerate');
        
        Route::get('/members', [AdminGroupController::class, 'getGroupMembers'])
            ->name('admin.group.members.index');
        
        Route::delete('/members/{id}', [AdminGroupController::class, 'removeMember'])
            ->name('admin.group.members.destroy');
    });
    
    /*
    |--------------------------------------------------------------------------
    | Admin Dashboard Routes (Admin Only)
    |--------------------------------------------------------------------------
    |
    | Comprehensive statistics and analytics for system administrators.
    | All routes require admin role.
    |
    */
    Route::middleware('admin')->prefix('admin/dashboard')->group(function () {
        Route::get('/stats', [AdminDashboardController::class, 'stats'])
            ->name('admin.dashboard.stats');
        
        Route::get('/users', [AdminDashboardController::class, 'users'])
            ->name('admin.dashboard.users');
        
        Route::get('/expenses', [AdminDashboardController::class, 'expenses'])
            ->name('admin.dashboard.expenses');
        
        Route::get('/analytics', [AdminDashboardController::class, 'analytics'])
            ->name('admin.dashboard.analytics');
    });
    
    /*
    |--------------------------------------------------------------------------
    | Audit Log Routes (Admin Only)
    |--------------------------------------------------------------------------
    |
    | View audit logs of all system activities. Only accessible to admin users.
    |
    */
    Route::middleware('admin')->prefix('audit-logs')->group(function () {
        Route::get('/', [AuditLogController::class, 'index'])
            ->name('audit-logs.index');
        
        Route::get('/{id}', [AuditLogController::class, 'show'])
            ->name('audit-logs.show');
    });
    
    /*
    |--------------------------------------------------------------------------
    | Data Synchronization Routes
    |--------------------------------------------------------------------------
    |
    | Handle batch synchronization, change tracking, and conflict resolution
    | for mobile app data sync.
    |
    */
    Route::prefix('sync')->group(function () {
        Route::post('/batch', [SyncController::class, 'batchSync'])
            ->name('sync.batch');
        
        Route::get('/changes', [SyncController::class, 'getChanges'])
            ->name('sync.changes');
        
        Route::post('/resolve', [SyncController::class, 'resolveConflict'])
            ->name('sync.resolve');
    });
    
    /*
    |--------------------------------------------------------------------------
    | User Group Management Routes
    |--------------------------------------------------------------------------
    |
    | Allow regular users to join admin groups using group codes and view
    | their current group information.
    |
    */
    Route::prefix('user')->group(function () {
        Route::post('/join-group', [AdminGroupController::class, 'joinGroup'])
            ->name('user.group.join');
        
        Route::get('/group-info', [AdminGroupController::class, 'getGroupInfo'])
            ->name('user.group.info');
    });
    
    /*
    |--------------------------------------------------------------------------
    | User Profile Management Routes
    |--------------------------------------------------------------------------
    |
    | Manage user profile information, password changes, and account deletion.
    | Sensitive operations require recent authentication.
    |
    */
    Route::prefix('profile')->group(function () {
        Route::get('/', [UserProfileController::class, 'show'])
            ->name('profile.show');
        
        Route::put('/', [UserProfileController::class, 'update'])
            ->name('profile.update');
        
        Route::put('/password', [UserProfileController::class, 'changePassword'])
            ->middleware('recent.auth')
            ->name('profile.password');
        
        Route::delete('/', [UserProfileController::class, 'destroy'])
            ->middleware('recent.auth')
            ->name('profile.destroy');
    });
    
    /*
    |--------------------------------------------------------------------------
    | Data Export Routes
    |--------------------------------------------------------------------------
    |
    | Generate and download data exports in various formats (PDF, Excel).
    | System-wide exports are admin-only.
    |
    */
    Route::prefix('export')->group(function () {
        Route::get('/', [ExportController::class, 'index'])
            ->name('export.index');
        
        Route::post('/expenses/pdf', [ExportController::class, 'exportExpensesToPdf'])
            ->name('export.expenses.pdf');
        
        Route::post('/expenses/excel', [ExportController::class, 'exportExpensesToExcel'])
            ->name('export.expenses.excel');
        
        Route::post('/system-wide', [ExportController::class, 'exportSystemWide'])
            ->middleware('admin')
            ->name('export.system-wide');
        
        Route::get('/{id}/status', [ExportController::class, 'status'])
            ->name('export.status');
        
        Route::get('/{id}/download', [ExportController::class, 'download'])
            ->name('export.download');
    });
    
    /*
    |--------------------------------------------------------------------------
    | Generic File Operations
    |--------------------------------------------------------------------------
    |
    | Upload and delete files. File validation middleware is applied to uploads.
    |
    */
    Route::prefix('files')->group(function () {
        Route::post('/upload', [FileController::class, 'upload'])
            ->middleware('validate.file')
            ->name('files.upload');
        
        Route::delete('/', [FileController::class, 'delete'])
            ->name('files.delete');
    });
});

/*
|--------------------------------------------------------------------------
| Public File Download Route
|--------------------------------------------------------------------------
|
| Download files using encrypted path. This route is outside the auth
| middleware to allow temporary signed URLs.
|
*/
Route::get('files/download', [FileController::class, 'download'])
    ->name('files.download');
