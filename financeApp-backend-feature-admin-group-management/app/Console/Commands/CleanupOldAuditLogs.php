<?php

namespace App\Console\Commands;

use App\Models\AuditLog;
use Illuminate\Console\Command;
use Carbon\Carbon;

class CleanupOldAuditLogs extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'audit:cleanup {--days=90 : Number of days to retain audit logs}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Clean up audit logs older than specified days (default: 90 days)';

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $days = (int) $this->option('days');
        $cutoffDate = Carbon::now()->subDays($days);

        $this->info("Cleaning up audit logs older than {$days} days (before {$cutoffDate->toDateString()})...");

        $count = AuditLog::where('created_at', '<', $cutoffDate)->delete();

        $this->info("Deleted {$count} old audit log(s).");

        return Command::SUCCESS;
    }
}
