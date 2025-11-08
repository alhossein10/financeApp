<?php

namespace App\Repositories;

use App\Models\Transfer;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class TransferRepository extends BaseRepository
{
    /**
     * Create a new TransferRepository instance.
     *
     * @param Transfer $transfer
     */
    public function __construct(Transfer $transfer)
    {
        parent::__construct($transfer);
    }

    /**
     * Get transfers for a specific user with filtering.
     *
     * @param User $user
     * @param array $filters
     * @param int $perPage
     * @return LengthAwarePaginator
     */
    public function getUserTransfers(User $user, array $filters = [], int $perPage = 15): LengthAwarePaginator
    {
        $query = $this->model->newQuery()
            ->where('user_id', $user->id)
            ->with('exchange');
        
        $query = $this->applyTransferFilters($query, $filters);
        return $query->paginate($perPage);
    }

    /**
     * Get all transfers (admin access) with filtering.
     *
     * @param User $user
     * @param array $filters
     * @param int $perPage
     * @return LengthAwarePaginator
     */
    public function getAllTransfers(User $user, array $filters = [], int $perPage = 15): LengthAwarePaginator
    {
        $query = $this->model->newQuery()
            ->with(['user:id,name,email', 'exchange']);
        
        // Apply group-based data scoping
        if ($user->isAdmin()) {
            // Admin users see transfers from all users in their group
            if ($user->managedGroup) {
                // Get all user IDs in the admin's group
                $groupMemberIds = \App\Models\User::where('admin_group_id', $user->managedGroup->id)
                    ->pluck('id')
                    ->toArray();
                
                $query->whereIn('user_id', $groupMemberIds);
            } else {
                // Admin without a group sees no transfers (or fallback to organization-based)
                // Fallback to organization-based filtering for backward compatibility
                if ($user->organization_id) {
                    $query->where('organization_id', $user->organization_id);
                } else {
                    // No group and no organization - return empty result
                    $query->whereRaw('1 = 0');
                }
            }
        } else {
            // Regular users see only their own transfers
            $query->where('user_id', $user->id);
        }
        
        $query = $this->applyTransferFilters($query, $filters);
        return $query->paginate($perPage);
    }

    /**
     * Find a transfer with its exchange data.
     *
     * @param int $id
     * @return Transfer|null
     */
    public function findWithExchange(int $id): ?Transfer
    {
        return $this->model->with('exchange')->find($id);
    }

    /**
     * Get transfers with exchange data.
     *
     * @param User|null $user
     * @param int $perPage
     * @return LengthAwarePaginator
     */
    public function getTransfersWithExchange(?User $user = null, int $perPage = 15): LengthAwarePaginator
    {
        $query = $this->model->newQuery()->has('exchange')->with('exchange');
        
        if ($user) {
            $query->where('user_id', $user->id);
        }
        
        return $query->paginate($perPage);
    }

    /**
     * Apply transfer-specific filters to the query.
     *
     * @param Builder $query
     * @param array $filters
     * @return Builder
     */
    protected function applyTransferFilters(Builder $query, array $filters): Builder
    {
        // Apply base filters (date range, sorting)
        $query = $this->applyFilters($query, $filters);

        // Filter by transfer date range
        if (isset($filters['transfer_date_from'])) {
            $query->whereDate('transfer_date', '>=', $filters['transfer_date_from']);
        }

        if (isset($filters['transfer_date_to'])) {
            $query->whereDate('transfer_date', '<=', $filters['transfer_date_to']);
        }

        // Filter by sync status
        if (isset($filters['sync_status'])) {
            $query->where('sync_status', $filters['sync_status']);
        }

        // Filter by user (for admin queries)
        if (isset($filters['user_id'])) {
            $query->where('user_id', $filters['user_id']);
        }

        // Search in recipient name or notes
        if (isset($filters['search'])) {
            $query->where(function ($q) use ($filters) {
                $q->where('recipient_name', 'like', '%' . $filters['search'] . '%')
                  ->orWhere('notes', 'like', '%' . $filters['search'] . '%');
            });
        }

        // Filter by amount range
        if (isset($filters['amount_min'])) {
            $query->where('amount_usd', '>=', $filters['amount_min']);
        }

        if (isset($filters['amount_max'])) {
            $query->where('amount_usd', '<=', $filters['amount_max']);
        }

        return $query;
    }
}
