<?php

namespace App\Observers;

use App\Models\User;
use App\Services\CacheService;

class UserObserver
{
    /**
     * Create a new UserObserver instance.
     *
     * @param CacheService $cacheService
     */
    public function __construct(
        protected CacheService $cacheService
    ) {}

    /**
     * Handle the User "created" event.
     *
     * @param User $user
     * @return void
     */
    public function created(User $user): void
    {
        // Invalidate user-related caches
        $this->cacheService->invalidateUserCache($user->id);
    }

    /**
     * Handle the User "updated" event.
     *
     * @param User $user
     * @return void
     */
    public function updated(User $user): void
    {
        // Invalidate user-related caches, especially if role changed
        $this->cacheService->invalidateUserCache($user->id);
    }

    /**
     * Handle the User "deleted" event.
     *
     * @param User $user
     * @return void
     */
    public function deleted(User $user): void
    {
        // Invalidate user-related caches
        $this->cacheService->invalidateUserCache($user->id);
    }

    /**
     * Handle the User "restored" event.
     *
     * @param User $user
     * @return void
     */
    public function restored(User $user): void
    {
        // Invalidate user-related caches
        $this->cacheService->invalidateUserCache($user->id);
    }
}
