<?php

namespace App\Services\Exporters;

use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Storage;

class PdfExporter implements ExporterInterface
{
    public function export(Collection $data, array $options = []): string
    {
        $fileName = 'export_' . time() . '_' . uniqid() . '.pdf';
        $filePath = 'exports/' . $fileName;

        // Prepare data for PDF view
        $viewData = [
            'expenses' => $data,
            'title' => $options['title'] ?? 'Expense Report',
            'dateRange' => $options['date_range'] ?? null,
            'generatedAt' => now()->format('Y-m-d H:i:s'),
            'userName' => $options['user_name'] ?? null,
            'isSystemWide' => $options['is_system_wide'] ?? false,
        ];

        // Generate PDF
        $pdf = Pdf::loadView('exports.expenses-pdf', $viewData);
        
        // Set paper size and orientation
        $pdf->setPaper('a4', 'portrait');

        // Save to storage
        Storage::put($filePath, $pdf->output());

        return $filePath;
    }

    public function getExtension(): string
    {
        return 'pdf';
    }

    public function getMimeType(): string
    {
        return 'application/pdf';
    }
}
