import 'package:flutter/material.dart';
import 'dart:io';

import '../../../../core/migration/data_migrator.dart';
import '../../../../injection_container.dart';

/// Page for migrating data from SQLite to Laravel backend
class MigrationPage extends StatefulWidget {
  const MigrationPage({Key? key}) : super(key: key);

  @override
  State<MigrationPage> createState() => _MigrationPageState();
}

class _MigrationPageState extends State<MigrationPage> {
  late final DataMigrator _migrator;
  
  bool _isMigrating = false;
  bool _isExporting = false;
  double _progress = 0.0;
  String _statusMessage = '';
  MigrationResult? _result;
  File? _exportFile;

  @override
  void initState() {
    super.initState();
    _migrator = sl();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Migration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildActionButtons(),
            const SizedBox(height: 16),
            if (_isMigrating || _isExporting) _buildProgressCard(),
            if (_result != null) _buildResultCard(),
            if (_exportFile != null) _buildExportCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'About Migration',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'This tool will migrate your local SQLite data to the Laravel backend. '
              'Your data will be uploaded to the server and synchronized.',
            ),
            const SizedBox(height: 12),
            const Text(
              'What will be migrated:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            _buildBulletPoint('All expenses'),
            _buildBulletPoint('All transfers'),
            _buildBulletPoint('All incoming transactions'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Make sure you have a stable internet connection before starting.',
                      style: TextStyle(color: Colors.orange[900]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _isMigrating || _isExporting ? null : _startMigration,
          icon: const Icon(Icons.cloud_upload),
          label: const Text('Start Migration'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _isMigrating || _isExporting ? null : _exportOnly,
          icon: const Icon(Icons.save_alt),
          label: const Text('Export to JSON Only'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(16),
          ),
        ),
        if (_result != null && !_result!.success && _result!.failedRecords > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ElevatedButton.icon(
              onPressed: _isMigrating ? null : _retryMigration,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Failed Records'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isMigrating ? 'Migration in Progress' : 'Exporting Data',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress / 100,
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '${_progress.toStringAsFixed(0)}%',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final result = _result!;
    final isSuccess = result.success;
    final color = isSuccess ? Colors.green : Colors.red;

    return Card(
      color: isSuccess ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  isSuccess ? 'Migration Successful' : 'Migration Failed',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildResultRow('Total Records', result.totalRecords.toString()),
            _buildResultRow(
              'Successful',
              result.successfulRecords.toString(),
              color: Colors.green,
            ),
            if (result.failedRecords > 0)
              _buildResultRow(
                'Failed',
                result.failedRecords.toString(),
                color: Colors.red,
              ),
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Errors:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: result.errors
                      .take(5)
                      .map((error) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• $error',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ))
                      .toList(),
                ),
              ),
              if (result.errors.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '... and ${result.errors.length - 5} more errors',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.file_download, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Export Complete',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Data exported to:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _exportFile!.path,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startMigration() async {
    final confirmed = await _showConfirmationDialog(
      'Start Migration',
      'This will upload all your local data to the Laravel backend. '
          'Make sure you have a stable internet connection.\n\n'
          'Continue?',
    );

    if (!confirmed) return;

    setState(() {
      _isMigrating = true;
      _progress = 0.0;
      _statusMessage = 'Initializing...';
      _result = null;
      _exportFile = null;
    });

    try {
      final result = await _migrator.exportAndMigrate(
        onProgress: (current, total, message) {
          setState(() {
            _progress = (current / total) * 100;
            _statusMessage = message;
          });
        },
      );

      setState(() {
        _result = result;
        _isMigrating = false;
        if (result.exportFilePath != null) {
          _exportFile = File(result.exportFilePath!);
        }
      });

      if (result.success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog();
      }
    } catch (e) {
      setState(() {
        _result = MigrationResult(
          success: false,
          totalRecords: 0,
          successfulRecords: 0,
          failedRecords: 0,
          errors: ['Migration error: $e'],
        );
        _isMigrating = false;
      });
      _showErrorDialog();
    }
  }

  Future<void> _exportOnly() async {
    setState(() {
      _isExporting = true;
      _progress = 0.0;
      _statusMessage = 'Exporting data...';
      _result = null;
      _exportFile = null;
    });

    try {
      final file = await _migrator.exportToJson();

      setState(() {
        _exportFile = file;
        _isExporting = false;
        _progress = 100.0;
        _statusMessage = 'Export complete';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
        _result = MigrationResult(
          success: false,
          totalRecords: 0,
          successfulRecords: 0,
          failedRecords: 0,
          errors: ['Export error: $e'],
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _retryMigration() async {
    // For retry, we just call the migration again
    await _startMigration();
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Migration Successful'),
          ],
        ),
        content: Text(
          'All ${_result!.totalRecords} records have been successfully migrated to the Laravel backend.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showErrorDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Migration Failed'),
          ],
        ),
        content: Text(
          'Migration completed with errors.\n\n'
          'Successful: ${_result!.successfulRecords}\n'
          'Failed: ${_result!.failedRecords}\n\n'
          'Please check the errors and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
