<?php

namespace App\Services;

use App\Models\AuditLog;
use App\Models\User;
use App\Repositories\AuditLogRepository;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\Request;

class AuditLogService
{
    /**
     * Create a new AuditLogService instance.
     *
     * @param AuditLogRepository $auditLogRepository
     */
    public function __construct(
        protected AuditLogRepository $auditLogRepository
    ) {}

    /**
     * Log an action for CRUD operations.
     *
     * @param User|null $user
     * @param string $action
     * @param string $resourceType
     * @param int|null $resourceId
     * @param array $metadata
     * @return AuditLog
     */
    public function logAction(
        ?User $user,
        string $action,
        string $resourceType,
        ?int $resourceId = null,
        array $metadata = []
    ): AuditLog {
        return $this->auditLogRepository->create([
            'user_id' => $user?->id,
            'action' => $action,
            'resource_type' => $resourceType,
            'resource_id' => $resourceId,
            'ip_address' => Request::ip(),
            'user_agent' => Request::userAgent(),
            'metadata' => $metadata,
        ]);
    }

    /**
     * Log a failed authentication attempt for security tracking.
     *
     * @param string $email
     * @param string $ipAddress
     * @param string|null $reason
     * @return AuditLog
     */
    public function logFailedAuth(string $email, string $ipAddress, ?string $reason = null): AuditLog
    {
        return $this->auditLogRepository->create([
            'user_id' => null,
            'action' => 'failed_auth',
            'resource_type' => 'User',
            'resource_id' => null,
            'ip_address' => $ipAddress,
            'user_agent' => Request::userAgent(),
            'metadata' => [
                'email' => $email,
                'reason' => $reason ?? 'Invalid credentials',
            ],
        ]);
    }

    /**
     * Log admin access to user data for tracking.
     *
     * @param User $admin
     * @param string $resourceType
     * @param int $resourceId
     * @param array $additionalMetadata
     * @return AuditLog
     */
    public function logDataAccess(
        User $admin,
        string $resourceType,
        int $resourceId,
        array $additionalMetadata = []
    ): AuditLog {
        return $this->auditLogRepository->create([
            'user_id' => $admin->id,
            'action' => 'view',
            'resource_type' => $resourceType,
            'resource_id' => $resourceId,
            'ip_address' => Request::ip(),
            'user_agent' => Request::userAgent(),
            'metadata' => array_merge([
                'admin_access' => true,
            ], $additionalMetadata),
        ]);
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
        return $this->auditLogRepository->getAuditLogs($filters, $perPage);
    }

    /**
     * Get a single audit log by ID.
     *
     * @param int $id
     * @return AuditLog|null
     */
    public function getAuditLogById(int $id): ?AuditLog
    {
        return $this->auditLogRepository->find($id);
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
        return $this->auditLogRepository->getUserAuditLogs($user, $filters, $perPage);
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
        return $this->auditLogRepository->getResourceAuditLogs($resourceType, $resourceId, $perPage);
    }
}
