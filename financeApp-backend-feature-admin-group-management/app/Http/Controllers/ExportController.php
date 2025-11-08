<?php

namespace App\Http\Controllers;

use App\Models\Export;
use App\Services\ExportService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ExportController extends Controller
{
    protected ExportService $exportService;

    public function __construct(ExportService $exportService)
    {
        $this->exportService = $exportService;
    }

    /**
     * Export expenses to PDF
     *
     * @OA\Post(
     *     path="/api/v1/export/expenses/pdf",
     *     tags={"Export"},
     *     summary="Export expenses to PDF",
     *     description="Generates a formatted PDF document with expense records and returns a download URL valid for 24 hours",
     *     security={{"sanctum":{}}},
     *     @OA\RequestBody(
     *         required=false,
     *         @OA\JsonContent(
     *             @OA\Property(property="start_date", type="string", format="date", example="2025-01-01"),
     *             @OA\Property(property="end_date", type="string", format="date", example="2025-12-31"),
     *             @OA\Property(property="sync_status", type="string", enum={"pending","syncing","synced","failed"}),
     *             @OA\Property(property="has_invoice", type="boolean", example=true)
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="PDF export generated successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="PDF export generated successfully"),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="export_id", type="integer", example=1),
     *                 @OA\Property(property="status", type="string", example="completed"),
     *                 @OA\Property(property="file_name", type="string", example="expenses_export_20251022.pdf"),
     *                 @OA\Property(property="expires_at", type="string", format="date-time"),
     *                 @OA\Property(property="download_url", type="string", example="/api/v1/export/1/download")
     *             )
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=500, description="Export generation failed")
     * )
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function exportExpensesToPdf(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
            'sync_status' => 'nullable|in:pending,syncing,synced,failed',
            'has_invoice' => 'nullable|boolean',
        ]);

        try {
            $export = $this->exportService->exportExpensesToPDF($request->user(), $validated);

            return response()->json([
                'success' => true,
                'message' => 'PDF export generated successfully',
                'data' => [
                    'export_id' => $export->id,
                    'status' => $export->status,
                    'file_name' => $export->file_name,
                    'expires_at' => $export->expires_at,
                    'download_url' => route('exports.download', $export->id),
                ],
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to generate PDF export',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Export expenses to Excel
     *
     * @OA\Post(
     *     path="/api/v1/export/expenses/excel",
     *     tags={"Export"},
     *     summary="Export expenses to Excel",
     *     description="Generates an XLSX file with expense records in tabular format and returns a download URL valid for 24 hours",
     *     security={{"sanctum":{}}},
     *     @OA\RequestBody(
     *         required=false,
     *         @OA\JsonContent(
     *             @OA\Property(property="start_date", type="string", format="date", example="2025-01-01"),
     *             @OA\Property(property="end_date", type="string", format="date", example="2025-12-31"),
     *             @OA\Property(property="sync_status", type="string", enum={"pending","syncing","synced","failed"}),
     *             @OA\Property(property="has_invoice", type="boolean", example=true)
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Excel export generated successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Excel export generated successfully"),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="export_id", type="integer", example=1),
     *                 @OA\Property(property="status", type="string", example="completed"),
     *                 @OA\Property(property="file_name", type="string", example="expenses_export_20251022.xlsx"),
     *                 @OA\Property(property="expires_at", type="string", format="date-time"),
     *                 @OA\Property(property="download_url", type="string", example="/api/v1/export/1/download")
     *             )
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=500, description="Export generation failed")
     * )
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function exportExpensesToExcel(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
            'sync_status' => 'nullable|in:pending,syncing,synced,failed',
            'has_invoice' => 'nullable|boolean',
        ]);

        try {
            $export = $this->exportService->exportExpensesToExcel($request->user(), $validated);

            return response()->json([
                'success' => true,
                'message' => 'Excel export generated successfully',
                'data' => [
                    'export_id' => $export->id,
                    'status' => $export->status,
                    'file_name' => $export->file_name,
                    'expires_at' => $export->expires_at,
                    'download_url' => route('exports.download', $export->id),
                ],
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to generate Excel export',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Generate system-wide export (admin only)
     *
     * @OA\Post(
     *     path="/api/v1/export/system-wide",
     *     tags={"Export"},
     *     summary="Generate system-wide export (Admin only)",
     *     description="Generates an export including data from all users with user identification columns",
     *     security={{"sanctum":{}}},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"format"},
     *             @OA\Property(property="format", type="string", enum={"pdf","excel"}, example="excel"),
     *             @OA\Property(property="start_date", type="string", format="date", example="2025-01-01"),
     *             @OA\Property(property="end_date", type="string", format="date", example="2025-12-31"),
     *             @OA\Property(property="sync_status", type="string", enum={"pending","syncing","synced","failed"}),
     *             @OA\Property(property="has_invoice", type="boolean", example=true)
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="System-wide export generated successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="System-wide export generated successfully"),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="export_id", type="integer", example=1),
     *                 @OA\Property(property="status", type="string", example="completed"),
     *                 @OA\Property(property="file_name", type="string", example="system_export_20251022.xlsx"),
     *                 @OA\Property(property="expires_at", type="string", format="date-time"),
     *                 @OA\Property(property="download_url", type="string", example="/api/v1/export/1/download")
     *             )
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=403, description="Forbidden - Admin only"),
     *     @OA\Response(response=500, description="Export generation failed")
     * )
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function exportSystemWide(Request $request): JsonResponse
    {
        // Check if user is admin
        if ($request->user()->role !== 'admin') {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized. Only admin users can generate system-wide exports.',
            ], 403);
        }

        $validated = $request->validate([
            'format' => 'required|in:pdf,excel',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
            'sync_status' => 'nullable|in:pending,syncing,synced,failed',
            'has_invoice' => 'nullable|boolean',
        ]);

        try {
            $format = $validated['format'];
            unset($validated['format']);

            $export = $this->exportService->generateSystemWideExport(
                $request->user(),
                $format,
                $validated
            );

            return response()->json([
                'success' => true,
                'message' => 'System-wide export generated successfully',
                'data' => [
                    'export_id' => $export->id,
                    'status' => $export->status,
                    'file_name' => $export->file_name,
                    'expires_at' => $export->expires_at,
                    'download_url' => route('exports.download', $export->id),
                ],
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to generate system-wide export',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Download an export file
     *
     * @OA\Get(
     *     path="/api/v1/export/{id}/download",
     *     tags={"Export"},
     *     summary="Download export file",
     *     description="Downloads a generated export file. Files are valid for 24 hours after generation.",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="Export ID",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Export file",
     *         @OA\MediaType(
     *             mediaType="application/octet-stream",
     *             @OA\Schema(type="string", format="binary")
     *         )
     *     ),
     *     @OA\Response(response=400, description="Export not ready for download"),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=404, description="Export not found"),
     *     @OA\Response(response=410, description="Export has expired")
     * )
     *
     * @param Request $request
     * @param int $id
     * @return JsonResponse|StreamedResponse
     */
    public function download(Request $request, int $id)
    {
        $export = $this->exportService->getExport($id, $request->user());

        if (!$export) {
            return response()->json([
                'success' => false,
                'message' => 'Export not found or you do not have permission to access it',
            ], 404);
        }

        if ($export->status !== 'completed') {
            return response()->json([
                'success' => false,
                'message' => 'Export is not ready for download',
                'data' => [
                    'status' => $export->status,
                    'error_message' => $export->error_message,
                ],
            ], 400);
        }

        if ($export->isExpired()) {
            return response()->json([
                'success' => false,
                'message' => 'Export has expired',
            ], 410);
        }

        if (!Storage::exists($export->file_path)) {
            return response()->json([
                'success' => false,
                'message' => 'Export file not found',
            ], 404);
        }

        // Determine MIME type based on file extension
        $mimeType = $export->type === 'pdf' 
            ? 'application/pdf' 
            : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

        return Storage::download($export->file_path, $export->file_name, [
            'Content-Type' => $mimeType,
        ]);
    }

    /**
     * Get export status
     *
     * @OA\Get(
     *     path="/api/v1/export/{id}/status",
     *     tags={"Export"},
     *     summary="Get export status",
     *     description="Returns the current status of an export job",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="Export ID",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Export status retrieved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="id", type="integer", example=1),
     *                 @OA\Property(property="type", type="string", example="pdf"),
     *                 @OA\Property(property="resource_type", type="string", example="expense"),
     *                 @OA\Property(property="status", type="string", enum={"pending","processing","completed","failed"}, example="completed"),
     *                 @OA\Property(property="file_name", type="string", example="expenses_export_20251022.pdf"),
     *                 @OA\Property(property="error_message", type="string", nullable=true),
     *                 @OA\Property(property="expires_at", type="string", format="date-time"),
     *                 @OA\Property(property="created_at", type="string", format="date-time"),
     *                 @OA\Property(property="download_url", type="string", nullable=true, example="/api/v1/export/1/download")
     *             )
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=404, description="Export not found")
     * )
     *
     * @param Request $request
     * @param int $id
     * @return JsonResponse
     */
    public function status(Request $request, int $id): JsonResponse
    {
        $export = $this->exportService->getExport($id, $request->user());

        if (!$export) {
            return response()->json([
                'success' => false,
                'message' => 'Export not found or you do not have permission to access it',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $export->id,
                'type' => $export->type,
                'resource_type' => $export->resource_type,
                'status' => $export->status,
                'file_name' => $export->file_name,
                'error_message' => $export->error_message,
                'expires_at' => $export->expires_at,
                'created_at' => $export->created_at,
                'download_url' => $export->status === 'completed' 
                    ? route('exports.download', $export->id) 
                    : null,
            ],
        ]);
    }

    /**
     * List user's exports
     *
     * @OA\Get(
     *     path="/api/v1/export",
     *     tags={"Export"},
     *     summary="List exports",
     *     description="Returns a paginated list of user's exports. Admins can see all exports with ?all=true parameter.",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(name="all", in="query", required=false, description="Admin only: show all exports", @OA\Schema(type="boolean")),
     *     @OA\Response(
     *         response=200,
     *         description="Exports retrieved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="data", type="array", @OA\Items(type="object")),
     *                 @OA\Property(property="current_page", type="integer", example=1),
     *                 @OA\Property(property="last_page", type="integer", example=3),
     *                 @OA\Property(property="per_page", type="integer", example=15),
     *                 @OA\Property(property="total", type="integer", example=45)
     *             )
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
        $query = Export::query()->where('user_id', $request->user()->id);

        // Admin can see all exports
        if ($request->user()->role === 'admin' && $request->boolean('all')) {
            $query = Export::query()->with('user:id,name,email');
        }

        $exports = $query->orderBy('created_at', 'desc')
            ->paginate(15);

        return response()->json([
            'success' => true,
            'data' => $exports,
        ]);
    }
}
