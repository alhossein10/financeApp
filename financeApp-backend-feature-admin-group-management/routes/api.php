<?php

use App\Http\Controllers\AdminDashboardController;
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
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
| Note: Versioned routes are loaded in bootstrap/app.php
| - API v1: routes/api_v1.php (prefix: /api/v1/)
|
*/

// API version information endpoint
Route::get('/', function () {
    return response()->json([
        'name' => 'Finance Management API',
        'current_version' => 'v1',
        'supported_versions' => ['v1'],
        'documentation' => url('/api/documentation'),
        'endpoints' => [
            'v1' => url('/api/v1'),
        ],
    ]);
});

// Legacy endpoint for backward compatibility (will be removed in future versions)
Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

// API Documentation route
Route::get('/documentation', function () {
    $jsonPath = storage_path('api-docs/api-docs.json');
    
    if (!file_exists($jsonPath)) {
        return response()->json([
            'error' => 'API documentation not generated. Run: php artisan openapi:generate'
        ], 404);
    }
    
    $spec = json_decode(file_get_contents($jsonPath), true);
    
    return response()->json($spec);
})->name('api.documentation');
