<?php

namespace App\Services;

use App\Models\Expense;
use App\Models\Incoming;
use App\Models\Transfer;
use App\Models\User;
use App\Repositories\FundBoxRepository;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class AdminDashboardService
{
    /**
     * Create a new AdminDashboardService instance.
     *
     * @param FundBoxRepository $fundBoxRepository
     * @param CacheService $cacheService
     */
    public function __construct(
        protected FundBoxRepository $fundBoxRepository,
        protected CacheService $cacheService
    ) {}

    /**
     * Get overall system statistics.
     *
     * @return array
     */
    public function getOverallStats(): array
    {
        return $this->cacheService->cacheDashboardStats(function () {
            $fundBox = $this->fundBoxRepository->getFundBox();

            return [
                'user_count' => User::count(),
                'expense_count' => Expense::count(),
                'transfer_count' => Transfer::count(),
                'incoming_count' => Incoming::count(),
                'fund_box_balance' => $fundBox->balance_usd,
                'fund_box_last_calculated_at' => $fundBox->last_calculated_at,
            ];
        });
    }

    /**
     * Get user activity list with transaction counts and last activity.
     *
     * @return Collection
     */
    public function getUserActivityList(): Collection
    {
        return $this->cacheService->cacheUserActivityList(function () {
            return User::select('users.*')
                ->withCount(['expenses', 'transfers', 'incoming'])
                ->get()
                ->map(function ($user) {
                    $lastActivity = $this->getUserLastActivity($user);
                    
                    return [
                        'id' => $user->id,
                        'name' => $user->name,
                        'email' => $user->email,
                        'role' => $user->role,
                        'expense_count' => $user->expenses_count,
                        'transfer_count' => $user->transfers_count,
                        'incoming_count' => $user->incoming_count,
                        'last_activity_at' => $lastActivity,
                        'created_at' => $user->created_at,
                    ];
                });
        });
    }

    /**
     * Get expense summaries by currency and by user.
     *
     * @param array $filters
     * @return array
     */
    public function getExpenseSummaries(array $filters = []): array
    {
        return $this->cacheService->cacheExpenseSummaries($filters, function () use ($filters) {
            $query = Expense::query();

            // Apply date range filters if provided
            if (isset($filters['start_date'])) {
                $query->where('expense_date', '>=', Carbon::parse($filters['start_date']));
            }
            if (isset($filters['end_date'])) {
                $query->where('expense_date', '<=', Carbon::parse($filters['end_date']));
            }

            // Get summaries by currency
            $byCurrency = [
                'total_usd' => (float) $query->sum('price_usd'),
                'total_syp' => (float) $query->sum('price_syp'),
                'total_try' => (float) $query->sum('price_try'),
            ];

            // Get summaries by user
            $byUser = Expense::query()
                ->when(isset($filters['start_date']), function ($q) use ($filters) {
                    $q->where('expense_date', '>=', Carbon::parse($filters['start_date']));
                })
                ->when(isset($filters['end_date']), function ($q) use ($filters) {
                    $q->where('expense_date', '<=', Carbon::parse($filters['end_date']));
                })
                ->select('user_id')
                ->selectRaw('SUM(price_usd) as total_usd')
                ->selectRaw('SUM(price_syp) as total_syp')
                ->selectRaw('SUM(price_try) as total_try')
                ->selectRaw('COUNT(*) as expense_count')
                ->with('user:id,name,email')
                ->groupBy('user_id')
                ->get()
                ->map(function ($expense) {
                    return [
                        'user_id' => $expense->user_id,
                        'user_name' => $expense->user->name,
                        'user_email' => $expense->user->email,
                        'total_usd' => (float) $expense->total_usd,
                        'total_syp' => (float) $expense->total_syp,
                        'total_try' => (float) $expense->total_try,
                        'expense_count' => $expense->expense_count,
                    ];
                });

            return [
                'by_currency' => $byCurrency,
                'by_user' => $byUser,
            ];
        });
    }

    /**
     * Get analytics with date range filtering.
     *
     * @param Carbon $startDate
     * @param Carbon $endDate
     * @return array
     */
    public function getAnalytics(Carbon $startDate, Carbon $endDate): array
    {
        return [
            'date_range' => [
                'start_date' => $startDate->toDateString(),
                'end_date' => $endDate->toDateString(),
            ],
            'expenses' => $this->getExpenseAnalytics($startDate, $endDate),
            'transfers' => $this->getTransferAnalytics($startDate, $endDate),
            'incoming' => $this->getIncomingAnalytics($startDate, $endDate),
            'summary' => $this->getSummaryAnalytics($startDate, $endDate),
        ];
    }

    /**
     * Get user's last activity timestamp.
     *
     * @param User $user
     * @return Carbon|null
     */
    protected function getUserLastActivity(User $user): ?Carbon
    {
        $lastExpense = Expense::where('user_id', $user->id)
            ->max('updated_at');
        
        $lastTransfer = Transfer::where('user_id', $user->id)
            ->max('updated_at');
        
        $lastIncoming = Incoming::where('user_id', $user->id)
            ->max('updated_at');

        $timestamps = array_filter([
            $lastExpense ? Carbon::parse($lastExpense) : null,
            $lastTransfer ? Carbon::parse($lastTransfer) : null,
            $lastIncoming ? Carbon::parse($lastIncoming) : null,
        ]);

        return !empty($timestamps) ? max($timestamps) : null;
    }

    /**
     * Get expense analytics for date range.
     *
     * @param Carbon $startDate
     * @param Carbon $endDate
     * @return array
     */
    protected function getExpenseAnalytics(Carbon $startDate, Carbon $endDate): array
    {
        $expenses = Expense::whereBetween('expense_date', [$startDate, $endDate]);

        return [
            'count' => $expenses->count(),
            'total_usd' => (float) $expenses->sum('price_usd'),
            'total_syp' => (float) $expenses->sum('price_syp'),
            'total_try' => (float) $expenses->sum('price_try'),
            'with_invoice_count' => Expense::whereBetween('expense_date', [$startDate, $endDate])
                ->where('has_invoice', true)
                ->count(),
        ];
    }

    /**
     * Get transfer analytics for date range.
     *
     * @param Carbon $startDate
     * @param Carbon $endDate
     * @return array
     */
    protected function getTransferAnalytics(Carbon $startDate, Carbon $endDate): array
    {
        $transfers = Transfer::whereBetween('transfer_date', [$startDate, $endDate]);

        return [
            'count' => $transfers->count(),
            'total_usd' => (float) $transfers->sum('amount_usd'),
        ];
    }

    /**
     * Get incoming analytics for date range.
     *
     * @param Carbon $startDate
     * @param Carbon $endDate
     * @return array
     */
    protected function getIncomingAnalytics(Carbon $startDate, Carbon $endDate): array
    {
        $incoming = Incoming::whereBetween('incoming_date', [$startDate, $endDate]);

        return [
            'count' => $incoming->count(),
            'total_usd' => (float) $incoming->sum('amount_usd'),
        ];
    }

    /**
     * Get summary analytics for date range.
     *
     * @param Carbon $startDate
     * @param Carbon $endDate
     * @return array
     */
    protected function getSummaryAnalytics(Carbon $startDate, Carbon $endDate): array
    {
        $totalExpenses = (float) Expense::whereBetween('expense_date', [$startDate, $endDate])
            ->sum('price_usd');
        
        $totalTransfers = (float) Transfer::whereBetween('transfer_date', [$startDate, $endDate])
            ->sum('amount_usd');
        
        $totalIncoming = (float) Incoming::whereBetween('incoming_date', [$startDate, $endDate])
            ->sum('amount_usd');

        $netFlow = $totalIncoming - $totalExpenses - $totalTransfers;

        return [
            'total_expenses_usd' => $totalExpenses,
            'total_transfers_usd' => $totalTransfers,
            'total_incoming_usd' => $totalIncoming,
            'net_flow_usd' => $netFlow,
        ];
    }
}
