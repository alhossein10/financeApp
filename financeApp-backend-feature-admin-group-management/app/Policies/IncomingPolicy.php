<?php

namespace App\Policies;

use App\Models\Incoming;
use App\Models\User;

class IncomingPolicy
{
    /**
     * Determine if the user can view the incoming record.
     *
     * @param User $user
     * @param Incoming $incoming
     * @return bool
     */
    public function view(User $user, Incoming $incoming): bool
    {
        // Admin can view all incoming records, users can only view their own
        return $user->role === 'admin' || $incoming->user_id === $user->id;
    }

    /**
     * Determine if the user can update the incoming record.
     *
     * @param User $user
     * @param Incoming $incoming
     * @return bool
     */
    public function update(User $user, Incoming $incoming): bool
    {
        // Admin can update all incoming records, users can only update their own
        return $user->role === 'admin' || $incoming->user_id === $user->id;
    }

    /**
     * Determine if the user can delete the incoming record.
     *
     * @param User $user
     * @param Incoming $incoming
     * @return bool
     */
    public function delete(User $user, Incoming $incoming): bool
    {
        // Admin can delete all incoming records, users can only delete their own
        return $user->role === 'admin' || $incoming->user_id === $user->id;
    }
}
