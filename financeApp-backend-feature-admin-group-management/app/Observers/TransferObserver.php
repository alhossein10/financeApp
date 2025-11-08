<?php

namespace App\Observers;

use App\Models\Transfer;
use App\Services\AuditLogService;
use App\Services\CacheService;
use App\Services\FundBoxService;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class TransferObserver
{
    /**
     * Create a new TransferObserver instance.
     *
     * @param FundBoxService $fundBoxService
     * @param AuditLogService $auditLogService
     * @param CacheService $cacheService
     */
    public function __construct(
        protected FundBoxService $fundBoxService,
        protected AuditLogService $auditLogService,
        protected CacheService $cacheService
    ) {}

    /**
     * Handle the Transfer "created" event.
     *
     * @param Transfer $transfer
     * @return void
     */
    public function created(Transfer $transfer): void
    {
        try {
            // Subtract transfer amount from fund box for the user who created it
            $user = $transfer->user;
            if ($user) {
                $this->fundBoxService->adjustBalanceForUser($user, -$transfer->amount_usd);
            }
        } catch (\Exception $e) {
            Log::error('Failed to update fund box on transfer creation', [
                'transfer_id' => $transfer->id,
                'error' => $e->getMessage(),
            ]);
        }

        // Log the action
        $this->auditLogService->logAction(
            Auth::user(),
            'create',
            'Transfer',
            $transfer->id,
            [
                'recipient_name' => $transfer->recipient_name,
                'amount_usd' => $transfer->amount_usd,
                'transfer_date' => $transfer->transfer_date->format('Y-m-d'),
            ]
        );

        // Invalidate transfer-related caches
        $this->cacheService->invalidateTransferCache();
    }

    /**
     * Handle the Transfer "updated" event.
     *
     * @param Transfer $transfer
     * @return void
     */
    public function updated(Transfer $transfer): void
    {
        // Only adjust if amount changed
        if ($transfer->isDirty('amount_usd')) {
            try {
                $oldAmount = $transfer->getOriginal('amount_usd');
                $newAmount = $transfer->amount_usd;
                $difference = $oldAmount - $newAmount;
                
                // Adjust by the difference (positive if amount decreased, negative if increased)
                $user = $transfer->user;
                if ($user) {
                    $this->fundBoxService->adjustBalanceForUser($user, $difference);
                }
            } catch (\Exception $e) {
                Log::error('Failed to update fund box on transfer update', [
                    'transfer_id' => $transfer->id,
                    'error' => $e->getMessage(),
                ]);
            }
        }

        // Log the action
        $this->auditLogService->logAction(
            Auth::user(),
            'update',
            'Transfer',
            $transfer->id,
            [
                'changes' => $transfer->getChanges(),
                'original' => $transfer->getOriginal(),
            ]
        );

        // Invalidate transfer-related caches
        $this->cacheService->invalidateTransferCache();
    }

    /**
     * Handle the Transfer "deleted" event.
     *
     * @param Transfer $transfer
     * @return void
     */
    public function deleted(Transfer $transfer): void
    {
        try {
            // Add transfer amount back to fund box
            $user = $transfer->user;
            if ($user) {
                $this->fundBoxService->adjustBalanceForUser($user, $transfer->amount_usd);
            }
        } catch (\Exception $e) {
            Log::error('Failed to update fund box on transfer deletion', [
                'transfer_id' => $transfer->id,
                'error' => $e->getMessage(),
            ]);
        }

        // Log the action
        $this->auditLogService->logAction(
            Auth::user(),
            'delete',
            'Transfer',
            $transfer->id,
            [
                'recipient_name' => $transfer->recipient_name,
                'amount_usd' => $transfer->amount_usd,
            ]
        );

        // Invalidate transfer-related caches
        $this->cacheService->invalidateTransferCache();
    }

    /**
     * Handle the Transfer "restored" event.
     *
     * @param Transfer $transfer
     * @return void
     */
    public function restored(Transfer $transfer): void
    {
        try {
            // Subtract transfer amount from fund box again
            $user = $transfer->user;
            if ($user) {
                $this->fundBoxService->adjustBalanceForUser($user, -$transfer->amount_usd);
            }
        } catch (\Exception $e) {
            Log::error('Failed to update fund box on transfer restoration', [
                'transfer_id' => $transfer->id,
                'error' => $e->getMessage(),
            ]);
        }

        // Invalidate transfer-related caches
        $this->cacheService->invalidateTransferCache();
    }
}
