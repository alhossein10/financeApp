<?php

namespace App\Services;

use App\Models\Expense;
use App\Models\Incoming;
use App\Models\Transfer;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class SyncService
{
    /**
     * The notification service instance.
     *
     * @var NotificationService
     */
    protected NotificationService $notificationService;

    /**
     * Create a new SyncService instance.
     *
     * @param NotificationService $notificationService
     */
    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }
    /**
     * Process batch sync for multiple records.
     *
     * @param User $user
     * @param array $records
     * @return array
     */
    public function batchSync(User $user, array $records): array
    {
        $results = [];
        $failureCount = 0;

        foreach ($records as $record) {
            try {
                $result = $this->processSingleRecord($user, $record);
                $results[] = [
                    'success' => true,
                    'resource_type' => $record['resource_type'] ?? null,
                    'resource_id' => $result['id'] ?? null,
                    'client_id' => $record['client_id'] ?? null,
                    'data' => $result,
                ];
            } catch (\Exception $e) {
                $failureCount++;
                
                Log::error('Sync failed for record', [
                    'user_id' => $user->id,
                    'record' => $record,
                    'error' => $e->getMessage(),
                ]);

                $results[] = [
                    'success' => false,
                    'resource_type' => $record['resource_type'] ?? null,
                    'client_id' => $record['client_id'] ?? null,
                    'error' => $e->getMessage(),
                    'error_code' => 'SYNC_FAILED',
                ];

                // Track retry count and send alert if exceeds threshold
                $retryCount = $record['sync_retry_count'] ?? 0;
                if ($retryCount > 3) {
                    $this->notificationService->sendSyncFailureAlert($user, $retryCount);
                }
            }
        }

        return $results;
    }

    /**
     * Process a single record for sync.
     *
     * @param User $user
     * @param array $record
     * @return array
     */
    protected function processSingleRecord(User $user, array $record): array
    {
        $resourceType = $record['resource_type'] ?? null;
        $action = $record['action'] ?? 'create';
        $data = $record['data'] ?? [];

        if (!$resourceType) {
            throw new \InvalidArgumentException('resource_type is required');
        }

        // Ensure user_id is set
        $data['user_id'] = $user->id;

        return match ($resourceType) {
            'expense' => $this->syncExpense($action, $data, $record['id'] ?? null),
            'transfer' => $this->syncTransfer($action, $data, $record['id'] ?? null),
            'incoming' => $this->syncIncoming($action, $data, $record['id'] ?? null),
            default => throw new \InvalidArgumentException("Unsupported resource type: {$resourceType}"),
        };
    }

    /**
     * Sync an expense record.
     *
     * @param string $action
     * @param array $data
     * @param int|null $id
     * @return array
     */
    protected function syncExpense(string $action, array $data, ?int $id): array
    {
        if ($action === 'create') {
            $expense = Expense::create($data);
            $this->updateSyncStatus($expense, 'synced');
            return $expense->toArray();
        }

        if ($action === 'update' && $id) {
            $expense = Expense::findOrFail($id);
            
            // Check for conflicts
            if (isset($data['updated_at']) && $expense->updated_at->gt(Carbon::parse($data['updated_at']))) {
                throw new \Exception('Conflict detected: server version is newer');
            }
            
            $expense->update($data);
            $this->updateSyncStatus($expense, 'synced');
            return $expense->fresh()->toArray();
        }

        if ($action === 'delete' && $id) {
            $expense = Expense::findOrFail($id);
            $expense->delete();
            return ['id' => $id, 'deleted' => true];
        }

        throw new \InvalidArgumentException("Invalid action: {$action}");
    }

    /**
     * Sync a transfer record.
     *
     * @param string $action
     * @param array $data
     * @param int|null $id
     * @return array
     */
    protected function syncTransfer(string $action, array $data, ?int $id): array
    {
        if ($action === 'create') {
            $transfer = Transfer::create($data);
            $this->updateSyncStatus($transfer, 'synced');
            return $transfer->toArray();
        }

        if ($action === 'update' && $id) {
            $transfer = Transfer::findOrFail($id);
            
            // Check for conflicts
            if (isset($data['updated_at']) && $transfer->updated_at->gt(Carbon::parse($data['updated_at']))) {
                throw new \Exception('Conflict detected: server version is newer');
            }
            
            $transfer->update($data);
            $this->updateSyncStatus($transfer, 'synced');
            return $transfer->fresh()->toArray();
        }

        if ($action === 'delete' && $id) {
            $transfer = Transfer::findOrFail($id);
            $transfer->delete();
            return ['id' => $id, 'deleted' => true];
        }

        throw new \InvalidArgumentException("Invalid action: {$action}");
    }

    /**
     * Sync an incoming record.
     *
     * @param string $action
     * @param array $data
     * @param int|null $id
     * @return array
     */
    protected function syncIncoming(string $action, array $data, ?int $id): array
    {
        if ($action === 'create') {
            $incoming = Incoming::create($data);
            $this->updateSyncStatus($incoming, 'synced');
            return $incoming->toArray();
        }

        if ($action === 'update' && $id) {
            $incoming = Incoming::findOrFail($id);
            
            // Check for conflicts
            if (isset($data['updated_at']) && $incoming->updated_at->gt(Carbon::parse($data['updated_at']))) {
                throw new \Exception('Conflict detected: server version is newer');
            }
            
            $incoming->update($data);
            $this->updateSyncStatus($incoming, 'synced');
            return $incoming->fresh()->toArray();
        }

        if ($action === 'delete' && $id) {
            $incoming = Incoming::findOrFail($id);
            $incoming->delete();
            return ['id' => $id, 'deleted' => true];
        }

        throw new \InvalidArgumentException("Invalid action: {$action}");
    }

    /**
     * Get changes since a specific timestamp.
     *
     * @param User $user
     * @param Carbon $timestamp
     * @return array
     */
    public function getChangesSince(User $user, Carbon $timestamp): array
    {
        $expenses = Expense::where('user_id', $user->id)
            ->where('updated_at', '>', $timestamp)
            ->get()
            ->map(fn($expense) => [
                'resource_type' => 'expense',
                'id' => $expense->id,
                'action' => $expense->deleted_at ? 'delete' : 'update',
                'data' => $expense->toArray(),
            ]);

        $transfers = Transfer::where('user_id', $user->id)
            ->where('updated_at', '>', $timestamp)
            ->with('exchange')
            ->get()
            ->map(fn($transfer) => [
                'resource_type' => 'transfer',
                'id' => $transfer->id,
                'action' => $transfer->deleted_at ? 'delete' : 'update',
                'data' => $transfer->toArray(),
            ]);

        $incoming = Incoming::where('user_id', $user->id)
            ->where('updated_at', '>', $timestamp)
            ->get()
            ->map(fn($incoming) => [
                'resource_type' => 'incoming',
                'id' => $incoming->id,
                'action' => $incoming->deleted_at ? 'delete' : 'update',
                'data' => $incoming->toArray(),
            ]);

        return [
            'changes' => $expenses->concat($transfers)->concat($incoming)->values()->all(),
            'timestamp' => now()->toIso8601String(),
        ];
    }

    /**
     * Resolve sync conflict using specified strategy.
     *
     * @param string $strategy
     * @param array $clientData
     * @param array $serverData
     * @return mixed
     */
    public function resolveConflict(string $strategy, array $clientData, array $serverData): mixed
    {
        return match ($strategy) {
            'server_wins' => $serverData,
            'client_wins' => $clientData,
            'merge' => $this->mergeData($clientData, $serverData),
            'newest_wins' => $this->selectNewest($clientData, $serverData),
            default => throw new \InvalidArgumentException("Unsupported conflict resolution strategy: {$strategy}"),
        };
    }

    /**
     * Merge client and server data.
     *
     * @param array $clientData
     * @param array $serverData
     * @return array
     */
    protected function mergeData(array $clientData, array $serverData): array
    {
        // Server data takes precedence for system fields
        $systemFields = ['id', 'user_id', 'created_at', 'updated_at', 'deleted_at'];
        
        $merged = $serverData;
        
        foreach ($clientData as $key => $value) {
            if (!in_array($key, $systemFields) && $value !== null) {
                $merged[$key] = $value;
            }
        }
        
        return $merged;
    }

    /**
     * Select the newest data based on updated_at timestamp.
     *
     * @param array $clientData
     * @param array $serverData
     * @return array
     */
    protected function selectNewest(array $clientData, array $serverData): array
    {
        $clientTime = isset($clientData['updated_at']) ? Carbon::parse($clientData['updated_at']) : null;
        $serverTime = isset($serverData['updated_at']) ? Carbon::parse($serverData['updated_at']) : null;
        
        if (!$clientTime || !$serverTime) {
            return $serverData;
        }
        
        return $clientTime->gt($serverTime) ? $clientData : $serverData;
    }

    /**
     * Update sync status for a model.
     *
     * @param mixed $model
     * @param string $status
     * @return void
     */
    public function updateSyncStatus($model, string $status): void
    {
        if (method_exists($model, 'update')) {
            $model->update([
                'sync_status' => $status,
                'synced_at' => $status === 'synced' ? now() : null,
            ]);
        }
    }
}
