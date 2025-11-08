<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote')->hourly();

/*
|--------------------------------------------------------------------------
| Scheduled Tasks
|--------------------------------------------------------------------------
|
| Here you may define all of your scheduled tasks. These tasks will be
| executed automatically by the Laravel scheduler.
|
*/

// Cleanup tasks - Run daily at 2 AM
Schedule::command('exports:cleanup')
    ->dailyAt('02:00')
    ->name('cleanup-old-exports')
    ->description('Clean up export files older than 24 hours');

Schedule::command('files:cleanup-temp')
    ->dailyAt('02:15')
    ->name('cleanup-temp-files')
    ->description('Clean up temporary files older than 24 hours');

Schedule::command('audit:cleanup --days=90')
    ->dailyAt('03:00')
    ->name('cleanup-old-audit-logs')
    ->description('Clean up audit logs older than 90 days');

// Maintenance tasks
Schedule::command('fundbox:recalculate')
    ->weekly()
    ->sundays()
    ->at('04:00')
    ->name('recalculate-fundbox')
    ->description('Recalculate fund box balance from all transactions');

// Queue maintenance
Schedule::command('queue:prune-batches')
    ->daily()
    ->name('prune-queue-batches')
    ->description('Prune stale entries from the batches database');

Schedule::command('queue:prune-failed')
    ->daily()
    ->name('prune-failed-jobs')
    ->description('Prune stale entries from the failed jobs database');

// Cache maintenance
Schedule::command('cache:prune-stale-tags')
    ->hourly()
    ->name('prune-cache-tags')
    ->description('Prune stale cache tags');
