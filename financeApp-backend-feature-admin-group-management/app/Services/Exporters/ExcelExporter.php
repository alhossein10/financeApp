<?php

namespace App\Services\Exporters;

use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Storage;
use Maatwebsite\Excel\Facades\Excel;
use App\Exports\ExpensesExport;

class ExcelExporter implements ExporterInterface
{
    public function export(Collection $data, array $options = []): string
    {
        $fileName = 'export_' . time() . '_' . uniqid() . '.xlsx';
        $filePath = 'exports/' . $fileName;

        // Create the export instance
        $export = new ExpensesExport($data, $options);

        // Store the file
        Excel::store($export, $filePath, 'local');

        return $filePath;
    }

    public function getExtension(): string
    {
        return 'xlsx';
    }

    public function getMimeType(): string
    {
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
}
