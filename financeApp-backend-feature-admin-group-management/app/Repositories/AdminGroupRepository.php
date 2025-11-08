<?php

namespace App\Repositories;

use App\Models\AdminGroup;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;

class AdminGroupRepository extends BaseRepository
{
    /**
     * Create a new AdminGroupRepository instance.
     *
     * @param AdminGroup $model
     */
    public function __construct(AdminGroup $model)
    {
        parent::__construct($model);
    }

    /**
     * Find an admin group by group code.
     *
     * @param string $groupCode
     * @return AdminGroup|null
     */
    public function findByGroupCode(string $groupCode): ?AdminGroup
    {
        return $this->model->where('group_code', $groupCode)
            ->where('is_active', true)
            ->first();
    }

    /**
     * Find an admin group by admin user.
     *
     * @param User $admin
     * @return AdminGroup|null
     */
    public function findByAdmin(User $admin): ?AdminGroup
    {
        return $this->model->where('admin_user_id', $admin->id)
            ->where('is_active', true)
            ->first();
    }

    /**
     * Get paginated group members with optional filters.
     *
     * @param AdminGroup $group
     * @param array $filters
     * @param int $perPage
     * @return LengthAwarePaginator
     */
    public function getGroupMembers(AdminGroup $group, array $filters = [], int $perPage = 15): LengthAwarePaginator
    {
        $query = User::where('admin_group_id', $group->id);

        // Apply filters
        $query = $this->applyMemberFilters($query, $filters);

        return $query->paginate($perPage);
    }

    /**
     * Check if a group code is unique.
     *
     * @param string $groupCode
     * @param int|null $excludeGroupId Optional group ID to exclude from uniqueness check
     * @return bool
     */
    public function isGroupCodeUnique(string $groupCode, ?int $excludeGroupId = null): bool
    {
        $query = $this->model->where('group_code', $groupCode);

        if ($excludeGroupId !== null) {
            $query->where('id', '!=', $excludeGroupId);
        }

        return !$query->exists();
    }

    /**
     * Update the group code for an admin group.
     *
     * @param AdminGroup $group
     * @param string $newCode
     * @return AdminGroup
     */
    public function updateGroupCode(AdminGroup $group, string $newCode): AdminGroup
    {
        $group->group_code = $newCode;
        $group->save();
        
        return $group->fresh();
    }

    /**
     * Apply filters to the group members query.
     *
     * @param Builder $query
     * @param array $filters
     * @return Builder
     */
    protected function applyMemberFilters(Builder $query, array $filters): Builder
    {
        // Filter by name
        if (isset($filters['name']) && !empty($filters['name'])) {
            $query->where('name', 'like', '%' . $filters['name'] . '%');
        }

        // Filter by email
        if (isset($filters['email']) && !empty($filters['email'])) {
            $query->where('email', 'like', '%' . $filters['email'] . '%');
        }

        // Filter by department
        if (isset($filters['department_name']) && !empty($filters['department_name'])) {
            $query->where('department_name', 'like', '%' . $filters['department_name'] . '%');
        }

        // Filter by role (should typically be 'user' for group members)
        if (isset($filters['role']) && !empty($filters['role'])) {
            $query->where('role', $filters['role']);
        }

        // Apply date range filter for when user joined the group
        if (isset($filters['joined_from'])) {
            $query->whereDate('updated_at', '>=', $filters['joined_from']);
        }

        if (isset($filters['joined_to'])) {
            $query->whereDate('updated_at', '<=', $filters['joined_to']);
        }

        // Apply sorting
        if (isset($filters['sort_by'])) {
            $direction = $filters['sort_direction'] ?? 'asc';
            $query->orderBy($filters['sort_by'], $direction);
        } else {
            // Default sorting by name
            $query->orderBy('name', 'asc');
        }

        return $query;
    }
}
