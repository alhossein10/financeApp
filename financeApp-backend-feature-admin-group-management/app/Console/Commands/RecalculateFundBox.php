<?php

namespace App\Console\Commands;

use App\Services\FundBoxService;
use Illuminate\Console\Command;

class RecalculateFundBox extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'fundbox:recalculate';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Recalculate fund box balance from all transactions';

    protected FundBoxService $fundBoxService;

    /**
     * Create a new command instance.
     */
    public function __construct(FundBoxService $fundBoxService)
    {
        parent::__construct();
        $this->fundBoxService = $fundBoxService;
    }

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $this->info('Recalculating fund box balance...');

        $fundBox = $this->fundBoxService->recalculateBalance();

        $this->info("Fund box balance recalculated: $" . number_format($fundBox->balance_usd, 2));
        $this->info("Last calculated at: {$fundBox->last_calculated_at}");

        return Command::SUCCESS;
    }
}
