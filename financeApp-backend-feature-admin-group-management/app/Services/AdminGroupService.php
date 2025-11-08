<?php

namespace App\Services;

use App\Models\AdminGroup;
use App\Models\User;
use App\Repositories\AdminGroupRepository;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Validation\ValidationException;

class AdminGroupService
{
    /**
     * The admin group repository instance.
     *
     * @var AdminGroupRepository
     */
    protected AdminGroupRepository $adminGroupRepository;

    /**
     * Create a new AdminGroupService instance.
     *
     * @param AdminGroupRepository $adminGroupRepository
     */
    public function __construct(AdminGroupRepository $adminGroupRepository)
    {
        $this->adminGroupRepository = $adminGroupRepository;
    }

    /**
     * Create a new admin group for an admin user during registration.
     *
     * @param User $admin
     * @param string|null $groupName
     * @return AdminGroup
     * @throws \RuntimeException
     */
    public function createGroupForAdmin(User $admin, ?string $groupName = null): AdminGroup
    {
        // Verify the user is an admin
        if (!$admin->isAdmin()) {
            throw new \InvalidArgumentException('Only admin users can have groups created for them.');
        }

        // Check if admin already has a group
        $existingGroup = $this->adminGroupRepository->findByAdmin($admin);
        if ($existingGroup) {
            return $existingGroup;
        }

        // Generate unique group code
        $groupCode = AdminGroup::generateUniqueGroupCode();

        // Create the admin group
        $adminGroup = AdminGroup::create([
            'admin_user_id' => $admin->id,
            'group_code' => $groupCode,
            'group_name' => $groupName ?? $admin->organization_name . ' - ' . $admin->name,
            'is_active' => true,
        ]);

        return $adminGroup;
    }

    /**
     * Get the admin group for an admin user.
     *
     * @param User $admin
     * @return AdminGroup|null
     */
    public function getAdminGroup(User $admin): ?AdminGroup
    {
        return $this->adminGroupRepository->findByAdmin($admin);
    }

    /**
     * Regenerate the group code for an admin's group.
     *
     * @param User $admin
     * @return AdminGroup
     * @throws ValidationException
     */
    public function regenerateGroupCode(User $admin): AdminGroup
    {
        // Get the admin's group
        $adminGroup = $this->adminGroupRepository->findByAdmin($admin);

        if (!$adminGroup) {
            throw ValidationException::withMessages([
                'admin' => ['Admin does not have a group.'],
            ]);
        }

        // Generate a new unique group code
        $newCode = AdminGroup::generateUniqueGroupCode();

        // Update the group code
        $adminGroup = $this->adminGroupRepository->updateGroupCode($adminGroup, $newCode);

        return $adminGroup;
    }

    /**
     * Join a group using a group code.
     *
     * @param User $user
     * @param string $groupCode
     * @return AdminGroup
     * @throws ValidationException
     */
    public function joinGroupByCode(User $user, string $groupCode): AdminGroup
    {
        // Regular users cannot be admins
        if ($user->isAdmin()) {
            throw ValidationException::withMessages([
                'user' => ['Admin users cannot join groups.'],
            ]);
        }

        // Check if user is already in a group
        if ($user->isGroupMember()) {
            throw ValidationException::withMessages([
                'user' => ['User already belongs to a group.'],
            ]);
        }

        // Find the admin group by code
        $adminGroup = $this->adminGroupRepository->findByGroupCode($groupCode);

        if (!$adminGroup) {
            throw ValidationException::withMessages([
                'group_code' => ['Invalid group code.'],
            ]);
        }

        // Validate organization matching
        if (!$this->validateGroupCodeForUser($user, $groupCode)) {
            throw ValidationException::withMessages([
                'organization' => ['Cannot join group from different organization.'],
            ]);
        }

        // Add user to the group
        $adminGroup->addMember($user);

        return $adminGroup;
    }

    /**
     * Validate if a user can join a group based on organization name matching.
     *
     * @param User $user
     * @param string $groupCode
     * @return bool
     */
    public function validateGroupCodeForUser(User $user, string $groupCode): bool
    {
        // Find the admin group by code
        $adminGroup = $this->adminGroupRepository->findByGroupCode($groupCode);

        if (!$adminGroup) {
            return false;
        }

        // Get the admin user
        $admin = $adminGroup->admin;

        if (!$admin) {
            return false;
        }

        // Compare organization names (case-insensitive)
        $userOrg = strtolower(trim($user->organization_name ?? ''));
        $adminOrg = strtolower(trim($admin->organization_name ?? ''));

        return $userOrg === $adminOrg;
    }

    /**
     * Get paginated list of group members for an admin.
     *
     * @param User $admin
     * @param array $filters
     * @param int $perPage
     * @return LengthAwarePaginator
     * @throws ValidationException
     */
    public function getGroupMembers(User $admin, array $filters = [], int $perPage = 15): LengthAwarePaginator
    {
        // Get the admin's group
        $adminGroup = $this->adminGroupRepository->findByAdmin($admin);

        if (!$adminGroup) {
            throw ValidationException::withMessages([
                'admin' => ['Admin does not have a group.'],
            ]);
        }

        // Get paginated group members
        return $this->adminGroupRepository->getGroupMembers($adminGroup, $filters, $perPage);
    }

    /**
     * Remove a member from an admin's group.
     *
     * @param User $admin
     * @param User $member
     * @return bool
     * @throws ValidationException
     */
    public function removeMemberFromGroup(User $admin, User $member): bool
    {
        // Get the admin's group
        $adminGroup = $this->adminGroupRepository->findByAdmin($admin);

        if (!$adminGroup) {
            throw ValidationException::withMessages([
                'admin' => ['Admin does not have a group.'],
            ]);
        }

        // Verify the member belongs to this admin's group
        if (!$adminGroup->isMember($member)) {
            throw ValidationException::withMessages([
                'member' => ['User is not a member of your group.'],
            ]);
        }

        // Remove the member from the group
        return $adminGroup->removeMember($member);
    }

    /**
     * Get available transfer recipients for an admin (users in their group).
     *
     * @param User $admin
     * @return Collection
     * @throws ValidationException
     */
    public function getAvailableTransferRecipients(User $admin): Collection
    {
        // Get the admin's group
        $adminGroup = $this->adminGroupRepository->findByAdmin($admin);

        if (!$adminGroup) {
            throw ValidationException::withMessages([
                'admin' => ['Admin does not have a group.'],
            ]);
        }

        // Return all active members in the group
        return User::where('admin_group_id', $adminGroup->id)
            ->where('role', 'user')
            ->whereNull('deleted_at')
            ->orderBy('name', 'asc')
            ->get(['id', 'name', 'email', 'department_name']);
    }
}
