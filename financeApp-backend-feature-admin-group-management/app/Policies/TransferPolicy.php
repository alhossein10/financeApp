<?php

namespace App\Policies;

use App\Models\Transfer;
use App\Models\User;

class TransferPolicy
{
    /**
     * Determine if the user can view the transfer.
     *
     * @param User $user
     * @param Transfer $transfer
     * @return bool
     */
    public function view(User $user, Transfer $transfer): bool
    {
        // Admin can view all transfers, users can only view their own
        return $user->role === 'admin' || $transfer->user_id === $user->id;
    }

    /**
     * Determine if the user can update the transfer.
     *
     * @param User $user
     * @param Transfer $transfer
     * @return bool
     */
    public function update(User $user, Transfer $transfer): bool
    {
        // Admin can update all transfers, users can only update their own
        return $user->role === 'admin' || $transfer->user_id === $user->id;
    }

    /**
     * Determine if the user can delete the transfer.
     *
     * @param User $user
     * @param Transfer $transfer
     * @return bool
     */
    public function delete(User $user, Transfer $transfer): bool
    {
        // Admin can delete all transfers, users can only delete their own
        return $user->role === 'admin' || $transfer->user_id === $user->id;
    }
}
