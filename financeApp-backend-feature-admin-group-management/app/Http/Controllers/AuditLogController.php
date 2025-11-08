<?php

namespace App\Http\Controllers;

use App\Services\AuditLogService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AuditLogController extends Controller
{
    /**
     * Create a new AuditLogController instance.
     *
     * @param AuditLogService $auditLogService
     */
    public function __construct(
        protected AuditLogService $auditLogService
    ) {}

    /**
     * Get audit logs with filtering (admin only)
     *
     * @OA\Get(
     *     path="/api/v1/audit-logs",
     *     tags={"Audit Logs"},
     *     summary="List audit logs (Admin only)",
     *     description="Returns paginated audit logs with filtering by user, action, resource type, and date range",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(name="per_page", in="query", required=false, @OA\Schema(type="integer", default=15)),
     *     @OA\Parameter(name="user_id", in="query", required=false, @OA\Schema(type="integer")),
     *     @OA\Parameter(name="action", in="query", required=false, @OA\Schema(type="string")),
     *     @OA\Parameter(name="resource_type", in="query", required=false, @OA\Schema(type="string")),
     *     @OA\Parameter(name="created_from", in="query", required=false, @OA\Schema(type="string", format="date")),
     *     @OA\Parameter(name="created_to", in="query", required=false, @OA\Schema(type="string", format="date")),
     *     @OA\Response(
     *         response=200,
     *         description="Audit logs retrieved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="array", @OA\Items(ref="#/components/schemas/AuditLog")),
     *             @OA\Property(property="pagination", ref="#/components/schemas/PaginationMeta")
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=403, description="Forbidden - Admin only")
     * )
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function index(Request $request): JsonResponse
    {
        $filters = $request->only([
            'user_id',
            'action',
            'resource_type',
            'resource_id',
            'ip_address',
            'created_from',
            'created_to',
        ]);

        $perPage = $request->input('per_page', 15);

        $auditLogs = $this->auditLogService->getAuditLogs($filters, $perPage);

        return response()->json([
            'success' => true,
            'data' => $auditLogs->items(),
            'pagination' => [
                'current_page' => $auditLogs->currentPage(),
                'per_page' => $auditLogs->perPage(),
                'total' => $auditLogs->total(),
                'last_page' => $auditLogs->lastPage(),
            ],
        ]);
    }

    /**
     * Get a single audit log by ID
     *
     * @OA\Get(
     *     path="/api/v1/audit-logs/{id}",
     *     tags={"Audit Logs"},
     *     summary="Get single audit log (Admin only)",
     *     description="Returns a single audit log entry with user information",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="Audit log ID",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Audit log retrieved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", ref="#/components/schemas/AuditLog")
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=403, description="Forbidden - Admin only"),
     *     @OA\Response(response=404, description="Audit log not found")
     * )
     *
     * @param int $id
     * @return JsonResponse
     */
    public function show(int $id): JsonResponse
    {
        $auditLog = $this->auditLogService->getAuditLogById($id);

        if (!$auditLog) {
            return response()->json([
                'success' => false,
                'message' => 'Audit log not found',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $auditLog->load('user:id,name,email'),
        ]);
    }
}
