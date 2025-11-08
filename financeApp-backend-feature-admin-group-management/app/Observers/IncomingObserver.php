<?php

namespace App\Observers;

use App\Models\Incoming;
use App\Services\AuditLogService;
use App\Services\CacheService;
use App\Services\FundBoxService;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class IncomingObserver
{
    /**
     * Create a new IncomingObserver instance.
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
     * Handle the Incoming "created" event.
     *
     * @param Incoming $incoming
     * @return void
     */
    public function created(Incoming $incoming): void
    {
        try {
            // Add incoming amount to fund box for the user who created it
            $user = $incoming->user;
            if ($user) {
                $this->fundBoxService->adjustBalanceForUser($user, $incoming->amount_usd);
            }
        } catch (\Exception $e) {
            Log::error('Failed to update fund box on incoming creation', [
                'incoming_id' => $incoming->id,
                'error' => $e->getMessage(),
            ]);
        }

        // Log the action
        $this->auditLogService->logAction(
            Auth::user(),
            'create',
            'Incoming',
            $incoming->id,
            [
                'description' => $incoming->description,
                'amount_usd' => $incoming->amount_usd,
                'incoming_date' => $incoming->incoming_date->format('Y-m-d'),
            ]
        );

        // Invalidate incoming-related caches
        $this->cacheService->invalidateIncomingCache();
    }

    /**
     * Handle the Incoming "updated" event.
     *
     * @param Incoming $incoming
     * @return void
     */
    public function updated(Incoming $incoming): void
    {
        // Only adjust if amount changed
        if ($incoming->isDirty('amount_usd')) {
            try {
                $oldAmount = $incoming->getOriginal('amount_usd');
                $newAmount = $incoming->amount_usd;
                $difference = $newAmount - $oldAmount;
                
                // Adjust by the difference (positive if amount increased, negative if decreased)
                $user = $incoming->user;
                if ($user) {
                    $this->fundBoxService->adjustBalanceForUser($user, $difference);
                }
            } catch (\Exception $e) {
                Log::error('Failed to update fund box on incoming update', [
                    'incoming_id' => $incoming->id,
                    'error' => $e->getMessage(),
                ]);
            }
        }

        // Log the action
        $this->auditLogService->logAction(
            Auth::user(),
            'update',
            'Incoming',
            $incoming->id,
            [
                'changes' => $incoming->getChanges(),
                'original' => $incoming->getOriginal(),
            ]
        );

        // Invalidate incoming-related caches
        $this->cacheService->invalidateIncomingCache();
    }

    /**
     * Handle the Incoming "deleted" event.
     *
     * @param Incoming $incoming
     * @return void
     */
    public function deleted(Incoming $incoming): void
    {
        try {
            // Subtract incoming amount from fund box
            $user = $incoming->user;
            if ($user) {
                $this->fundBoxService->adjustBalanceForUser($user, -$incoming->amount_usd);
            }
        } catch (\Exception $e) {
            Log::error('Failed to update fund box on incoming deletion', [
                'incoming_id' => $incoming->id,
                'error' => $e->getMessage(),
            ]);
        }

        // Log the action
        $this->auditLogService->logAction(
            Auth::user(),
            'delete',
            'Incoming',
            $incoming->id,
            [
                'description' => $incoming->description,
                'amount_usd' => $incoming->amount_usd,
            ]
        );

        // Invalidate incoming-related caches
        $this->cacheService->invalidateIncomingCache();
    }

    /**
     * Handle the Incoming "restored" event.
     *
     * @param Incoming $incoming
     * @return void
     */
    public function restored(Incoming $incoming): void
    {
        try {
            // Add incoming amount back to fund box
            $user = $incoming->user;
            if ($user) {
                $this->fundBoxService->adjustBalanceForUser($user, $incoming->amount_usd);
            }
        } catch (\Exception $e) {
            Log::error('Failed to update fund box on incoming restoration', [
                'incoming_id' => $incoming->id,
                'error' => $e->getMessage(),
            ]);
        }

        // Invalidate incoming-related caches
        $this->cacheService->invalidateIncomingCache();
    }
}
