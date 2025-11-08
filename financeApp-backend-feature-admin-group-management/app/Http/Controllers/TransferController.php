<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreTransferRequest;
use App\Http\Requests\UpdateTransferRequest;
use App\Http\Requests\StoreExchangeRequest;
use App\Models\Transfer;
use App\Services\AuditLogService;
use App\Services\NotificationService;
use App\Services\TransferService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class TransferController extends Controller
{
    /**
     * Create a new TransferController instance.
     *
     * @param TransferService $transferService
     * @param AuditLogService $auditLogService
     * @param NotificationService $notificationService
     */
    public function __construct(
        protected TransferService $transferService,
        protected AuditLogService $auditLogService,
        protected NotificationService $notificationService
    ) {}

    /**
     * Display a listing of transfers
     *
     * @OA\Get(
     *     path="/api/v1/transfers",
     *     tags={"Transfers"},
     *     summary="List transfers",
     *     description="Get paginated list of transfers with optional exchange data. Regular users see only their transfers, admins see all.",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(name="per_page", in="query", required=false, @OA\Schema(type="integer", default=15)),
     *     @OA\Parameter(name="transfer_date_from", in="query", required=false, @OA\Schema(type="string", format="date")),
     *     @OA\Parameter(name="transfer_date_to", in="query", required=false, @OA\Schema(type="string", format="date")),
     *     @OA\Parameter(name="sync_status", in="query", required=false, @OA\Schema(type="string", enum={"pending", "syncing", "synced", "failed"})),
     *     @OA\Response(
     *         response=200,
     *         description="Transfers retrieved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="array", @OA\Items(ref="#/components/schemas/Transfer")),
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
            'transfer_date_from' => $request->input('transfer_date_from'),
            'transfer_date_to' => $request->input('transfer_date_to'),
            'sync_status' => $request->input('sync_status'),
            'search' => $request->input('search'),
            'amount_min' => $request->input('amount_min'),
            'amount_max' => $request->input('amount_max'),
            'sort_by' => $request->input('sort_by', 'transfer_date'),
            'sort_order' => $request->input('sort_order', 'desc'),
        ];

        // Admin-specific filter for user_id
        if ($user->role === 'admin') {
            $filters['user_id'] = $request->input('user_id');
        }

        // Use group-scoped data retrieval for both admins and regular users
        // Admins see transfers from their group members, users see only their own
        $transfers = $this->transferService->getAllTransfers($user, $filters, $perPage);

        return response()->json([
            'success' => true,
            'data' => $transfers->items(),
            'meta' => [
                'current_page' => $transfers->currentPage(),
                'last_page' => $transfers->lastPage(),
                'per_page' => $transfers->perPage(),
                'total' => $transfers->total(),
            ],
        ]);
    }

    /**
     * Store a newly created transfer
     *
     * @OA\Post(
     *     path="/api/v1/transfers",
     *     tags={"Transfers"},
     *     summary="Create transfer",
     *     description="Creates a new transfer record with optional currency exchange information",
     *     security={{"sanctum":{}}},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"recipient_name","amount_usd","transfer_date"},
     *             @OA\Property(property="recipient_name", type="string", example="Jane Smith"),
     *             @OA\Property(property="amount_usd", type="number", format="float", example=100.00),
     *             @OA\Property(property="transfer_date", type="string", format="date", example="2025-10-22"),
     *             @OA\Property(property="notes", type="string", example="Monthly payment", nullable=true),
     *             @OA\Property(property="sync_status", type="string", enum={"pending","syncing","synced","failed"}, example="synced")
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Transfer created successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Transfer created successfully"),
     *             @OA\Property(property="data", ref="#/components/schemas/Transfer")
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=422, description="Validation error")
     * )
     *
     * @param StoreTransferRequest $request
     * @return JsonResponse
     */
    public function store(StoreTransferRequest $request): JsonResponse
    {
        try {
            $user = $request->user();
            $transfer = $this->transferService->createTransfer($user, $request->validated());

            return response()->json([
                'success' => true,
                'message' => 'Transfer created successfully',
                'data' => $transfer,
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to create transfer',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Display the specified transfer
     *
     * @OA\Get(
     *     path="/api/v1/transfers/{id}",
     *     tags={"Transfers"},
     *     summary="Get single transfer",
     *     description="Returns a single transfer record with exchange data. Users can only view their own transfers, admins can view all.",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="Transfer ID",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Transfer retrieved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", ref="#/components/schemas/Transfer")
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=403, description="Unauthorized"),
     *     @OA\Response(response=404, description="Transfer not found")
     * )
     *
     * @param Request $request
     * @param Transfer $transfer
     * @return JsonResponse
     */
    public function show(Request $request, Transfer $transfer): JsonResponse
    {
        $user = $request->user();

        // Authorization: users can only view their own transfers, admins can view all
        if (!Gate::allows('view', $transfer)) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized to view this transfer',
            ], 403);
        }

        // Log admin access to other users' data
        if ($user->role === 'admin' && $transfer->user_id !== $user->id) {
            $this->auditLogService->logDataAccess($user, 'Transfer', $transfer->id);
        }

        // Load exchange data
        $transfer->load('exchange');

        return response()->json([
            'success' => true,
            'data' => $transfer,
        ]);
    }

    /**
     * Update the specified transfer
     *
     * @OA\Put(
     *     path="/api/v1/transfers/{id}",
     *     tags={"Transfers"},
     *     summary="Update transfer",
     *     description="Updates an existing transfer record. Users can only update their own transfers, admins can update all.",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="Transfer ID",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             @OA\Property(property="recipient_name", type="string", example="Jane Smith"),
     *             @OA\Property(property="amount_usd", type="number", format="float", example=150.00),
     *             @OA\Property(property="transfer_date", type="string", format="date", example="2025-10-22"),
     *             @OA\Property(property="notes", type="string", example="Updated payment", nullable=true),
     *             @OA\Property(property="sync_status", type="string", enum={"pending","syncing","synced","failed"})
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Transfer updated successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Transfer updated successfully"),
     *             @OA\Property(property="data", ref="#/components/schemas/Transfer")
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=403, description="Unauthorized"),
     *     @OA\Response(response=404, description="Transfer not found"),
     *     @OA\Response(response=422, description="Validation error")
     * )
     *
     * @param UpdateTransferRequest $request
     * @param Transfer $transfer
     * @return JsonResponse
     */
    public function update(UpdateTransferRequest $request, Transfer $transfer): JsonResponse
    {
        $user = $request->user();

        // Authorization: users can only update their own transfers, admins can update all
        if (!Gate::allows('update', $transfer)) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized to update this transfer',
            ], 403);
        }

        try {
            $updatedTransfer = $this->transferService->updateTransfer($transfer, $request->validated());

            // Send notification if admin modified another user's data
            if ($user->role === 'admin' && $transfer->user_id !== $user->id) {
                $transferOwner = $transfer->user;
                $this->notificationService->sendDataModificationAlert($transferOwner, 'update', 'transfer');
            }

            return response()->json([
                'success' => true,
                'message' => 'Transfer updated successfully',
                'data' => $updatedTransfer,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to update transfer',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Remove the specified transfer (soft delete)
     *
     * @OA\Delete(
     *     path="/api/v1/transfers/{id}",
     *     tags={"Transfers"},
     *     summary="Delete transfer",
     *     description="Soft deletes a transfer record. Users can only delete their own transfers, admins can delete all.",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="Transfer ID",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Transfer deleted successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Transfer deleted successfully")
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=403, description="Unauthorized"),
     *     @OA\Response(response=404, description="Transfer not found")
     * )
     *
     * @param Request $request
     * @param Transfer $transfer
     * @return JsonResponse
     */
    public function destroy(Request $request, Transfer $transfer): JsonResponse
    {
        $user = $request->user();

        // Authorization: users can only delete their own transfers, admins can delete all
        if (!Gate::allows('delete', $transfer)) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized to delete this transfer',
            ], 403);
        }

        try {
            // Send notification if admin deleted another user's data
            if ($user->role === 'admin' && $transfer->user_id !== $user->id) {
                $transferOwner = $transfer->user;
                $this->notificationService->sendDataModificationAlert($transferOwner, 'delete', 'transfer');
            }

            $this->transferService->deleteTransfer($transfer);

            return response()->json([
                'success' => true,
                'message' => 'Transfer deleted successfully',
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete transfer',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Add exchange data to a transfer
     *
     * @OA\Post(
     *     path="/api/v1/transfers/{id}/exchange",
     *     tags={"Transfers"},
     *     summary="Add exchange to transfer",
     *     description="Links currency exchange data to a transfer record with exchange rate snapshots",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="Transfer ID",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"exchange_date"},
     *             @OA\Property(property="converted_amount_syp", type="number", format="float", example=250000.00, nullable=true),
     *             @OA\Property(property="converted_amount_try", type="number", format="float", example=3000.00, nullable=true),
     *             @OA\Property(property="exchange_rate_usd_to_syp", type="number", format="float", example=2500.00, nullable=true),
     *             @OA\Property(property="exchange_rate_usd_to_try", type="number", format="float", example=30.00, nullable=true),
     *             @OA\Property(property="exchange_date", type="string", format="date", example="2025-10-22")
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Exchange added successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Exchange added successfully"),
     *             @OA\Property(property="data", ref="#/components/schemas/Exchange")
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=403, description="Unauthorized"),
     *     @OA\Response(response=404, description="Transfer not found"),
     *     @OA\Response(response=422, description="Validation error or exchange already exists")
     * )
     *
     * @param StoreExchangeRequest $request
     * @param Transfer $transfer
     * @return JsonResponse
     */
    public function addExchange(StoreExchangeRequest $request, Transfer $transfer): JsonResponse
    {
        // Authorization: users can only add exchange to their own transfers, admins can add to all
        if (!Gate::allows('update', $transfer)) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized to add exchange to this transfer',
            ], 403);
        }

        // Check if exchange already exists
        if ($transfer->exchange) {
            return response()->json([
                'success' => false,
                'message' => 'Exchange data already exists for this transfer. Use update endpoint instead.',
            ], 422);
        }

        try {
            $exchange = $this->transferService->addExchange($transfer, $request->validated());

            return response()->json([
                'success' => true,
                'message' => 'Exchange added successfully',
                'data' => $exchange,
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to add exchange',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
