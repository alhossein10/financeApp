<?php

namespace App\Http\Controllers;

use App\Services\AdminDashboardService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminDashboardController extends Controller
{
    /**
     * Create a new AdminDashboardController instance.
     *
     * @param AdminDashboardService $adminDashboardService
     */
    public function __construct(
        protected AdminDashboardService $adminDashboardService
    ) {}

    /**
     * Get overall system statistics
     *
     * @OA\Get(
     *     path="/api/v1/admin/dashboard/stats",
     *     tags={"Admin Dashboard"},
     *     summary="Get overall statistics (Admin only)",
     *     description="Returns total counts of users, expenses, transfers, incoming transactions, and fund box balance",
     *     security={{"sanctum":{}}},
     *     @OA\Response(
     *         response=200,
     *         description="Statistics retrieved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="total_users", type="integer", example=50),
     *                 @OA\Property(property="total_expenses", type="integer", example=1250),
     *                 @OA\Property(property="total_transfers", type="integer", example=320),
     *                 @OA\Property(property="total_incoming", type="integer", example=180),
     *                 @OA\Property(property="fund_box_balance", type="number", format="float", example=50000.00)
     *             )
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=403, description="Forbidden - Admin only")
     * )
     *
     * @return JsonResponse
     */
    public function stats(): JsonResponse
    {
        $stats = $this->adminDashboardService->getOverallStats();

        return response()->json([
            'success' => true,
            'data' => $stats,
        ]);
    }

    /**
     * Get user activity list
     *
     * @OA\Get(
     *     path="/api/v1/admin/dashboard/users",
     *     tags={"Admin Dashboard"},
     *     summary="Get user activity list (Admin only)",
     *     description="Returns a list of all users with their transaction counts and last activity timestamps",
     *     security={{"sanctum":{}}},
     *     @OA\Response(
     *         response=200,
     *         description="User activity list retrieved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="array",
     *                 @OA\Items(
     *                     type="object",
     *                     @OA\Property(property="id", type="integer", example=1),
     *                     @OA\Property(property="name", type="string", example="John Doe"),
     *                     @OA\Property(property="email", type="string", example="john@example.com"),
     *                     @OA\Property(property="expenses_count", type="integer", example=25),
     *                     @OA\Property(property="transfers_count", type="integer", example=10),
     *                     @OA\Property(property="incoming_count", type="integer", example=5),
     *                     @OA\Property(property="last_activity", type="string", format="date-time")
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=403, description="Forbidden - Admin only")
     * )
     *
     * @return JsonResponse
     */
    public function users(): JsonResponse
    {
        $users = $this->adminDashboardService->getUserActivityList();

        return response()->json([
            'success' => true,
            'data' => $users,
        ]);
    }

    /**
     * Get expense summaries
     *
     * @OA\Get(
     *     path="/api/v1/admin/dashboard/expenses",
     *     tags={"Admin Dashboard"},
     *     summary="Get expense summaries (Admin only)",
     *     description="Returns expense totals by currency and by user with optional date range filtering",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(name="start_date", in="query", required=false, @OA\Schema(type="string", format="date")),
     *     @OA\Parameter(name="end_date", in="query", required=false, @OA\Schema(type="string", format="date")),
     *     @OA\Response(
     *         response=200,
     *         description="Expense summaries retrieved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="by_currency", type="object",
     *                     @OA\Property(property="total_usd", type="number", format="float", example=5000.00),
     *                     @OA\Property(property="total_syp", type="number", format="float", example=12500000.00),
     *                     @OA\Property(property="total_try", type="number", format="float", example=150000.00)
     *                 ),
     *                 @OA\Property(property="by_user", type="array",
     *                     @OA\Items(
     *                         type="object",
     *                         @OA\Property(property="user_id", type="integer", example=1),
     *                         @OA\Property(property="user_name", type="string", example="John Doe"),
     *                         @OA\Property(property="total_expenses", type="integer", example=25),
     *                         @OA\Property(property="total_amount_usd", type="number", format="float", example=1250.00)
     *                     )
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=403, description="Forbidden - Admin only")
     * )
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function expenses(Request $request): JsonResponse
    {
        $filters = $request->only(['start_date', 'end_date']);
        
        $summaries = $this->adminDashboardService->getExpenseSummaries($filters);

        return response()->json([
            'success' => true,
            'data' => $summaries,
        ]);
    }

    /**
     * Get analytics with date range filtering
     *
     * @OA\Get(
     *     path="/api/v1/admin/dashboard/analytics",
     *     tags={"Admin Dashboard"},
     *     summary="Get analytics (Admin only)",
     *     description="Returns aggregated analytics data for a specified date range including expenses, transfers, and incoming transactions",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(name="start_date", in="query", required=true, @OA\Schema(type="string", format="date", example="2025-01-01")),
     *     @OA\Parameter(name="end_date", in="query", required=true, @OA\Schema(type="string", format="date", example="2025-12-31")),
     *     @OA\Response(
     *         response=200,
     *         description="Analytics retrieved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="period", type="object",
     *                     @OA\Property(property="start_date", type="string", format="date", example="2025-01-01"),
     *                     @OA\Property(property="end_date", type="string", format="date", example="2025-12-31")
     *                 ),
     *                 @OA\Property(property="expenses", type="object",
     *                     @OA\Property(property="count", type="integer", example=150),
     *                     @OA\Property(property="total_usd", type="number", format="float", example=7500.00)
     *                 ),
     *                 @OA\Property(property="transfers", type="object",
     *                     @OA\Property(property="count", type="integer", example=45),
     *                     @OA\Property(property="total_usd", type="number", format="float", example=4500.00)
     *                 ),
     *                 @OA\Property(property="incoming", type="object",
     *                     @OA\Property(property="count", type="integer", example=30),
     *                     @OA\Property(property="total_usd", type="number", format="float", example=15000.00)
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=403, description="Forbidden - Admin only"),
     *     @OA\Response(response=422, description="Validation error")
     * )
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function analytics(Request $request): JsonResponse
    {
        $request->validate([
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
        ]);

        $startDate = Carbon::parse($request->input('start_date'));
        $endDate = Carbon::parse($request->input('end_date'));

        $analytics = $this->adminDashboardService->getAnalytics($startDate, $endDate);

        return response()->json([
            'success' => true,
            'data' => $analytics,
        ]);
    }
}
