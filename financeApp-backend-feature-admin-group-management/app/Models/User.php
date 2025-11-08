<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use App\Notifications\ResetPasswordNotification;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'organization_id',
        'department_id',
        'organization_name',
        'department_name',
        'admin_group_id',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    /**
     * Check if the user is an admin.
     *
     * @return bool
     */
    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    /**
     * Check if the user is a regular user.
     *
     * @return bool
     */
    public function isUser(): bool
    {
        return $this->role === 'user';
    }

    /**
     * Get cached user role.
     *
     * @return string
     */
    public function getCachedRole(): string
    {
        return app(\App\Services\CacheService::class)->cacheUserRole(
            $this->id,
            fn() => $this->role
        );
    }

    /**
     * Get cached user permissions (role-based).
     *
     * @return array
     */
    public function getCachedPermissions(): array
    {
        return app(\App\Services\CacheService::class)->cacheUserPermissions(
            $this->id,
            function () {
                // Define permissions based on role
                return match ($this->role) {
                    'admin' => [
                        'manage_users',
                        'view_dashboard',
                        'manage_expenses',
                        'manage_transfers',
                        'manage_incoming',
                        'manage_fund_box',
                        'view_audit_logs',
                        'export_data',
                    ],
                    'user' => [
                        'manage_expenses',
                        'manage_transfers',
                        'manage_incoming',
                        'view_own_data',
                    ],
                    default => [],
                };
            }
        );
    }

    /**
     * Send the password reset notification.
     *
     * @param string $token
     * @return void
     */
    public function sendPasswordResetNotification($token): void
    {
        $this->notify(new ResetPasswordNotification($token));
    }

    /**
     * Get the user's expenses.
     */
    public function expenses()
    {
        return $this->hasMany(Expense::class);
    }

    /**
     * Get the user's transfers.
     */
    public function transfers()
    {
        return $this->hasMany(Transfer::class);
    }

    /**
     * Get the user's incoming transactions.
     */
    public function incoming()
    {
        return $this->hasMany(Incoming::class);
    }

    /**
     * Get the user's fund box.
     */
    public function fundBox()
    {
        return $this->hasOne(FundBox::class);
    }

    /**
     * Get the organization that owns the user.
     */
    public function organization()
    {
        return $this->belongsTo(Organization::class);
    }

    /**
     * Get the department that owns the user.
     */
    public function department()
    {
        return $this->belongsTo(Department::class);
    }

    /**
     * Get the admin group that the user belongs to (for regular users).
     */
    public function adminGroup()
    {
        return $this->belongsTo(AdminGroup::class, 'admin_group_id');
    }

    /**
     * Get the admin group managed by this user (for admin users).
     */
    public function managedGroup()
    {
        return $this->hasOne(AdminGroup::class, 'admin_user_id');
    }

    /**
     * Check if the user is a member of an admin group.
     *
     * @return bool
     */
    public function isGroupMember(): bool
    {
        return $this->admin_group_id !== null;
    }

    /**
     * Get the admin of the user's group.
     *
     * @return User|null
     */
    public function getGroupAdmin(): ?User
    {
        if (!$this->isGroupMember()) {
            return null;
        }

        return $this->adminGroup?->admin;
    }

    /**
     * Check if the current user can access another user's data.
     *
     * @param User $user
     * @return bool
     */
    public function canAccessUser(User $user): bool
    {
        // Users can always access their own data
        if ($this->id === $user->id) {
            return true;
        }

        // Admins can access data of users in their group
        if ($this->isAdmin() && $this->managedGroup) {
            return $user->admin_group_id === $this->managedGroup->id;
        }

        // Regular users cannot access other users' data
        return false;
    }
}
