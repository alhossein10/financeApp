<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class AdminGroup extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'admin_user_id',
        'group_code',
        'group_name',
        'is_active',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'is_active' => 'boolean',
    ];

    /**
     * Get the admin user that owns the group.
     */
    public function admin()
    {
        return $this->belongsTo(User::class, 'admin_user_id');
    }

    /**
     * Get the members of the group.
     */
    public function members()
    {
        return $this->hasMany(User::class, 'admin_group_id');
    }

    /**
     * Generate a unique group code.
     *
     * @param int $length The length of the group code (4-6 digits)
     * @return string
     */
    public static function generateUniqueGroupCode(int $length = 6): string
    {
        $maxAttempts = 10;
        $attempts = 0;

        do {
            // Generate a random numeric code using secure random generation
            $code = '';
            for ($i = 0; $i < $length; $i++) {
                $code .= random_int(0, 9);
            }

            // Check if the code is unique
            $exists = self::where('group_code', $code)->exists();
            $attempts++;

            if (!$exists) {
                return $code;
            }
        } while ($attempts < $maxAttempts);

        // If we couldn't generate a unique code after max attempts, throw an exception
        throw new \RuntimeException('Failed to generate unique group code after ' . $maxAttempts . ' attempts');
    }

    /**
     * Regenerate the group code for this admin group.
     *
     * @return bool
     */
    public function regenerateGroupCode(): bool
    {
        $newCode = self::generateUniqueGroupCode();
        $this->group_code = $newCode;
        return $this->save();
    }

    /**
     * Add a user to the group.
     *
     * @param User $user
     * @return bool
     */
    public function addMember(User $user): bool
    {
        $user->admin_group_id = $this->id;
        return $user->save();
    }

    /**
     * Remove a user from the group.
     *
     * @param User $user
     * @return bool
     */
    public function removeMember(User $user): bool
    {
        $user->admin_group_id = null;
        return $user->save();
    }

    /**
     * Check if a user is a member of this group.
     *
     * @param User $user
     * @return bool
     */
    public function isMember(User $user): bool
    {
        return $user->admin_group_id === $this->id;
    }
}
