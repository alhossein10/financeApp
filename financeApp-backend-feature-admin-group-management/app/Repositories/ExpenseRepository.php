<?php

namespace App\Repositories;

use App\Models\Expense;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ExpenseRepository extends BaseRepository
{
    /**
     * Create a new ExpenseRepository instance.
     *
     * @param Expense $expense
     */
    public function __construct(Expense $expense)
    {
        parent::__construct($expense);
    }

    /**
     * Get expenses for a specific user with filtering.
     *
     * @param User $user
     * @param array $filters
     * @param int $perPage
     * @return LengthAwarePaginator|\Illuminate\Support\Collection
     */
    public function getUserExpenses(User $user, array $filters = [], int $perPage = 15)
    {
        $query = $this->model->newQuery()
            ->where('user_id', $user->id)
            ->select('expenses.*'); // Optimize by selecting only needed columns
        
        $query = $this->applyExpenseFilters($query, $filters);
        
        // If perPage is null or 0, return all results as collection
        if (!$perPage) {
            return $query->get();
        }
        
        return $query->paginate($perPage);
    }

    /**
     * Get all expenses (admin access) with filtering.
     *
     * @param User $user
     * @param array $filters
     * @param int $perPage
     * @return LengthAwarePaginator|\Illuminate\Support\Collection
     */
    public function getAllExpenses(User $user, array $filters = [], int $perPage = 15)
    {
        $query = $this->model->newQuery()->with('user:id,name,email');
        
        // Apply group-based data scoping
        if ($user->isAdmin()) {
            // Admin users see expenses from all users in their group
            if ($user->managedGroup) {
                // Get all user IDs in the admin's group
                $groupMemberIds = \App\Models\User::where('admin_group_id', $user->managedGroup->id)
                    ->pluck('id')
                    ->toArray();
                
                $query->whereIn('user_id', $groupMemberIds);
            } else {
                // Admin without a group sees no expenses (or fallback to organization-based)
                // Fallback to organization-based filtering for backward compatibility
                if ($user->organization_id) {
                    $query->where('organization_id', $user->organization_id);
                } else {
                    // No group and no organization - return empty result
                    $query->whereRaw('1 = 0');
                }
            }
        } else {
            // Regular users see only their own expenses
            $query->where('user_id', $user->id);
        }
        
        $query = $this->applyExpenseFilters($query, $filters);
        
        // If perPage is null or 0, return all results as collection
        if (!$perPage) {
            return $query->get();
        }
        
        return $query->paginate($perPage);
    }

    /**
     * Get expenses with invoice attachments.
     *
     * @param User|null $user
     * @param int $perPage
     * @return LengthAwarePaginator
     */
    public function getExpensesWithInvoices(?User $user = null, int $perPage = 15): LengthAwarePaginator
    {
        $query = $this->model->newQuery()->where('has_invoice', true);
        
        if ($user) {
            $query->where('user_id', $user->id);
        }
        
        return $query->paginate($perPage);
    }

    /**
     * Get expenses without invoice attachments.
     *
     * @param User|null $user
     * @param int $perPage
     * @return LengthAwarePaginator
     */
    public function getExpensesWithoutInvoices(?User $user = null, int $perPage = 15): LengthAwarePaginator
    {
        $query = $this->model->newQuery()->where('has_invoice', false);
        
        if ($user) {
            $query->where('user_id', $user->id);
        }
        
        return $query->paginate($perPage);
    }

    /**
     * Apply expense-specific filters to the query.
     *
     * @param Builder $query
     * @param array $filters
     * @return Builder
     */
    protected function applyExpenseFilters(Builder $query, array $filters): Builder
    {
        // Apply base filters (date range, sorting)
        $query = $this->applyFilters($query, $filters);

        // Filter by sync status
        if (isset($filters['sync_status'])) {
            $query->where('sync_status', $filters['sync_status']);
        }

        // Filter by expense date range
        if (isset($filters['expense_date_from'])) {
            $query->whereDate('expense_date', '>=', $filters['expense_date_from']);
        }

        if (isset($filters['expense_date_to'])) {
            $query->whereDate('expense_date', '<=', $filters['expense_date_to']);
        }

        // Filter by invoice status
        if (isset($filters['has_invoice'])) {
            $query->where('has_invoice', $filters['has_invoice']);
        }

        // Filter by user (for admin queries)
        if (isset($filters['user_id'])) {
            $query->where('user_id', $filters['user_id']);
        }

        // Search in description
        if (isset($filters['search'])) {
            $query->where('description', 'like', '%' . $filters['search'] . '%');
        }

        return $query;
    }
}
