<?php

namespace App\Http\Controllers;

use App\Services\FundBoxService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use InvalidArgumentException;

class FundBoxController extends Controller
{
    /**
     * Create a new FundBoxController instance.
     *
     * @param FundBoxService $fundBoxService
     */
    public function __construct(
        protected FundBoxService $fundBoxService
    ) {
        // Middleware is applied in routes/api_v1.php
    }

    /**
     * Get the fund box balance
     *
     * @OA\Get(
     *     path="/api/v1/fund-box",
     *     tags={"Fund Box"},
     *     summary="Get fund box balance",
     *     description="Returns the current fund box balance and last calculated timestamp. Admins see their group's fund box, regular users see their own.",
     *     security={{"sanctum":{}}},
     *     @OA\Response(
     *         response=200,
     *         description="Fund box retrieved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", ref="#/components/schemas/FundBox")
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated")
     * )
     *
     * @return JsonResponse
     */
    public function show(): JsonResponse
    {
        $user = auth()->user();
        $fundBox = $this->fundBoxService->getFundBoxForUser($user);

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $fundBox->id,
                'balance_usd' => $fundBox->balance_usd,
                'last_calculated_at' => $fundBox->last_calculated_at?->toIso8601String(),
                'updated_at' => $fundBox->updated_at->toIso8601String(),
            ],
        ]);
    }

    /**
     * Update the fund box balance
     *
     * @OA\Put(
     *     path="/api/v1/fund-box",
     *     tags={"Fund Box"},
     *     summary="Update fund box balance",
     *     description="Updates the fund box balance with validation for non-negative values. Admins update their group's fund box, regular users update their own.",
     *     security={{"sanctum":{}}},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"balance_usd"},
     *             @OA\Property(property="balance_usd", type="number", format="float", example=10000.00, minimum=0)
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Fund box updated successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Fund box balance updated successfully."),
     *             @OA\Property(property="data", ref="#/components/schemas/FundBox")
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=422, description="Validation error")
     * )
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function update(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'balance_usd' => 'required|numeric|min:0',
        ]);

        try {
            $user = auth()->user();
            $fundBox = $this->fundBoxService->updateBalanceForUser($user, $validated['balance_usd']);

            return response()->json([
                'success' => true,
                'message' => 'Fund box balance updated successfully.',
                'data' => [
                    'id' => $fundBox->id,
                    'balance_usd' => $fundBox->balance_usd,
                    'last_calculated_at' => $fundBox->last_calculated_at?->toIso8601String(),
                    'updated_at' => $fundBox->updated_at->toIso8601String(),
                ],
            ]);
        } catch (InvalidArgumentException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }
    }
}
