<?php

namespace App\Exports;

use Illuminate\Support\Collection;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Maatwebsite\Excel\Concerns\WithStyles;
use Maatwebsite\Excel\Concerns\WithTitle;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class ExpensesExport implements FromCollection, WithHeadings, WithMapping, WithStyles, WithTitle
{
    protected Collection $expenses;
    protected array $options;

    public function __construct(Collection $expenses, array $options = [])
    {
        $this->expenses = $expenses;
        $this->options = $options;
    }

    public function collection()
    {
        return $this->expenses;
    }

    public function headings(): array
    {
        $headings = [
            'ID',
            'Date',
            'Description',
            'Amount (USD)',
            'Amount (SYP)',
            'Amount (TRY)',
            'Has Invoice',
            'Sync Status',
            'Created At',
        ];

        // Add user column for system-wide exports
        if ($this->options['is_system_wide'] ?? false) {
            array_splice($headings, 1, 0, ['User']);
        }

        return $headings;
    }

    public function map($expense): array
    {
        $row = [
            $expense->id,
            $expense->expense_date,
            $expense->description,
            $expense->price_usd,
            $expense->price_syp ?? 'N/A',
            $expense->price_try ?? 'N/A',
            $expense->has_invoice ? 'Yes' : 'No',
            ucfirst($expense->sync_status),
            $expense->created_at->format('Y-m-d H:i:s'),
        ];

        // Add user name for system-wide exports
        if ($this->options['is_system_wide'] ?? false) {
            array_splice($row, 1, 0, [$expense->user->name ?? 'N/A']);
        }

        return $row;
    }

    public function styles(Worksheet $sheet)
    {
        return [
            1 => ['font' => ['bold' => true]],
        ];
    }

    public function title(): string
    {
        return 'Expenses';
    }
}
