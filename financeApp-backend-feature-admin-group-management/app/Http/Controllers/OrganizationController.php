<?php

namespace App\Http\Controllers;

use App\Models\Organization;
use Illuminate\Http\JsonResponse;

class OrganizationController extends Controller
{
    /**
     * Get all organizations.
     *
     * @return JsonResponse
     */
    public function index(): JsonResponse
    {
        $organizations = Organization::select('id', 'name')
            ->orderBy('name')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $organizations,
        ]);
    }

    /**
     * Get departments for a specific organization.
     *
     * @param int $id
     * @return JsonResponse
     */
    public function departments(int $id): JsonResponse
    {
        $organization = Organization::find($id);

        if (!$organization) {
            return response()->json([
                'success' => false,
                'message' => 'المنظمة المحددة غير موجودة',
            ], 404);
        }

        $departments = $organization->departments()
            ->select('id', 'organization_id', 'name')
            ->orderBy('name')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $departments,
        ]);
    }
}
