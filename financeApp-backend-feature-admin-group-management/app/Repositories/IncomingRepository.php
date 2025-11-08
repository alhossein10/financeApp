<?php

namespace App\Repositories;

use App\Models\Incoming;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class IncomingRepository extends BaseRepository
{
    /**
     * Create a new IncomingRepository instance.
     *
     * @param Incoming $incoming
     */
    public function __construct(Incoming $incoming)
    {
        parent::__construct($incoming);
    }

    /**
     * Get incoming transactions for a specific user with filtering.
     *
     * @param User $user
     * @param array $filters
     * @param int $perPage
     * @return LengthAwarePaginator
     */
    public function getUserIncoming(User $user, array $filters = [], int $perPage = 15): LengthAwarePaginator
    {
        $query = $this->model->newQuery()->where('user_id', $user->id);
        $query = $this->applyIncomingFilters($query, $filters);
        return $query->paginate($perPage);
    }

    /**
     * Get all incoming transactions (admin access) with filtering.
     *
     * @param User $user
     * @param array $filters
     * @param int $perPage
     * @return LengthAwarePaginator
     */
    public function getAllIncoming(User $user, array $filters = [], int $perPage = 15): LengthAwarePaginator
    {
        $query = $this->model->newQuery()->with('user:id,name,email');
        
        // Apply group-based data scoping
        if ($user->isAdmin()) {
            // Admin users see incoming transactions from all users in their group
            if ($user->managedGroup) {
                // Get all user IDs in the admin's group
                $groupMemberIds = \App\Models\User::where('admin_group_id', $user->managedGroup->id)
                    ->pluck('id')
                    ->toArray();
                
                $query->whereIn('user_id', $groupMemberIds);
            } else {
                // Admin without a group sees no incoming transactions (or fallback to organization-based)
                // Fallback to organization-based filtering for backward compatibility
                if ($user->organization_id) {
                    $query->where('organization_id', $user->organization_id);
                } else {
                    // No group and no organization - return empty result
                    $query->whereRaw('1 = 0');
                }
            }
        } else {
            // Regular users see only their own incoming transactions
            $query->where('user_id', $user->id);
        }
        
        $query = $this->applyIncomingFilters($query, $filters);
        return $query->paginate($perPage);
    }

    /**
     * Apply incoming-specific filters to the query.
     *
     * @param Builder $query
     * @param array $filters
     * @return Builder
     */
    protected function applyIncomingFilters(Builder $query, array $filters): Builder
    {
        // Apply base filters (date range, sorting)
        $query = $this->applyFilters($query, $filters);

        // Filter by incoming date range
        if (isset($filters['incoming_date_from'])) {
            $query->whereDate('incoming_date', '>=', $filters['incoming_date_from']);
        }

        if (isset($filters['incoming_date_to'])) {
            $query->whereDate('incoming_date', '<=', $filters['incoming_date_to']);
        }

        // Filter by sync status
        if (isset($filters['sync_status'])) {
            $query->where('sync_status', $filters['sync_status']);
        }

        // Filter by user (for admin queries)
        if (isset($filters['user_id'])) {
            $query->where('user_id', $filters['user_id']);
        }

        // Search in description
        if (isset($filters['search'])) {
            $query->where('description', 'like', '%' . $filters['search'] . '%');
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
