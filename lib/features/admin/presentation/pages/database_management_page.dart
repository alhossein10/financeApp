import 'package:flutter/material.dart';
import '../../../../core/utils/database_utils.dart';
import '../../../../l10n/app_localizations.dart';

/// Admin page for database management
class DatabaseManagementPage extends StatefulWidget {
  const DatabaseManagementPage({super.key});

  @override
  State<DatabaseManagementPage> createState() => _DatabaseManagementPageState();
}

class _DatabaseManagementPageState extends State<DatabaseManagementPage> {
  Map<String, int>? _stats;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final stats = await DatabaseUtils.getDatabaseStats();
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)?.errorLoadingStats ?? 'Error loading stats'}: $e')),
        );
      }
    }
  }

  Future<void> _clearAllData() async {
    final l10n = AppLocalizations.of(context);
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.clearAllData ?? 'Clear All Data'),
        content: Text(
          AppLocalizations.of(context)?.clearAllDataWarning ?? 'This will delete ALL data from the database including:\n\n'
          '• All users (except default user)\n'
          '• All expenses\n'
          '• All transfers\n'
          '• All incoming transactions\n'
          '• All sessions\n\n'
          'This action CANNOT be undone!\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(AppLocalizations.of(context)?.deleteAllData ?? 'Delete All Data'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);
    
    try {
      await DatabaseUtils.clearAllData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.allDataCleared ?? '✓ All data cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Reload stats
      await _loadStats();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.errorClearingData ?? 'Error clearing data'}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.databaseManagement ?? 'Database Management'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Database Statistics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_stats != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: _stats!.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    entry.key,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    '${entry.value} records',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  const Text(
                    'Danger Zone',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Clear All Data',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'This will permanently delete all data from the database. '
                            'The database structure will remain intact, and a default user will be recreated.',
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _clearAllData,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              icon: const Icon(Icons.delete_forever),
                              label: Text(AppLocalizations.of(context)?.clearAllData ?? 'Clear All Data'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'After clearing data:\n\n'
                            '• Default user credentials:\n'
                            '  Email: default@finance.app\n'
                            '  Password: password\n\n'
                            '• You will need to log out and log back in\n\n'
                            '• All Supabase synced data will remain in the cloud',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
