<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreIncomingRequest;
use App\Http\Requests\UpdateIncomingRequest;
use App\Models\Incoming;
use App\Services\AuditLogService;
use App\Services\IncomingService;
use App\Services\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class IncomingController extends Controller
{
    /**
     * Create a new IncomingController instance.
     *
     * @param IncomingService $incomingService
     * @param AuditLogService $auditLogService
     * @param NotificationService $notificationService
     */
    public function __construct(
        protected IncomingService $incomingService,
        protected AuditLogService $auditLogService,
        protected NotificationService $notificationService
    ) {}

    /**
     * Display a listing of incoming records
     *
     * @OA\Get(
     *     path="/api/v1/incoming",
     *     tags={"Incoming"},
     *     summary="List incoming funds",
     *     description="Get paginated list of incoming transactions. Regular users see only their records, admins see all.",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(name="per_page", in="query", required=false, @OA\Schema(type="integer", default=15)),
     *     @OA\Parameter(name="incoming_date_from", in="query", required=false, @OA\Schema(type="string", format="date")),
     *     @OA\Parameter(name="incoming_date_to", in="query", required=false, @OA\Schema(type="string", format="date")),
     *     @OA\Parameter(name="sync_status", in="query", required=false, @OA\Schema(type="string", enum={"pending", "syncing", "synced", "failed"})),
     *     @OA\Response(
     *         response=200,
     *         description="Incoming records retrieved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="array", @OA\Items(ref="#/components/schemas/Incoming")),
     *             @OA\Property(property="meta", ref="#/components/schemas/PaginationMeta")
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated")
     * )
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $perPage = $request->input('per_page', 15);
        
        $filters = [
            'incoming_date_from' => $request->input('incoming_date_from'),
            'incoming_date_to' => $request->input('incoming_date_to'),
            'sync_status' => $request->input('sync_status'),
            'search' => $request->input('search'),
            'amount_min' => $request->input('amount_min'),
            'amount_max' => $request->input('amount_max'),
            'sort_by' => $request->input('sort_by', 'incoming_date'),
            'sort_order' => $request->input('sort_order', 'desc'),
        ];

        // Admin-specific filter for user_id
        if ($user->role === 'admin') {
            $filters['user_id'] = $request->input('user_id');
        }

        // Use group-scoped data retrieval for both admins and regular users
        // Admins see incoming transactions from their group members, users see only their own
        $incoming = $this->incomingService->getAllIncoming($user, $filters, $perPage);

        return response()->json([
            'success' => true,
            'data' => $incoming->items(),
            'meta' => [
                'current_page' => $incoming->currentPage(),
                'last_page' => $incoming->lastPage(),
                'per_page' => $incoming->perPage(),
                'total' => $incoming->total(),
            ],
        ]);
    }

    /**
     * Store a newly created incoming record
     *
     * @OA\Post(
     *     path="/api/v1/incoming",
     *     tags={"Incoming"},
     *     summary="Create incoming record",
     *     description="Creates a new incoming funds transaction record",
     *     security={{"sanctum":{}}},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"description","amount_usd","incoming_date"},
     *             @OA\Property(property="description", type="string", example="Client payment"),
     *             @OA\Property(property="amount_usd", type="number", format="float", example=500.00),
     *             @OA\Property(property="incoming_date", type="string", format="date", example="2025-10-22"),
     *             @OA\Property(property="sync_status", type="string", enum={"pending","syncing","synced","failed"}, example="synced")
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Incoming record created successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Incoming record created successfully"),
     *             @OA\Property(property="data", ref="#/components/schemas/Incoming")
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=422, description="Validation error")
     * )
     *
     * @param StoreIncomingRequest $request
     * @return JsonResponse
     */
    public function store(StoreIncomingRequest $request): JsonResponse
    {
        try {
            $user = $request->user();
            $incoming = $this->incomingService->createIncoming($user, $request->validated());

            return response()->json([
                'success' => true,
                'message' => 'Incoming record created successfully',
                'data' => $incoming,
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to create incoming record',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Display the specified incoming record
     *
     * @OA\Get(
     *     path="/api/v1/incoming/{id}",
     *     tags={"Incoming"},
     *     summary="Get single incoming record",
     *     description="Returns a single incoming funds transaction. Users can only view their own records, admins can view all.",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="Incoming record ID",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Incoming record retrieved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", ref="#/components/schemas/Incoming")
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=403, description="Unauthorized"),
     *     @OA\Response(response=404, description="Incoming record not found")
     * )
     *
     * @param Request $request
     * @param Incoming $incoming
     * @return JsonResponse
     */
    public function show(Request $request, Incoming $incoming): JsonResponse
    {
        $user = $request->user();

        // Authorization: users can only view their own incoming records, admins can view all
        if (!Gate::allows('view', $incoming)) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized to view this incoming record',
            ], 403);
        }

        // Log admin access to other users' data
        if ($user->role === 'admin' && $incoming->user_id !== $user->id) {
            $this->auditLogService->logDataAccess($user, 'Incoming', $incoming->id);
        }

        return response()->json([
            'success' => true,
            'data' => $incoming,
        ]);
    }

    /**
     * Update the specified incoming record
     *
     * @OA\Put(
     *     path="/api/v1/incoming/{id}",
     *     tags={"Incoming"},
     *     summary="Update incoming record",
     *     description="Updates an existing incoming funds transaction. Users can only update their own records, admins can update all.",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="Incoming record ID",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             @OA\Property(property="description", type="string", example="Updated client payment"),
     *             @OA\Property(property="amount_usd", type="number", format="float", example=600.00),
     *             @OA\Property(property="incoming_date", type="string", format="date", example="2025-10-22"),
     *             @OA\Property(property="sync_status", type="string", enum={"pending","syncing","synced","failed"})
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Incoming record updated successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Incoming record updated successfully"),
     *             @OA\Property(property="data", ref="#/components/schemas/Incoming")
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=403, description="Unauthorized"),
     *     @OA\Response(response=404, description="Incoming record not found"),
     *     @OA\Response(response=422, description="Validation error")
     * )
     *
     * @param UpdateIncomingRequest $request
     * @param Incoming $incoming
     * @return JsonResponse
     */
    public function update(UpdateIncomingRequest $request, Incoming $incoming): JsonResponse
    {
        $user = $request->user();

        // Authorization: users can only update their own incoming records, admins can update all
        if (!Gate::allows('update', $incoming)) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized to update this incoming record',
            ], 403);
        }

        try {
            $updatedIncoming = $this->incomingService->updateIncoming($incoming, $request->validated());

            // Send notification if admin modified another user's data
            if ($user->role === 'admin' && $incoming->user_id !== $user->id) {
                $incomingOwner = $incoming->user;
                $this->notificationService->sendDataModificationAlert($incomingOwner, 'update', 'incoming');
            }

            return response()->json([
                'success' => true,
                'message' => 'Incoming record updated successfully',
                'data' => $updatedIncoming,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to update incoming record',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Remove the specified incoming record (soft delete)
     *
     * @OA\Delete(
     *     path="/api/v1/incoming/{id}",
     *     tags={"Incoming"},
     *     summary="Delete incoming record",
     *     description="Soft deletes an incoming funds transaction. Users can only delete their own records, admins can delete all.",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="Incoming record ID",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Incoming record deleted successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Incoming record deleted successfully")
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=403, description="Unauthorized"),
     *     @OA\Response(response=404, description="Incoming record not found")
     * )
     *
     * @param Request $request
     * @param Incoming $incoming
     * @return JsonResponse
     */
    public function destroy(Request $request, Incoming $incoming): JsonResponse
    {
        $user = $request->user();

        // Authorization: users can only delete their own incoming records, admins can delete all
        if (!Gate::allows('delete', $incoming)) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized to delete this incoming record',
            ], 403);
        }

        try {
            // Send notification if admin deleted another user's data
            if ($user->role === 'admin' && $incoming->user_id !== $user->id) {
                $incomingOwner = $incoming->user;
                $this->notificationService->sendDataModificationAlert($incomingOwner, 'delete', 'incoming');
            }

            $this->incomingService->deleteIncoming($incoming);

            return response()->json([
                'success' => true,
                'message' => 'Incoming record deleted successfully',
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete incoming record',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
