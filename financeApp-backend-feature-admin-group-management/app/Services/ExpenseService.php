<?php

namespace App\Services;

use App\Models\Expense;
use App\Models\User;
use App\Repositories\ExpenseRepository;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

class ExpenseService
{
    /**
     * Create a new ExpenseService instance.
     *
     * @param ExpenseRepository $expenseRepository
     * @param FileStorageService $fileStorageService
     */
    public function __construct(
        protected ExpenseRepository $expenseRepository,
        protected FileStorageService $fileStorageService
    ) {}

    /**
     * Create a new expense with multi-currency support and optional photo.
     *
     * @param User $user
     * @param array $data
     * @return Expense
     */
    public function createExpense(User $user, array $data): Expense
    {
        // Handle photo upload if provided
        $hasInvoice = false;
        $invoicePath = null;
        
        if (isset($data['photo']) && $data['photo'] instanceof UploadedFile) {
            $invoicePath = $this->fileStorageService->uploadFile($data['photo'], 'public/invoices');
            $hasInvoice = true;
        }

        $expenseData = [
            'user_id' => $user->id,
            'organization_id' => $user->organization_id,
            'department_id' => $user->department_id,
            'description' => $data['description'],
            'price_usd' => $data['price_usd'] ?? null,
            'price_syp' => $data['price_syp'] ?? null,
            'price_try' => $data['price_try'] ?? null,
            'expense_date' => $data['expense_date'],
            'has_invoice' => $hasInvoice,
            'invoice_path' => $invoicePath,
            'sync_status' => $data['sync_status'] ?? 'synced',
            'synced_at' => $data['synced_at'] ?? now(),
            'sync_retry_count' => $data['sync_retry_count'] ?? 0,
            'sync_error_message' => $data['sync_error_message'] ?? null,
        ];

        return $this->expenseRepository->create($expenseData);
    }

    /**
     * Update an existing expense with sync status tracking and optional photo.
     *
     * @param Expense $expense
     * @param array $data
     * @return Expense
     */
    public function updateExpense(Expense $expense, array $data): Expense
    {
        $updateData = [];

        // Handle photo upload if provided
        if (isset($data['photo']) && $data['photo'] instanceof UploadedFile) {
            // Delete old photo if exists
            if ($expense->invoice_path) {
                $this->fileStorageService->deleteFile($expense->invoice_path);
            }
            
            // Upload new photo
            $updateData['invoice_path'] = $this->fileStorageService->uploadFile($data['photo'], 'public/invoices');
            $updateData['has_invoice'] = true;
        }

        if (isset($data['description'])) {
            $updateData['description'] = $data['description'];
        }

        if (isset($data['price_usd'])) {
            $updateData['price_usd'] = $data['price_usd'];
        }

        if (isset($data['price_syp'])) {
            $updateData['price_syp'] = $data['price_syp'];
        }

        if (isset($data['price_try'])) {
            $updateData['price_try'] = $data['price_try'];
        }

        if (isset($data['expense_date'])) {
            $updateData['expense_date'] = $data['expense_date'];
        }

        // Update sync status tracking
        if (isset($data['sync_status'])) {
            $updateData['sync_status'] = $data['sync_status'];
        }

        if (isset($data['synced_at'])) {
            $updateData['synced_at'] = $data['synced_at'];
        }

        if (isset($data['sync_retry_count'])) {
            $updateData['sync_retry_count'] = $data['sync_retry_count'];
        }

        if (isset($data['sync_error_message'])) {
            $updateData['sync_error_message'] = $data['sync_error_message'];
        }

        return $this->expenseRepository->update($expense, $updateData);
    }

    /**
     * Delete an expense with soft delete and file cleanup.
     *
     * @param Expense $expense
     * @return bool
     */
    public function deleteExpense(Expense $expense): bool
    {
        // Clean up invoice file if it exists
        if ($expense->has_invoice && $expense->invoice_path) {
            Storage::delete($expense->invoice_path);
        }

        return $this->expenseRepository->delete($expense);
    }

    /**
     * Get expenses for a specific user with filtering.
     *
     * @param User $user
     * @param array $filters
     * @param int $perPage
     * @return LengthAwarePaginator
     */
    public function getUserExpenses(User $user, array $filters = [], int $perPage = 15): LengthAwarePaginator
    {
        return $this->expenseRepository->getUserExpenses($user, $filters, $perPage);
    }

    /**
     * Get all expenses (admin access) with filtering.
     *
     * @param User $user
     * @param array $filters
     * @param int $perPage
     * @return LengthAwarePaginator
     */
    public function getAllExpenses(User $user, array $filters = [], int $perPage = 15): LengthAwarePaginator
    {
        return $this->expenseRepository->getAllExpenses($user, $filters, $perPage);
    }

    /**
     * Attach an invoice file to an expense.
     *
     * @param Expense $expense
     * @param UploadedFile $file
     * @return Expense
     */
    public function attachInvoice(Expense $expense, UploadedFile $file): Expense
    {
        // Delete old invoice if exists
        if ($expense->has_invoice && $expense->invoice_path) {
            $this->fileStorageService->deleteFile($expense->invoice_path);
        }

        // Upload new invoice
        $path = $this->fileStorageService->uploadFile($file, 'public/invoices');

        // Update expense
        return $this->expenseRepository->update($expense, [
            'has_invoice' => true,
            'invoice_path' => $path,
        ]);
    }

    /**
     * Delete the invoice file from an expense.
     *
     * @param Expense $expense
     * @return Expense
     */
    public function deleteInvoice(Expense $expense): Expense
    {
        // Delete file from storage
        if ($expense->invoice_path) {
            $this->fileStorageService->deleteFile($expense->invoice_path);
        }

        // Update expense
        return $this->expenseRepository->update($expense, [
            'has_invoice' => false,
            'invoice_path' => null,
        ]);
    }
}
