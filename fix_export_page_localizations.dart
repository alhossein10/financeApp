import 'dart:io';

void main() async {
  print('Fixing export_page.dart localizations...\n');

  final file = File('lib/features/export/presentation/pages/export_page.dart');
  if (!await file.exists()) {
    print('⚠️  File not found');
    return;
  }

  var content = await file.readAsString();

  // Map of missing properties to fallback values
  final replacements = {
    "l10n?.open ?? 'Open'": "l10n?.viewDetails ?? 'Open'",
    "l10n?.dateRange ?? 'Date Range'": "l10n?.date ?? 'Date Range'",
    "l10n?.startDate ?? 'Start Date'": "'Start Date'",
    "l10n?.endDate ?? 'End Date'": "'End Date'",
    "l10n?.clearDates ?? 'Clear Dates'": "l10n?.clear ?? 'Clear Dates'",
    "l10n?.exportFormat ?? 'Export Format'": "l10n?.export ?? 'Export Format'",
    "l10n?.pdf ?? 'PDF'": "l10n?.exportPdf ?? 'PDF'",
    "l10n?.excel ?? 'Excel'": "l10n?.exportExcel ?? 'Excel'",
    "l10n?.exporting ?? 'Exporting...'": "l10n?.syncing ?? 'Exporting...'",
    "l10n?.exportStatus ?? 'Export Status'": "l10n?.syncStatus ?? 'Export Status'",
    "l10n?.requestingExport ?? 'Requesting export...'": "l10n?.syncing ?? 'Requesting export...'",
    "l10n?.pleaseWait ?? 'Please wait'": "l10n?.loading ?? 'Please wait'",
    "l10n?.exportQueued ?? 'Export queued'": "l10n?.pending ?? 'Export queued'",
    "l10n?.exportInQueue ?? 'Export is in queue'": "l10n?.pending ?? 'Export is in queue'",
    "l10n?.processingExport ?? 'Processing export...'": "l10n?.syncing ?? 'Processing export...'",
    "l10n?.complete ?? 'complete'": "l10n?.success ?? 'complete'",
    "l10n?.exportReady ?? 'Export ready'": "l10n?.success ?? 'Export ready'",
    "l10n?.downloading ?? 'Downloading...'": "l10n?.loading ?? 'Downloading...'",
    "l10n?.downloadingExport ?? 'Downloading export...'": "l10n?.loading ?? 'Downloading export...'",
    "l10n?.exportCompleted ?? 'Export completed'": "l10n?.success ?? 'Export completed'",
    "l10n?.fileSavedSuccessfully ?? 'File saved successfully'": "l10n?.success ?? 'File saved successfully'",
    "l10n?.openFile ?? 'Open File'": "l10n?.viewDetails ?? 'Open File'",
    "l10n?.exportFailed ?? 'Export failed'": "l10n?.error ?? 'Export failed'",
  };

  var modified = false;
  for (final entry in replacements.entries) {
    if (content.contains(entry.key)) {
      content = content.replaceAll(entry.key, entry.value);
      modified = true;
    }
  }

  if (modified) {
    await file.writeAsString(content);
    print('✅ Fixed export_page.dart');
  } else {
    print('ℹ️  No changes needed');
  }
}
