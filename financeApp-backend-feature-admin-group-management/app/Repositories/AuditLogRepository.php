<?php

namespace App\Repositories;

use App\Models\AuditLog;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class AuditLogRepository extends BaseRepository
{
    /**
     * Create a new AuditLogRepository instance.
     *
     * @param AuditLog $auditLog
     */
    public function __construct(AuditLog $auditLog)
    {
        parent::__construct($auditLog);
    }

    /**
     * Get audit logs with filtering.
     *
     * @param array $filters
     * @param int $perPage
     * @return LengthAwarePaginator
     */
    public function getAuditLogs(array $filters = [], int $perPage = 15): LengthAwarePaginator
    {
        $query = $this->model->newQuery()
            ->with('user:id,name,email')
            ->orderBy('created_at', 'desc');
        
        $query = $this->applyAuditLogFilters($query, $filters);
        return $query->paginate($perPage);
    }

    /**
     * Get audit logs for a specific user.
     *
     * @param User $user
     * @param array $filters
     * @param int $perPage
     * @return LengthAwarePaginator
     */
    public function getUserAuditLogs(User $user, array $filters = [], int $perPage = 15): LengthAwarePaginator
    {
        $query = $this->model->newQuery()
            ->where('user_id', $user->id)
            ->orderBy('created_at', 'desc');
        
        $query = $this->applyAuditLogFilters($query, $filters);
        return $query->paginate($perPage);
    }

    /**
     * Get audit logs for a specific resource.
     *
     * @param string $resourceType
     * @param int $resourceId
     * @param int $perPage
     * @return LengthAwarePaginator
     */
    public function getResourceAuditLogs(string $resourceType, int $resourceId, int $perPage = 15): LengthAwarePaginator
    {
        return $this->model->newQuery()
            ->with('user:id,name,email')
            ->where('resource_type', $resourceType)
            ->where('resource_id', $resourceId)
            ->orderBy('created_at', 'desc')
            ->paginate($perPage);
    }

    /**
     * Apply audit log-specific filters to the query.
     *
     * @param Builder $query
     * @param array $filters
     * @return Builder
     */
    protected function applyAuditLogFilters(Builder $query, array $filters): Builder
    {
        // Apply base filters (date range, sorting)
        $query = $this->applyFilters($query, $filters);

        // Filter by user
        if (isset($filters['user_id'])) {
            $query->where('user_id', $filters['user_id']);
        }

        // Filter by action type
        if (isset($filters['action'])) {
            $query->where('action', $filters['action']);
        }

        // Filter by resource type
        if (isset($filters['resource_type'])) {
            $query->where('resource_type', $filters['resource_type']);
        }

        // Filter by resource ID
        if (isset($filters['resource_id'])) {
            $query->where('resource_id', $filters['resource_id']);
        }

        // Filter by IP address
        if (isset($filters['ip_address'])) {
            $query->where('ip_address', $filters['ip_address']);
        }

        // Filter by date range (created_at)
        if (isset($filters['created_from'])) {
            $query->whereDate('created_at', '>=', $filters['created_from']);
        }

        if (isset($filters['created_to'])) {
            $query->whereDate('created_at', '<=', $filters['created_to']);
        }

        return $query;
    }
}
