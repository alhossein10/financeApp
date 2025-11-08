<?php

namespace App\Console\Commands;

use App\Services\ExportService;
use Illuminate\Console\Command;

class CleanupOldExports extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'exports:cleanup';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Clean up expired export files (older than 24 hours)';

    protected ExportService $exportService;

    /**
     * Create a new command instance.
     */
    public function __construct(ExportService $exportService)
    {
        parent::__construct();
        $this->exportService = $exportService;
    }

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $this->info('Starting cleanup of old exports...');

        $count = $this->exportService->cleanupOldExports();

        $this->info("Cleaned up {$count} expired export(s).");

        return Command::SUCCESS;
    }
}
