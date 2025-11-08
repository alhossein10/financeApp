<?php

namespace App\Services;

use App\Models\User;
use App\Notifications\WelcomeNotification;
use App\Notifications\DataModificationNotification;
use App\Notifications\SyncFailureNotification;
use Illuminate\Support\Facades\Log;

class NotificationService
{
    /**
     * Send welcome email to newly registered user.
     *
     * @param User $user
     * @return void
     */
    public function sendWelcomeEmail(User $user): void
    {
        try {
            $user->notify(new WelcomeNotification());
            Log::info('Welcome email sent', ['user_id' => $user->id, 'email' => $user->email]);
        } catch (\Exception $e) {
            Log::error('Failed to send welcome email', [
                'user_id' => $user->id,
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Send password reset email to user.
     * Note: This is handled by AuthService using ResetPasswordNotification.
     *
     * @param User $user
     * @param string $token
     * @return void
     */
    public function sendPasswordResetEmail(User $user, string $token): void
    {
        // This method is kept for interface consistency
        // The actual implementation is in AuthService using User::sendPasswordResetNotification()
        Log::info('Password reset email triggered', ['user_id' => $user->id, 'email' => $user->email]);
    }

    /**
     * Send data modification alert to user when admin modifies their data.
     *
     * @param User $user
     * @param string $action
     * @param string $resource
     * @return void
     */
    public function sendDataModificationAlert(User $user, string $action, string $resource): void
    {
        try {
            $user->notify(new DataModificationNotification($action, $resource));
            Log::info('Data modification alert sent', [
                'user_id' => $user->id,
                'action' => $action,
                'resource' => $resource,
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to send data modification alert', [
                'user_id' => $user->id,
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Send sync failure alert when sync fails repeatedly.
     *
     * @param User $user
     * @param int $retryCount
     * @return void
     */
    public function sendSyncFailureAlert(User $user, int $retryCount): void
    {
        try {
            $user->notify(new SyncFailureNotification($retryCount));
            Log::info('Sync failure alert sent', [
                'user_id' => $user->id,
                'retry_count' => $retryCount,
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to send sync failure alert', [
                'user_id' => $user->id,
                'error' => $e->getMessage(),
            ]);
        }
    }
}
