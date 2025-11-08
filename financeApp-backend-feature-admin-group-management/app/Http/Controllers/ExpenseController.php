<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreExpenseRequest;
use App\Http\Requests\UpdateExpenseRequest;
use App\Models\Expense;
use App\Services\AuditLogService;
use App\Services\ExpenseService;
use App\Services\FileStorageService;
use App\Services\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ExpenseController extends Controller
{
    /**
     * Create a new ExpenseController instance.
     *
     * @param ExpenseService $expenseService
     * @param FileStorageService $fileStorageService
     * @param AuditLogService $auditLogService
     * @param NotificationService $notificationService
     */
    public function __construct(
        protected ExpenseService $expenseService,
        protected FileStorageService $fileStorageService,
        protected AuditLogService $auditLogService,
        protected NotificationService $notificationService
    ) {}

    /**
     * Display a listing of expenses
     *
     * @OA\Get(
     *     path="/api/v1/expenses",
     *     tags={"Expenses"},
     *     summary="List expenses",
     *     description="Get paginated list of expenses. Regular users see only their expenses, admins see all.",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(
     *         name="per_page",
     *         in="query",
     *         description="Items per page",
     *         required=false,
     *         @OA\Schema(type="integer", default=15)
     *     ),
     *     @OA\Parameter(
     *         name="sync_status",
     *         in="query",
     *         description="Filter by sync status",
     *         required=false,
     *         @OA\Schema(type="string", enum={"pending", "syncing", "synced", "failed"})
     *     ),
     *     @OA\Parameter(
     *         name="expense_date_from",
     *         in="query",
     *         description="Filter by expense date from",
     *         required=false,
     *         @OA\Schema(type="string", format="date")
     *     ),
     *     @OA\Parameter(
     *         name="expense_date_to",
     *         in="query",
     *         description="Filter by expense date to",
     *         required=false,
     *         @OA\Schema(type="string", format="date")
     *     ),
     *     @OA\Parameter(
     *         name="has_invoice",
     *         in="query",
     *         description="Filter by invoice presence",
     *         required=false,
     *         @OA\Schema(type="boolean")
     *     ),
     *     @OA\Parameter(
     *         name="search",
     *         in="query",
     *         description="Search in description",
     *         required=false,
     *         @OA\Schema(type="string")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Expenses retrieved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", type="array", @OA\Items(ref="#/components/schemas/Expense")),
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
            'sync_status' => $request->input('sync_status'),
            'expense_date_from' => $request->input('expense_date_from'),
            'expense_date_to' => $request->input('expense_date_to'),
            'has_invoice' => $request->input('has_invoice'),
            'user_id' => $request->input('user_id'),
            'search' => $request->input('search'),
            'sort_by' => $request->input('sort_by', 'expense_date'),
            'sort_order' => $request->input('sort_order', 'desc'),
        ];

        // Remove null values from filters
        $filters = array_filter($filters, fn($value) => $value !== null);

        // Admin users can see all expenses from their organization, regular users see only their own
        if ($user->role === 'admin') {
            $expenses = $this->expenseService->getAllExpenses($user, $filters, $perPage);
        } else {
            $expenses = $this->expenseService->getUserExpenses($user, $filters, $perPage);
        }

        return response()->json([
            'success' => true,
            'data' => $expenses->items(),
            'meta' => [
                'current_page' => $expenses->currentPage(),
                'last_page' => $expenses->lastPage(),
                'per_page' => $expenses->perPage(),
                'total' => $expenses->total(),
            ],
        ]);
    }

    /**
     * Store a newly created expense
     *
     * @OA\Post(
     *     path="/api/v1/expenses",
     *     tags={"Expenses"},
     *     summary="Create expense",
     *     description="Creates a new expense record with multi-currency support and optional photo/invoice attachment",
     *     security={{"sanctum":{}}},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\MediaType(
     *             mediaType="multipart/form-data",
     *             @OA\Schema(
     *                 required={"description","expense_date"},
     *                 @OA\Property(property="description", type="string", example="Office supplies"),
     *                 @OA\Property(property="price_usd", type="number", format="float", example=50.00, nullable=true),
     *                 @OA\Property(property="price_syp", type="number", format="float", example=125000.00, nullable=true),
     *                 @OA\Property(property="price_try", type="number", format="float", example=1500.00, nullable=true),
     *                 @OA\Property(property="expense_date", type="string", format="date", example="2025-10-22"),
     *                 @OA\Property(property="photo", type="string", format="binary", description="Optional photo/invoice (max 10MB, jpeg/jpg/png/gif/webp)", nullable=true),
     *                 @OA\Property(property="sync_status", type="string", enum={"pending","syncing","synced","failed"}, example="synced", nullable=true)
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Expense created successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Expense created successfully"),
     *             @OA\Property(property="data", ref="#/components/schemas/Expense")
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=422, description="Validation error")
     * )
     *
     * @param StoreExpenseRequest $request
     * @return JsonResponse
     */
    public function store(StoreExpenseRequest $request): JsonResponse
    {
        $user = $request->user();
        
        $data = $request->validated();
        
        // Add the photo file if present
        if ($request->hasFile('photo')) {
            $data['photo'] = $request->file('photo');
        }
        
        $expense = $this->expenseService->createExpense($user, $data);

        return response()->json([
            'success' => true,
            'message' => 'Expense created successfully',
            'data' => $expense,
        ], 201);
    }

    /**
     * Display the specified expense
     *
     * @OA\Get(
     *     path="/api/v1/expenses/{id}",
     *     tags={"Expenses"},
     *     summary="Get single expense",
     *     description="Returns a single expense record. Users can only view their own expenses, admins can view all.",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="Expense ID",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Expense retrieved successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="data", ref="#/components/schemas/Expense")
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=403, description="Unauthorized to view this expense"),
     *     @OA\Response(response=404, description="Expense not found")
     * )
     *
     * @param Request $request
     * @param Expense $expense
     * @return JsonResponse
     */
    public function show(Request $request, Expense $expense): JsonResponse
    {
        $user = $request->user();

        // Authorization: users can only view their own expenses, admins can view all
        if ($user->role !== 'admin' && $expense->user_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized to view this expense',
            ], 403);
        }

        // Log admin access to other users' data
        if ($user->role === 'admin' && $expense->user_id !== $user->id) {
            $this->auditLogService->logDataAccess($user, 'Expense', $expense->id);
        }

        return response()->json([
            'success' => true,
            'data' => $expense,
        ]);
    }

    /**
     * Update the specified expense
     *
     * @OA\Post(
     *     path="/api/v1/expenses/{id}",
     *     tags={"Expenses"},
     *     summary="Update expense",
     *     description="Updates an existing expense record with optional photo. Users can only update their own expenses, admins can update all. Note: Use POST with _method=PUT for file uploads.",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="Expense ID",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\MediaType(
     *             mediaType="multipart/form-data",
     *             @OA\Schema(
     *                 @OA\Property(property="description", type="string", example="Updated office supplies", nullable=true),
     *                 @OA\Property(property="price_usd", type="number", format="float", example=60.00, nullable=true),
     *                 @OA\Property(property="price_syp", type="number", format="float", example=150000.00, nullable=true),
     *                 @OA\Property(property="price_try", type="number", format="float", example=1800.00, nullable=true),
     *                 @OA\Property(property="expense_date", type="string", format="date", example="2025-10-22", nullable=true),
     *                 @OA\Property(property="photo", type="string", format="binary", description="Optional photo/invoice (max 10MB, jpeg/jpg/png/gif/webp)", nullable=true),
     *                 @OA\Property(property="sync_status", type="string", enum={"pending","syncing","synced","failed"}, nullable=true),
     *                 @OA\Property(property="_method", type="string", example="PUT", description="Method spoofing for file uploads")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Expense updated successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Expense updated successfully"),
     *             @OA\Property(property="data", ref="#/components/schemas/Expense")
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=403, description="Unauthorized to update this expense"),
     *     @OA\Response(response=404, description="Expense not found"),
     *     @OA\Response(response=422, description="Validation error")
     * )
     *
     * @param UpdateExpenseRequest $request
     * @param Expense $expense
     * @return JsonResponse
     */
    public function update(UpdateExpenseRequest $request, Expense $expense): JsonResponse
    {
        $user = $request->user();

        // Authorization: users can only update their own expenses, admins can update all
        if ($user->role !== 'admin' && $expense->user_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized to update this expense',
            ], 403);
        }

        $data = $request->validated();
        
        // Add the photo file if present
        if ($request->hasFile('photo')) {
            $data['photo'] = $request->file('photo');
        }

        $updatedExpense = $this->expenseService->updateExpense($expense, $data);

        // Send notification if admin modified another user's data
        if ($user->role === 'admin' && $expense->user_id !== $user->id) {
            $expenseOwner = $expense->user;
            $this->notificationService->sendDataModificationAlert($expenseOwner, 'update', 'expense');
        }

        return response()->json([
            'success' => true,
            'message' => 'Expense updated successfully',
            'data' => $updatedExpense,
        ]);
    }

    /**
     * Remove the specified expense (soft delete)
     *
     * @OA\Delete(
     *     path="/api/v1/expenses/{id}",
     *     tags={"Expenses"},
     *     summary="Delete expense",
     *     description="Soft deletes an expense record and removes associated invoice files. Users can only delete their own expenses, admins can delete all.",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="Expense ID",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Expense deleted successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Expense deleted successfully")
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=403, description="Unauthorized to delete this expense"),
     *     @OA\Response(response=404, description="Expense not found")
     * )
     *
     * @param Request $request
     * @param Expense $expense
     * @return JsonResponse
     */
    public function destroy(Request $request, Expense $expense): JsonResponse
    {
        $user = $request->user();

        // Authorization: users can only delete their own expenses, admins can delete all
        if ($user->role !== 'admin' && $expense->user_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized to delete this expense',
            ], 403);
        }

        // Send notification if admin deleted another user's data
        if ($user->role === 'admin' && $expense->user_id !== $user->id) {
            $expenseOwner = $expense->user;
            $this->notificationService->sendDataModificationAlert($expenseOwner, 'delete', 'expense');
        }

        $this->expenseService->deleteExpense($expense);

        return response()->json([
            'success' => true,
            'message' => 'Expense deleted successfully',
        ], 200);
    }

    /**
     * Upload an invoice file for the specified expense
     *
     * @OA\Post(
     *     path="/api/v1/expenses/{id}/invoice",
     *     tags={"Expenses"},
     *     summary="Upload invoice",
     *     description="Uploads an invoice file for an expense. Images are compressed to max 1920px width. Max file size 10MB.",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="Expense ID",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\MediaType(
     *             mediaType="multipart/form-data",
     *             @OA\Schema(
     *                 required={"invoice"},
     *                 @OA\Property(property="invoice", type="string", format="binary", description="Invoice file (JPEG, PNG, PDF)")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Invoice uploaded successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Invoice uploaded successfully"),
     *             @OA\Property(property="data", ref="#/components/schemas/Expense")
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=403, description="Unauthorized"),
     *     @OA\Response(response=404, description="Expense not found"),
     *     @OA\Response(response=422, description="Validation error")
     * )
     *
     * @param Request $request
     * @param Expense $expense
     * @return JsonResponse
     */
    public function uploadInvoice(Request $request, Expense $expense): JsonResponse
    {
        $user = $request->user();

        // Authorization: users can only upload invoices for their own expenses, admins can upload for all
        if ($user->role !== 'admin' && $expense->user_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized to upload invoice for this expense',
            ], 403);
        }

        // Validate the uploaded file
        $request->validate([
            'invoice' => 'required|file|mimes:jpeg,jpg,png,pdf|max:10240', // 10MB max
        ]);

        try {
            $updatedExpense = $this->expenseService->attachInvoice($expense, $request->file('invoice'));

            return response()->json([
                'success' => true,
                'message' => 'Invoice uploaded successfully',
                'data' => $updatedExpense,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to upload invoice: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Download the invoice file for the specified expense
     *
     * @OA\Get(
     *     path="/api/v1/expenses/{id}/invoice",
     *     tags={"Expenses"},
     *     summary="Download invoice",
     *     description="Downloads the invoice file for an expense. Users can only download invoices for their own expenses, admins can download all.",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="Expense ID",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Invoice file",
     *         @OA\MediaType(
     *             mediaType="application/octet-stream",
     *             @OA\Schema(type="string", format="binary")
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=403, description="Unauthorized"),
     *     @OA\Response(response=404, description="Invoice not found")
     * )
     *
     * @param Request $request
     * @param Expense $expense
     * @return StreamedResponse|JsonResponse
     */
    public function downloadInvoice(Request $request, Expense $expense): StreamedResponse|JsonResponse
    {
        $user = $request->user();

        // Authorization: users can only download invoices for their own expenses, admins can download all
        if ($user->role !== 'admin' && $expense->user_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized to download invoice for this expense',
            ], 403);
        }

        // Check if expense has an invoice
        if (!$expense->has_invoice || !$expense->invoice_path) {
            return response()->json([
                'success' => false,
                'message' => 'No invoice found for this expense',
            ], 404);
        }

        // Check if file exists
        if (!$this->fileStorageService->fileExists($expense->invoice_path)) {
            return response()->json([
                'success' => false,
                'message' => 'Invoice file not found',
            ], 404);
        }

        try {
            $fileContents = $this->fileStorageService->getFileContents($expense->invoice_path);
            $mimeType = $this->fileStorageService->getFileMimeType($expense->invoice_path);
            $filename = basename($expense->invoice_path);

            return response()->streamDownload(function () use ($fileContents) {
                echo $fileContents;
            }, $filename, [
                'Content-Type' => $mimeType,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to download invoice: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Delete the invoice file for the specified expense
     *
     * @OA\Delete(
     *     path="/api/v1/expenses/{id}/invoice",
     *     tags={"Expenses"},
     *     summary="Delete invoice",
     *     description="Deletes the invoice file for an expense. Users can only delete invoices for their own expenses, admins can delete all.",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(
     *         name="id",
     *         in="path",
     *         required=true,
     *         description="Expense ID",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Invoice deleted successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Invoice deleted successfully"),
     *             @OA\Property(property="data", ref="#/components/schemas/Expense")
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=403, description="Unauthorized"),
     *     @OA\Response(response=404, description="Invoice not found")
     * )
     *
     * @param Request $request
     * @param Expense $expense
     * @return JsonResponse
     */
    public function deleteInvoice(Request $request, Expense $expense): JsonResponse
    {
        $user = $request->user();

        // Authorization: users can only delete invoices for their own expenses, admins can delete all
        if ($user->role !== 'admin' && $expense->user_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized to delete invoice for this expense',
            ], 403);
        }

        // Check if expense has an invoice
        if (!$expense->has_invoice || !$expense->invoice_path) {
            return response()->json([
                'success' => false,
                'message' => 'No invoice found for this expense',
            ], 404);
        }

        try {
            $updatedExpense = $this->expenseService->deleteInvoice($expense);

            return response()->json([
                'success' => true,
                'message' => 'Invoice deleted successfully',
                'data' => $updatedExpense,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete invoice: ' . $e->getMessage(),
            ], 500);
        }
    }
}
