<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;
use Carbon\Carbon;

class CleanupTemporaryFiles extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'files:cleanup-temp';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Clean up temporary files older than 24 hours';

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $this->info('Starting cleanup of temporary files...');

        $count = 0;
        $tempDirectories = ['temp', 'tmp', 'uploads/temp'];

        foreach ($tempDirectories as $directory) {
            if (!Storage::exists($directory)) {
                continue;
            }

            $files = Storage::files($directory);
            
            foreach ($files as $file) {
                $lastModified = Storage::lastModified($file);
                $fileAge = Carbon::createFromTimestamp($lastModified);

                // Delete files older than 24 hours
                if ($fileAge->diffInHours(now()) > 24) {
                    Storage::delete($file);
                    $count++;
                    $this->line("Deleted: {$file}");
                }
            }
        }

        $this->info("Cleaned up {$count} temporary file(s).");

        return Command::SUCCESS;
    }
}
