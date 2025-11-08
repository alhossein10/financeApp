<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

// API Documentation UI
Route::get('/api/documentation', function () {
    $jsonPath = storage_path('api-docs/api-docs.json');
    
    if (!file_exists($jsonPath)) {
        return response()->view('api-docs-missing');
    }
    
    return view('api-documentation');
})->name('api.documentation.ui');
