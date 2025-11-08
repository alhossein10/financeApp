<?php

namespace App\Services\Exporters;

use Illuminate\Support\Collection;

interface ExporterInterface
{
    /**
     * Export data to a file
     *
     * @param Collection $data
     * @param array $options
     * @return string File path
     */
    public function export(Collection $data, array $options = []): string;

    /**
     * Get the file extension for this exporter
     *
     * @return string
     */
    public function getExtension(): string;

    /**
     * Get the MIME type for this exporter
     *
     * @return string
     */
    public function getMimeType(): string;
}
