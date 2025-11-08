<?php

namespace App\Services;

use App\Models\Export;
use App\Models\User;
use App\Repositories\ExpenseRepository;
use App\Services\Exporters\ExcelExporter;
use App\Services\Exporters\ExporterInterface;
use App\Services\Exporters\PdfExporter;
use Carbon\Carbon;
use Illuminate\Support\Facades\Storage;

class ExportService
{
    protected ExpenseRepository $expenseRepository;

    public function __construct(ExpenseRepository $expenseRepository)
    {
        $this->expenseRepository = $expenseRepository;
    }

    /**
     * Export expenses to PDF
     *
     * @param User $user
     * @param array $filters
     * @return Export
     */
    public function exportExpensesToPDF(User $user, array $filters = []): Export
    {
        $exporter = new PdfExporter();
        return $this->createExport($user, $exporter, 'expenses', $filters);
    }

    /**
     * Export expenses to Excel
     *
     * @param User $user
     * @param array $filters
     * @return Export
     */
    public function exportExpensesToExcel(User $user, array $filters = []): Export
    {
        $exporter = new ExcelExporter();
        return $this->createExport($user, $exporter, 'expenses', $filters);
    }

    /**
     * Generate system-wide export for admin users
     *
     * @param User $admin
     * @param string $format ('pdf' or 'excel')
     * @param array $filters
     * @return Export
     * @throws \Exception
     */
    public function generateSystemWideExport(User $admin, string $format = 'pdf', array $filters = []): Export
    {
        if ($admin->role !== 'admin') {
            throw new \Exception('Only admin users can generate system-wide exports');
        }

        $exporter = $format === 'excel' ? new ExcelExporter() : new PdfExporter();
        $filters['is_system_wide'] = true;

        return $this->createExport($admin, $exporter, 'system_wide', $filters);
    }

    /**
     * Create an export record and generate the file
     *
     * @param User $user
     * @param ExporterInterface $exporter
     * @param string $resourceType
     * @param array $filters
     * @return Export
     */
    protected function createExport(User $user, ExporterInterface $exporter, string $resourceType, array $filters = []): Export
    {
        // Create export record
        $export = Export::create([
            'user_id' => $user->id,
            'type' => $exporter->getExtension(),
            'resource_type' => $resourceType,
            'file_path' => '',
            'file_name' => '',
            'filters' => $filters,
            'status' => 'processing',
            'expires_at' => now()->addHours(24),
        ]);

        try {
            // Fetch data based on resource type and filters
            $data = $this->fetchData($user, $resourceType, $filters);

            // Prepare export options
            $options = $this->prepareExportOptions($user, $filters);

            // Generate the file
            $filePath = $exporter->export($data, $options);

            // Update export record
            $export->update([
                'file_path' => $filePath,
                'file_name' => basename($filePath),
                'status' => 'completed',
            ]);

            return $export->fresh();
        } catch (\Exception $e) {
            // Update export record with error
            $export->update([
                'status' => 'failed',
                'error_message' => $e->getMessage(),
            ]);

            throw $e;
        }
    }

    /**
     * Fetch data for export
     *
     * @param User $user
     * @param string $resourceType
     * @param array $filters
     * @return \Illuminate\Support\Collection
     */
    protected function fetchData(User $user, string $resourceType, array $filters = [])
    {
        $isSystemWide = $filters['is_system_wide'] ?? false;

        if ($resourceType === 'expenses' || $resourceType === 'system_wide') {
            // Build query filters
            $queryFilters = [];

            if (isset($filters['start_date'])) {
                $queryFilters['start_date'] = $filters['start_date'];
            }

            if (isset($filters['end_date'])) {
                $queryFilters['end_date'] = $filters['end_date'];
            }

            // Fetch expenses
            if ($isSystemWide && $user->role === 'admin') {
                // Get all expenses for admin (no pagination)
                $expenses = $this->expenseRepository->getAllExpenses($user, $queryFilters, 0);
            } else {
                // Get user's expenses (no pagination)
                $expenses = $this->expenseRepository->getUserExpenses($user, $queryFilters, 0);
            }

            // Load user relationship for system-wide exports
            if ($isSystemWide) {
                $expenses->load('user');
            }

            return $expenses;
        }

        return collect([]);
    }

    /**
     * Prepare export options
     *
     * @param User $user
     * @param array $filters
     * @return array
     */
    protected function prepareExportOptions(User $user, array $filters = []): array
    {
        $options = [
            'user_name' => $user->name,
            'is_system_wide' => $filters['is_system_wide'] ?? false,
        ];

        // Add title
        if ($options['is_system_wide']) {
            $options['title'] = 'System-Wide Expense Report';
        } else {
            $options['title'] = 'Expense Report - ' . $user->name;
        }

        // Add date range if provided
        if (isset($filters['start_date']) && isset($filters['end_date'])) {
            $options['date_range'] = $filters['start_date'] . ' to ' . $filters['end_date'];
        } elseif (isset($filters['start_date'])) {
            $options['date_range'] = 'From ' . $filters['start_date'];
        } elseif (isset($filters['end_date'])) {
            $options['date_range'] = 'Until ' . $filters['end_date'];
        }

        return $options;
    }

    /**
     * Get export by ID
     *
     * @param int $exportId
     * @param User|null $user
     * @return Export|null
     */
    public function getExport(int $exportId, ?User $user = null): ?Export
    {
        $query = Export::query();

        if ($user && $user->role !== 'admin') {
            $query->where('user_id', $user->id);
        }

        return $query->find($exportId);
    }

    /**
     * Clean up old exports (older than 24 hours)
     * This should be called by a scheduled job
     *
     * @return int Number of exports cleaned up
     */
    public function cleanupOldExports(): int
    {
        $expiredExports = Export::expired()->get();
        $count = 0;

        foreach ($expiredExports as $export) {
            // Delete the file from storage
            if ($export->file_path && Storage::exists($export->file_path)) {
                Storage::delete($export->file_path);
            }

            // Delete the export record
            $export->delete();
            $count++;
        }

        return $count;
    }

    /**
     * Get download URL for an export
     *
     * @param Export $export
     * @return string|null
     */
    public function getDownloadUrl(Export $export): ?string
    {
        if ($export->status !== 'completed' || !$export->file_path) {
            return null;
        }

        if ($export->isExpired()) {
            return null;
        }

        return Storage::url($export->file_path);
    }
}
