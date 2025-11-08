<?php

namespace App\Services;

use App\Models\Incoming;
use App\Models\User;
use App\Repositories\IncomingRepository;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class IncomingService
{
    /**
     * Create a new IncomingService instance.
     *
     * @param IncomingRepository $incomingRepository
     */
    public function __construct(
        protected IncomingRepository $incomingRepository
    ) {}

    /**
     * Create a new incoming record.
     *
     * @param User $user
     * @param array $data
     * @return Incoming
     * @throws \Exception
     */
    public function createIncoming(User $user, array $data): Incoming
    {
        try {
            DB::beginTransaction();

            $incomingData = [
                'user_id' => $user->id,
                'organization_id' => $user->organization_id,
                'department_id' => $user->department_id,
                'description' => $data['description'],
                'amount_usd' => $data['amount_usd'],
                'incoming_date' => $data['incoming_date'],
                'sync_status' => $data['sync_status'] ?? 'synced',
                'synced_at' => $data['synced_at'] ?? now(),
            ];

            $incoming = $this->incomingRepository->create($incomingData);

            DB::commit();

            Log::info('Incoming record created', [
                'incoming_id' => $incoming->id,
                'user_id' => $user->id,
                'amount_usd' => $incoming->amount_usd,
            ]);

            return $incoming;
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Failed to create incoming record', [
                'user_id' => $user->id,
                'error' => $e->getMessage(),
            ]);
            throw $e;
        }
    }

    /**
     * Update an existing incoming record with timestamp tracking.
     *
     * @param Incoming $incoming
     * @param array $data
     * @return Incoming
     * @throws \Exception
     */
    public function updateIncoming(Incoming $incoming, array $data): Incoming
    {
        try {
            DB::beginTransaction();

            $updateData = [];

            if (isset($data['description'])) {
                $updateData['description'] = $data['description'];
            }

            if (isset($data['amount_usd'])) {
                $updateData['amount_usd'] = $data['amount_usd'];
            }

            if (isset($data['incoming_date'])) {
                $updateData['incoming_date'] = $data['incoming_date'];
            }

            if (isset($data['sync_status'])) {
                $updateData['sync_status'] = $data['sync_status'];
            }

            if (isset($data['synced_at'])) {
                $updateData['synced_at'] = $data['synced_at'];
            }

            // Laravel automatically updates the updated_at timestamp
            $incoming = $this->incomingRepository->update($incoming, $updateData);

            DB::commit();

            Log::info('Incoming record updated', [
                'incoming_id' => $incoming->id,
                'user_id' => $incoming->user_id,
            ]);

            return $incoming->fresh();
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Failed to update incoming record', [
                'incoming_id' => $incoming->id,
                'error' => $e->getMessage(),
            ]);
            throw $e;
        }
    }

    /**
     * Delete an incoming record with soft delete.
     *
     * @param Incoming $incoming
     * @return bool
     * @throws \Exception
     */
    public function deleteIncoming(Incoming $incoming): bool
    {
        try {
            DB::beginTransaction();

            $incomingId = $incoming->id;
            $userId = $incoming->user_id;

            // Soft delete the incoming record
            $deleted = $this->incomingRepository->delete($incoming);

            DB::commit();

            Log::info('Incoming record deleted', [
                'incoming_id' => $incomingId,
                'user_id' => $userId,
            ]);

            return $deleted;
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Failed to delete incoming record', [
                'incoming_id' => $incoming->id,
                'error' => $e->getMessage(),
            ]);
            throw $e;
        }
    }

    /**
     * Get incoming records for a specific user with filtering.
     *
     * @param User $user
     * @param array $filters
     * @param int $perPage
     * @return LengthAwarePaginator
     */
    public function getUserIncoming(User $user, array $filters = [], int $perPage = 15): LengthAwarePaginator
    {
        return $this->incomingRepository->getUserIncoming($user, $filters, $perPage);
    }

    /**
     * Get all incoming records (admin access) with filtering.
     *
     * @param array $filters
     * @param int $perPage
     * @return LengthAwarePaginator
     */
    public function getAllIncoming(User $user, array $filters = [], int $perPage = 15): LengthAwarePaginator
    {
        return $this->incomingRepository->getAllIncoming($user, $filters, $perPage);
    }
}
