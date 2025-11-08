<?php

namespace App\Http\Controllers;

use App\Services\AdminGroupService;
use App\Http\Requests\JoinGroupRequest;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class AdminGroupController extends Controller
{
    protected AdminGroupService $adminGroupService;

    public function __construct(AdminGroupService $adminGroupService)
    {
        $this->adminGroupService = $adminGroupService;
    }

    /**
     * Get admin's group information and code
     *
     * @OA\Get(
     *     path="/api/v1/admin/group",
     *     tags={"Admin Group Management"},
     *     summary="Get admin's group information",
     *     description="Returns the authenticated admin's group information including group code",
     *     security={{"sanctum":{}}},
     *     @OA\Response(
     *         response=200,
     *         description="Group information retrieved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Group information retrieved successfully."),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="group", type="object",
     *                     @OA\Property(property="id", type="integer", example=1),
     *                     @OA\Property(property="admin_user_id", type="integer", example=1),
     *                     @OA\Property(property="group_code", type="string", example="123456"),
     *                     @OA\Property(property="group_name", type="string", example="Acme Corp - John Doe"),
     *                     @OA\Property(property="is_active", type="boolean", example=true),
     *                     @OA\Property(property="created_at", type="string", format="date-time"),
     *                     @OA\Property(property="updated_at", type="string", format="date-time")
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Admin does not have a group",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=false),
     *             @OA\Property(property="message", type="string", example="Admin does not have a group.")
     *         )
     *     ),
     *     @OA\Response(
     *         response=401,
     *         description="Unauthenticated"
     *     )
     * )
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function getAdminGroup(Request $request): JsonResponse
    {
        try {
            $admin = $request->user();
            $group = $this->adminGroupService->getAdminGroup($admin);

            if (!$group) {
                return response()->json([
                    'success' => false,
                    'message' => 'Admin does not have a group.',
                ], 404);
            }

            return response()->json([
                'success' => true,
                'message' => 'Group information retrieved successfully.',
                'data' => [
                    'group' => $group,
                ],
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve group information.',
                'errors' => ['error' => [$e->getMessage()]],
            ], 500);
        }
    }

    /**
     * Regenerate admin's group code
     *
     * @OA\Post(
     *     path="/api/v1/admin/group/regenerate",
     *     tags={"Admin Group Management"},
     *     summary="Regenerate admin's group code",
     *     description="Generates a new unique group code for the authenticated admin",
     *     security={{"sanctum":{}}},
     *     @OA\Response(
     *         response=200,
     *         description="Group code regenerated successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Group code regenerated successfully."),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="group", type="object",
     *                     @OA\Property(property="id", type="integer", example=1),
     *                     @OA\Property(property="admin_user_id", type="integer", example=1),
     *                     @OA\Property(property="group_code", type="string", example="654321"),
     *                     @OA\Property(property="group_name", type="string", example="Acme Corp - John Doe"),
     *                     @OA\Property(property="is_active", type="boolean", example=true),
     *                     @OA\Property(property="created_at", type="string", format="date-time"),
     *                     @OA\Property(property="updated_at", type="string", format="date-time")
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Admin does not have a group",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=false),
     *             @OA\Property(property="message", type="string", example="Failed to regenerate group code.")
     *         )
     *     ),
     *     @OA\Response(
     *         response=401,
     *         description="Unauthenticated"
     *     )
     * )
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function regenerateGroupCode(Request $request): JsonResponse
    {
        try {
            $admin = $request->user();
            $group = $this->adminGroupService->regenerateGroupCode($admin);

            return response()->json([
                'success' => true,
                'message' => 'Group code regenerated successfully.',
                'data' => [
                    'group' => $group,
                ],
            ], 200);
        } catch (ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to regenerate group code.',
                'errors' => $e->errors(),
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to regenerate group code.',
                'errors' => ['error' => [$e->getMessage()]],
            ], 500);
        }
    }

    /**
     * Get paginated list of group members
     *
     * @OA\Get(
     *     path="/api/v1/admin/group/members",
     *     tags={"Admin Group Management"},
     *     summary="Get group members",
     *     description="Returns paginated list of users in the authenticated admin's group",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(
     *         name="page",
     *         in="query",
     *         description="Page number",
     *         required=false,
     *         @OA\Schema(type="integer", example=1)
     *     ),
     *     @OA\Parameter(
     *         name="per_page",
     *         in="query",
     *         description="Items per page",
     *         required=false,
     *         @OA\Schema(type="integer", example=15)
     *     ),
     *     @OA\Parameter(
     *         name="search",
     *         in="query",
     *         description="Search by name or email",
     *         required=false,
     *         @OA\Schema(type="string")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Group members retrieved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Group members retrieved successfully."),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="members", type="object",
     *                     @OA\Property(property="current_page", type="integer", example=1),
     *                     @OA\Property(property="data", type="array",
     *                         @OA\Items(type="object",
     *                             @OA\Property(property="id", type="integer", example=2),
     *                             @OA\Property(property="name", type="string", example="Jane Smith"),
     *                             @OA\Property(property="email", type="string", example="jane@example.com"),
     *                             @OA\Property(property="organization_name", type="string", example="Acme Corp"),
     *                             @OA\Property(property="department_name", type="string", example="Finance"),
     *                             @OA\Property(property="created_at", type="string", format="date-time")
     *                         )
     *                     ),
     *                     @OA\Property(property="per_page", type="integer", example=15),
     *                     @OA\Property(property="total", type="integer", example=50)
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Admin does not have a group",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=false),
     *             @OA\Property(property="message", type="string", example="Failed to retrieve group members.")
     *         )
     *     ),
     *     @OA\Response(
     *         response=401,
     *         description="Unauthenticated"
     *     )
     * )
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function getGroupMembers(Request $request): JsonResponse
    {
        try {
            $admin = $request->user();
            $perPage = $request->input('per_page', 15);
            $filters = $request->only(['search']);

            $members = $this->adminGroupService->getGroupMembers($admin, $filters, $perPage);

            return response()->json([
                'success' => true,
                'message' => 'Group members retrieved successfully.',
                'data' => [
                    'members' => $members,
                ],
            ], 200);
        } catch (ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve group members.',
                'errors' => $e->errors(),
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve group members.',
                'errors' => ['error' => [$e->getMessage()]],
            ], 500);
        }
    }

    /**
     * Remove a member from the admin's group
     *
     * @OA\Delete(
     *     path="/api/v1/admin/group/members/{id}",
     *     tags={"Admin Group Management"},
     *     summary="Remove member from group",
     *     description="Removes a user from the authenticated admin's group",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         description="User ID to remove",
     *         required=true,
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Member removed successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Member removed from group successfully.")
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="User not found or not in group",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=false),
     *             @OA\Property(property="message", type="string", example="Failed to remove member from group.")
     *         )
     *     ),
     *     @OA\Response(
     *         response=401,
     *         description="Unauthenticated"
     *     )
     * )
     *
     * @param Request $request
     * @param int $id
     * @return JsonResponse
     */
    public function removeMember(Request $request, int $id): JsonResponse
    {
        try {
            $admin = $request->user();
            $member = User::findOrFail($id);

            $this->adminGroupService->removeMemberFromGroup($admin, $member);

            return response()->json([
                'success' => true,
                'message' => 'Member removed from group successfully.',
            ], 200);
        } catch (ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to remove member from group.',
                'errors' => $e->errors(),
            ], 404);
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'User not found.',
                'errors' => ['user' => ['User not found.']],
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to remove member from group.',
                'errors' => ['error' => [$e->getMessage()]],
            ], 500);
        }
    }

    /**
     * Join a group using a group code
     *
     * @OA\Post(
     *     path="/api/v1/user/join-group",
     *     tags={"User Group Management"},
     *     summary="Join a group using code",
     *     description="Allows a regular user to join an admin's group using a group code",
     *     security={{"sanctum":{}}},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"group_code"},
     *             @OA\Property(property="group_code", type="string", example="123456", minLength=4, maxLength=6)
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Successfully joined group",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Successfully joined group."),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="group", type="object",
     *                     @OA\Property(property="id", type="integer", example=1),
     *                     @OA\Property(property="group_name", type="string", example="Acme Corp - John Doe"),
     *                     @OA\Property(property="admin", type="object",
     *                         @OA\Property(property="id", type="integer", example=1),
     *                         @OA\Property(property="name", type="string", example="John Doe"),
     *                         @OA\Property(property="email", type="string", example="john@example.com")
     *                     )
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="Cannot join group (organization mismatch or already in group)",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=false),
     *             @OA\Property(property="message", type="string", example="Failed to join group.")
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Invalid group code",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=false),
     *             @OA\Property(property="message", type="string", example="Failed to join group.")
     *         )
     *     ),
     *     @OA\Response(
     *         response=401,
     *         description="Unauthenticated"
     *     )
     * )
     *
     * @param JoinGroupRequest $request
     * @return JsonResponse
     */
    public function joinGroup(JoinGroupRequest $request): JsonResponse
    {
        try {
            $user = $request->user();
            $groupCode = $request->validated()['group_code'];

            $group = $this->adminGroupService->joinGroupByCode($user, $groupCode);

            // Load admin relationship
            $group->load('admin:id,name,email');

            return response()->json([
                'success' => true,
                'message' => 'Successfully joined group.',
                'data' => [
                    'group' => [
                        'id' => $group->id,
                        'group_name' => $group->group_name,
                        'admin' => $group->admin,
                    ],
                ],
            ], 200);
        } catch (ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to join group.',
                'errors' => $e->errors(),
            ], 403);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to join group.',
                'errors' => ['error' => [$e->getMessage()]],
            ], 500);
        }
    }

    /**
     * Get current user's group information
     *
     * @OA\Get(
     *     path="/api/v1/user/group-info",
     *     tags={"User Group Management"},
     *     summary="Get user's group information",
     *     description="Returns the authenticated user's group information",
     *     security={{"sanctum":{}}},
     *     @OA\Response(
     *         response=200,
     *         description="Group information retrieved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Group information retrieved successfully."),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="group", type="object",
     *                     @OA\Property(property="id", type="integer", example=1),
     *                     @OA\Property(property="group_name", type="string", example="Acme Corp - John Doe"),
     *                     @OA\Property(property="admin", type="object",
     *                         @OA\Property(property="id", type="integer", example=1),
     *                         @OA\Property(property="name", type="string", example="John Doe"),
     *                         @OA\Property(property="email", type="string", example="john@example.com")
     *                     )
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="User is not in a group",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=false),
     *             @OA\Property(property="message", type="string", example="User is not in a group.")
     *         )
     *     ),
     *     @OA\Response(
     *         response=401,
     *         description="Unauthenticated"
     *     )
     * )
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function getGroupInfo(Request $request): JsonResponse
    {
        try {
            $user = $request->user();

            if (!$user->isGroupMember()) {
                return response()->json([
                    'success' => false,
                    'message' => 'User is not in a group.',
                ], 404);
            }

            // Load the admin group with admin relationship
            $group = $user->adminGroup()->with('admin:id,name,email')->first();

            if (!$group) {
                return response()->json([
                    'success' => false,
                    'message' => 'User is not in a group.',
                ], 404);
            }

            return response()->json([
                'success' => true,
                'message' => 'Group information retrieved successfully.',
                'data' => [
                    'group' => [
                        'id' => $group->id,
                        'group_name' => $group->group_name,
                        'admin' => $group->admin,
                    ],
                ],
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve group information.',
                'errors' => ['error' => [$e->getMessage()]],
            ], 500);
        }
    }
}
