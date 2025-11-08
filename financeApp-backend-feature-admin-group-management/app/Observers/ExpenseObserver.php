<?php

namespace App\Observers;

use App\Models\Expense;
use App\Services\AuditLogService;
use App\Services\CacheService;
use Illuminate\Support\Facades\Auth;

class ExpenseObserver
{
    /**
     * Create a new ExpenseObserver instance.
     *
     * @param AuditLogService $auditLogService
     * @param CacheService $cacheService
     */
    public function __construct(
        protected AuditLogService $auditLogService,
        protected CacheService $cacheService
    ) {}

    /**
     * Handle the Expense "created" event.
     *
     * @param Expense $expense
     * @return void
     */
    public function created(Expense $expense): void
    {
        $this->auditLogService->logAction(
            Auth::user(),
            'create',
            'Expense',
            $expense->id,
            [
                'description' => $expense->description,
                'price_usd' => $expense->price_usd,
                'expense_date' => $expense->expense_date->format('Y-m-d'),
            ]
        );

        // Invalidate expense-related caches
        $this->cacheService->invalidateExpenseCache();
    }

    /**
     * Handle the Expense "updated" event.
     *
     * @param Expense $expense
     * @return void
     */
    public function updated(Expense $expense): void
    {
        $this->auditLogService->logAction(
            Auth::user(),
            'update',
            'Expense',
            $expense->id,
            [
                'changes' => $expense->getChanges(),
                'original' => $expense->getOriginal(),
            ]
        );

        // Invalidate expense-related caches
        $this->cacheService->invalidateExpenseCache();
    }

    /**
     * Handle the Expense "deleted" event.
     *
     * @param Expense $expense
     * @return void
     */
    public function deleted(Expense $expense): void
    {
        $this->auditLogService->logAction(
            Auth::user(),
            'delete',
            'Expense',
            $expense->id,
            [
                'description' => $expense->description,
                'price_usd' => $expense->price_usd,
            ]
        );

        // Invalidate expense-related caches
        $this->cacheService->invalidateExpenseCache();
    }

    /**
     * Handle the Expense "force deleted" event.
     *
     * @param Expense $expense
     * @return void
     */
    public function forceDeleted(Expense $expense): void
    {
        $this->auditLogService->logAction(
            Auth::user(),
            'force_delete',
            'Expense',
            $expense->id,
            [
                'description' => $expense->description,
                'price_usd' => $expense->price_usd,
            ]
        );

        // Invalidate expense-related caches
        $this->cacheService->invalidateExpenseCache();
    }
}
