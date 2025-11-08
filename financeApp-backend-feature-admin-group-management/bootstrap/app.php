<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Support\Facades\Route;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
        then: function () {
            // Load versioned API routes
            Route::prefix('api/v1')
                ->middleware('api')
                ->group(base_path('routes/api_v1.php'));
        },
    )
    ->withMiddleware(function (Middleware $middleware) {
        $middleware->alias([
            'auth.api' => \App\Http\Middleware\EnsureUserIsAuthenticated::class,
            'admin' => \App\Http\Middleware\EnsureUserIsAdmin::class,
            'recent.auth' => \App\Http\Middleware\RequireRecentAuthentication::class,
            'validate.file' => \App\Http\Middleware\ValidateFileUpload::class,
            'api.version' => \App\Http\Middleware\ApiVersionNegotiation::class,
        ]);
        
        // Add security headers and version negotiation to API routes
        $middleware->api(append: [
            \App\Http\Middleware\AddSecurityHeaders::class,
            \App\Http\Middleware\ApiVersionNegotiation::class,
        ]);
        
        // Configure rate limiting
        $middleware->throttleApi();
    })
    ->withExceptions(function (Exceptions $exceptions) {
        //
    })->create();
