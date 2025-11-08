<?php

namespace App\Providers;

use App\Models\Expense;
use App\Models\Incoming;
use App\Models\Transfer;
use App\Models\User;
use App\Observers\ExpenseObserver;
use App\Observers\IncomingObserver;
use App\Observers\TransferObserver;
use App\Observers\UserObserver;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Register model observers
        Expense::observe(ExpenseObserver::class);
        Transfer::observe(TransferObserver::class);
        Incoming::observe(IncomingObserver::class);
        User::observe(UserObserver::class);
        
        // Configure rate limiters
        $this->configureRateLimiting();
    }
    
    /**
     * Configure the rate limiters for the application.
     */
    protected function configureRateLimiting(): void
    {
        // Default API rate limiter - 60 requests per minute for authenticated users
        RateLimiter::for('api', function (Request $request) {
            return $request->user()
                ? Limit::perMinute(1000)->by($request->user()->id)
                : Limit::perMinute(10)->by($request->ip());
        });
        
        // Login endpoint rate limiter - 5 requests per minute
        RateLimiter::for('login', function (Request $request) {
            return Limit::perMinute(5)->by($request->ip());
        });
        
        // Public endpoints rate limiter - IP-based
        RateLimiter::for('public', function (Request $request) {
            return Limit::perMinute(20)->by($request->ip());
        });
    }
}
