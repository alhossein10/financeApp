<?php

namespace App\Http\Controllers;

use App\Services\SyncService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class SyncController extends Controller
{
    protected SyncService $syncService;

    public function __construct(SyncService $syncService)
    {
        $this->syncService = $syncService;
    }

    /**
     * Process batch sync for multiple records
     *
     * @OA\Post(
     *     path="/api/v1/sync/batch",
     *     tags={"Sync"},
     *     summary="Batch sync multiple records",
     *     description="Process multiple create, update, or delete operations in a single request with individual success/failure tracking",
     *     security={{"sanctum":{}}},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"records"},
     *             @OA\Property(property="records", type="array",
     *                 @OA\Items(
     *                     type="object",
     *                     required={"resource_type","action"},
     *                     @OA\Property(property="resource_type", type="string", enum={"expense","transfer","incoming"}, example="expense"),
     *                     @OA\Property(property="action", type="string", enum={"create","update","delete"}, example="create"),
     *                     @OA\Property(property="data", type="object", description="Required for create/update"),
     *                     @OA\Property(property="id", type="integer", description="Required for update/delete", example=1),
     *                     @OA\Property(property="client_id", type="string", example="client-uuid-123")
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Batch sync processed",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Batch sync completed: 5 succeeded, 0 failed"),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="results", type="array", @OA\Items(type="object")),
     *                 @OA\Property(property="summary", type="object",
     *                     @OA\Property(property="total", type="integer", example=5),
     *                     @OA\Property(property="succeeded", type="integer", example=5),
     *                     @OA\Property(property="failed", type="integer", example=0)
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=422, description="Validation error")
     * )
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function batchSync(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'records' => 'required|array',
            'records.*.resource_type' => 'required|string|in:expense,transfer,incoming',
            'records.*.action' => 'required|string|in:create,update,delete',
            'records.*.data' => 'required_if:records.*.action,create,update|array',
            'records.*.id' => 'required_if:records.*.action,update,delete|integer',
            'records.*.client_id' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $results = $this->syncService->batchSync($user, $request->input('records'));

        $successCount = collect($results)->where('success', true)->count();
        $failureCount = collect($results)->where('success', false)->count();

        return response()->json([
            'success' => true,
            'message' => "Batch sync completed: {$successCount} succeeded, {$failureCount} failed",
            'results' => $results,
            'summary' => [
                'total' => count($results),
                'succeeded' => $successCount,
                'failed' => $failureCount,
            ],
        ], 200);
    }

    /**
     * Get changes since a specific timestamp
     *
     * @OA\Get(
     *     path="/api/v1/sync/changes",
     *     tags={"Sync"},
     *     summary="Get changes since timestamp",
     *     description="Returns all records modified after a specific timestamp for synchronization",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(
     *         name="since",
     *         in="query",
     *         required=true,
     *         description="Timestamp to get changes since",
     *         @OA\Schema(type="string", format="date-time", example="2025-10-20T10:00:00Z")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Changes retrieved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="expenses", type="array", @OA\Items(ref="#/components/schemas/Expense")),
     *                 @OA\Property(property="transfers", type="array", @OA\Items(ref="#/components/schemas/Transfer")),
     *                 @OA\Property(property="incoming", type="array", @OA\Items(ref="#/components/schemas/Incoming"))
     *             )
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=422, description="Validation error")
     * )
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function getChanges(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'since' => 'required|date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $since = Carbon::parse($request->input('since'));

        $changes = $this->syncService->getChangesSince($user, $since);

        return response()->json([
            'success' => true,
            'data' => $changes,
        ], 200);
    }

    /**
     * Resolve sync conflict
     *
     * @OA\Post(
     *     path="/api/v1/sync/resolve",
     *     tags={"Sync"},
     *     summary="Resolve sync conflict",
     *     description="Resolves data synchronization conflicts using specified strategy (server_wins, client_wins, merge, newest_wins)",
     *     security={{"sanctum":{}}},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"strategy","client_data","server_data"},
     *             @OA\Property(property="strategy", type="string", enum={"server_wins","client_wins","merge","newest_wins"}, example="newest_wins"),
     *             @OA\Property(property="client_data", type="object", description="Client version of the data"),
     *             @OA\Property(property="server_data", type="object", description="Server version of the data")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Conflict resolved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Conflict resolved"),
     *             @OA\Property(property="data", type="object", description="Resolved data")
     *         )
     *     ),
     *     @OA\Response(response=400, description="Failed to resolve conflict"),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=422, description="Validation error")
     * )
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function resolveConflict(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'strategy' => 'required|string|in:server_wins,client_wins,merge,newest_wins',
            'client_data' => 'required|array',
            'server_data' => 'required|array',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $resolved = $this->syncService->resolveConflict(
                $request->input('strategy'),
                $request->input('client_data'),
                $request->input('server_data')
            );

            return response()->json([
                'success' => true,
                'message' => 'Conflict resolved',
                'data' => $resolved,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to resolve conflict',
                'error' => $e->getMessage(),
            ], 400);
        }
    }
}
