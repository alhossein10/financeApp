<?php

namespace App\Services;

use App\Models\Transfer;
use App\Models\Exchange;
use App\Models\User;
use App\Repositories\TransferRepository;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

class TransferService
{
    /**
     * Create a new TransferService instance.
     *
     * @param TransferRepository $transferRepository
     * @param AdminGroupService $adminGroupService
     */
    public function __construct(
        protected TransferRepository $transferRepository,
        protected AdminGroupService $adminGroupService
    ) {}

    /**
     * Create a new transfer with optional currency exchange support.
     *
     * @param User $user
     * @param array $data
     * @return Transfer
     * @throws \Exception
     * @throws ValidationException
     */
    public function createTransfer(User $user, array $data): Transfer
    {
        try {
            DB::beginTransaction();

            // Validate group member restrictions for admins
            if ($user->isAdmin() && isset($data['recipient_user_id'])) {
                $this->validateRecipientInGroup($user, $data['recipient_user_id']);
            }

            // Validate group member restrictions for regular users
            if ($user->isUser() && isset($data['recipient_user_id'])) {
                $this->validateRecipientForRegularUser($user, $data['recipient_user_id']);
            }

            // Create the transfer
            $transferData = [
                'user_id' => $user->id,
                'organization_id' => $user->organization_id,
                'department_id' => $user->department_id,
                'recipient_name' => $data['recipient_name'],
                'amount_usd' => $data['amount_usd'],
                'transfer_date' => $data['transfer_date'],
                'notes' => $data['notes'] ?? null,
                'sync_status' => $data['sync_status'] ?? 'synced',
                'synced_at' => $data['synced_at'] ?? now(),
            ];

            $transfer = $this->transferRepository->create($transferData);

            // If exchange data is provided, create the exchange record
            if (isset($data['exchange'])) {
                $this->addExchange($transfer, $data['exchange']);
            }

            DB::commit();

            Log::info('Transfer created', [
                'transfer_id' => $transfer->id,
                'user_id' => $user->id,
                'amount_usd' => $transfer->amount_usd,
            ]);

            return $transfer->load('exchange');
        } catch (ValidationException $e) {
            DB::rollBack();
            throw $e;
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Failed to create transfer', [
                'user_id' => $user->id,
                'error' => $e->getMessage(),
            ]);
            throw $e;
        }
    }

    /**
     * Update an existing transfer.
     *
     * @param Transfer $transfer
     * @param array $data
     * @return Transfer
     * @throws \Exception
     */
    public function updateTransfer(Transfer $transfer, array $data): Transfer
    {
        try {
            DB::beginTransaction();

            $updateData = [];

            if (isset($data['recipient_name'])) {
                $updateData['recipient_name'] = $data['recipient_name'];
            }

            if (isset($data['amount_usd'])) {
                $updateData['amount_usd'] = $data['amount_usd'];
            }

            if (isset($data['transfer_date'])) {
                $updateData['transfer_date'] = $data['transfer_date'];
            }

            if (isset($data['notes'])) {
                $updateData['notes'] = $data['notes'];
            }

            if (isset($data['sync_status'])) {
                $updateData['sync_status'] = $data['sync_status'];
            }

            if (isset($data['synced_at'])) {
                $updateData['synced_at'] = $data['synced_at'];
            }

            $transfer = $this->transferRepository->update($transfer, $updateData);

            // Update exchange data if provided
            if (isset($data['exchange'])) {
                if ($transfer->exchange) {
                    // Update existing exchange
                    $transfer->exchange->update($data['exchange']);
                } else {
                    // Create new exchange
                    $this->addExchange($transfer, $data['exchange']);
                }
            }

            DB::commit();

            Log::info('Transfer updated', [
                'transfer_id' => $transfer->id,
                'user_id' => $transfer->user_id,
            ]);

            return $transfer->fresh(['exchange']);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Failed to update transfer', [
                'transfer_id' => $transfer->id,
                'error' => $e->getMessage(),
            ]);
            throw $e;
        }
    }

    /**
     * Delete a transfer with soft delete.
     *
     * @param Transfer $transfer
     * @return bool
     * @throws \Exception
     */
    public function deleteTransfer(Transfer $transfer): bool
    {
        try {
            DB::beginTransaction();

            $transferId = $transfer->id;
            $userId = $transfer->user_id;

            // Soft delete the transfer (cascade will handle exchange if configured)
            $deleted = $this->transferRepository->delete($transfer);

            DB::commit();

            Log::info('Transfer deleted', [
                'transfer_id' => $transferId,
                'user_id' => $userId,
            ]);

            return $deleted;
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Failed to delete transfer', [
                'transfer_id' => $transfer->id,
                'error' => $e->getMessage(),
            ]);
            throw $e;
        }
    }

    /**
     * Add exchange data to a transfer.
     *
     * @param Transfer $transfer
     * @param array $data
     * @return Exchange
     * @throws \Exception
     */
    public function addExchange(Transfer $transfer, array $data): Exchange
    {
        try {
            $exchangeData = [
                'transfer_id' => $transfer->id,
                'converted_amount_syp' => $data['converted_amount_syp'] ?? null,
                'converted_amount_try' => $data['converted_amount_try'] ?? null,
                'exchange_rate_usd_to_syp' => $data['exchange_rate_usd_to_syp'] ?? null,
                'exchange_rate_usd_to_try' => $data['exchange_rate_usd_to_try'] ?? null,
                'exchange_date' => $data['exchange_date'] ?? $transfer->transfer_date,
            ];

            $exchange = Exchange::create($exchangeData);

            Log::info('Exchange added to transfer', [
                'transfer_id' => $transfer->id,
                'exchange_id' => $exchange->id,
            ]);

            return $exchange;
        } catch (\Exception $e) {
            Log::error('Failed to add exchange to transfer', [
                'transfer_id' => $transfer->id,
                'error' => $e->getMessage(),
            ]);
            throw $e;
        }
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
        return $this->transferRepository->getUserTransfers($user, $filters, $perPage);
    }

    /**
     * Get all transfers (admin access) with filtering.
     *
     * @param array $filters
     * @param int $perPage
     * @return LengthAwarePaginator
     */
    public function getAllTransfers(User $user, array $filters = [], int $perPage = 15): LengthAwarePaginator
    {
        return $this->transferRepository->getAllTransfers($user, $filters, $perPage);
    }

    /**
     * Find a transfer by ID with exchange data.
     *
     * @param int $id
     * @return Transfer|null
     */
    public function findTransferWithExchange(int $id): ?Transfer
    {
        return $this->transferRepository->findWithExchange($id);
    }

    /**
     * Validate that the recipient is in the admin's group.
     *
     * @param User $admin
     * @param int $recipientUserId
     * @return void
     * @throws ValidationException
     */
    protected function validateRecipientInGroup(User $admin, int $recipientUserId): void
    {
        // Get available transfer recipients (users in admin's group)
        $availableRecipients = $this->adminGroupService->getAvailableTransferRecipients($admin);

        // Check if the recipient is in the list
        $recipientInGroup = $availableRecipients->contains('id', $recipientUserId);

        if (!$recipientInGroup) {
            throw ValidationException::withMessages([
                'recipient_user_id' => ['Cannot transfer to user outside your group.'],
            ]);
        }
    }

    /**
     * Validate that a regular user can only transfer to themselves or within their group.
     *
     * @param User $user
     * @param int $recipientUserId
     * @return void
     * @throws ValidationException
     */
    protected function validateRecipientForRegularUser(User $user, int $recipientUserId): void
    {
        // Regular users can transfer to themselves
        if ($user->id === $recipientUserId) {
            return;
        }

        // If user is in a group, they can transfer to other members in the same group
        if ($user->isGroupMember()) {
            $recipient = User::find($recipientUserId);

            if (!$recipient) {
                throw ValidationException::withMessages([
                    'recipient_user_id' => ['Recipient user not found.'],
                ]);
            }

            // Check if recipient is in the same group
            if ($recipient->admin_group_id !== $user->admin_group_id) {
                throw ValidationException::withMessages([
                    'recipient_user_id' => ['Cannot transfer to user outside your group.'],
                ]);
            }
        } else {
            // Users not in a group can only transfer to themselves
            throw ValidationException::withMessages([
                'recipient_user_id' => ['You can only transfer to yourself.'],
            ]);
        }
    }

    /**
     * Get available transfer recipients for a user.
     * For admins: returns users in their group.
     * For regular users: returns themselves and other members in their group.
     *
     * @param User $user
     * @return \Illuminate\Database\Eloquent\Collection
     */
    public function getAvailableTransferRecipients(User $user): \Illuminate\Database\Eloquent\Collection
    {
        if ($user->isAdmin()) {
            // Admins can transfer to users in their group
            return $this->adminGroupService->getAvailableTransferRecipients($user);
        }

        // Regular users can transfer to themselves
        $recipients = collect([$user]);

        // If user is in a group, they can also transfer to other members
        if ($user->isGroupMember()) {
            $groupMembers = User::where('admin_group_id', $user->admin_group_id)
                ->where('id', '!=', $user->id)
                ->where('role', 'user')
                ->whereNull('deleted_at')
                ->orderBy('name', 'asc')
                ->get(['id', 'name', 'email', 'department_name']);

            $recipients = $recipients->merge($groupMembers);
        }

        return $recipients;
    }
}
