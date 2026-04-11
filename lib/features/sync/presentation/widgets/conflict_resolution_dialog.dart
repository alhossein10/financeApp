import 'package:flutter/material.dart';
import '../../../../core/models/conflict_resolution.dart';
import '../../../../core/models/sync_response_dto.dart';

/// Dialog for resolving sync conflicts from batch sync
class ConflictResolutionDialog extends StatefulWidget {
  final ConflictItemDto conflict;
  final String entityType; // 'expense', 'incoming', 'transfer'
  final Function(ConflictStrategy strategy, Map<String, dynamic>? data) onResolve;

  const ConflictResolutionDialog({
    super.key,
    required this.conflict,
    required this.entityType,
    required this.onResolve,
  });

  @override
  State<ConflictResolutionDialog> createState() => 
      _ConflictResolutionDialogState();
}

class _ConflictResolutionDialogState extends State<ConflictResolutionDialog> {
  ConflictStrategy _selectedStrategy = ConflictStrategy.serverWins;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sync Conflict Detected'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A conflict was detected for ${widget.entityType}.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Reason: ${widget.conflict.reason}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red[700],
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Server version:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildDataPreview(widget.conflict.serverData),
            const SizedBox(height: 16),
            Text(
              'Local version:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildDataPreview(widget.conflict.localData),
            const SizedBox(height: 16),
            Text(
              'Choose resolution strategy:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            RadioListTile<ConflictStrategy>(
              title: const Text('Use server version'),
              subtitle: const Text('Keep the version from the server'),
              value: ConflictStrategy.serverWins,
              groupValue: _selectedStrategy,
              onChanged: (value) {
                setState(() {
                  _selectedStrategy = value!;
                });
              },
            ),
            RadioListTile<ConflictStrategy>(
              title: const Text('Use local version'),
              subtitle: const Text('Keep your local changes'),
              value: ConflictStrategy.clientWins,
              groupValue: _selectedStrategy,
              onChanged: (value) {
                setState(() {
                  _selectedStrategy = value!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onResolve(_selectedStrategy, null);
            Navigator.of(context).pop();
          },
          child: const Text('Resolve'),
        ),
      ],
    );
  }

  Widget _buildDataPreview(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.entries.take(5).map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '${entry.key}: ${entry.value}',
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
      ),
    );
  }

}

/// Widget to show a list of conflicts for batch resolution
class ConflictListDialog extends StatelessWidget {
  final List<ConflictItemDto> conflicts;
  final String entityType;
  final Function(int index, ConflictStrategy strategy) onResolve;

  const ConflictListDialog({
    super.key,
    required this.conflicts,
    required this.entityType,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${conflicts.length} Conflicts Detected'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: conflicts.length,
          itemBuilder: (context, index) {
            final conflict = conflicts[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text('$entityType Conflict ${index + 1}'),
                subtitle: Text(conflict.reason),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.cloud),
                      tooltip: 'Use server version',
                      onPressed: () {
                        onResolve(index, ConflictStrategy.serverWins);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone_android),
                      tooltip: 'Use local version',
                      onPressed: () {
                        onResolve(index, ConflictStrategy.clientWins);
                      },
                    ),
                  ],
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => ConflictResolutionDialog(
                      conflict: conflict,
                      entityType: entityType,
                      onResolve: (strategy, data) {
                        onResolve(index, strategy);
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            // Resolve all with server wins
            for (int i = 0; i < conflicts.length; i++) {
              onResolve(i, ConflictStrategy.serverWins);
            }
            Navigator.of(context).pop();
          },
          child: const Text('Use Server for All'),
        ),
        ElevatedButton(
          onPressed: () {
            // Resolve all with client wins
            for (int i = 0; i < conflicts.length; i++) {
              onResolve(i, ConflictStrategy.clientWins);
            }
            Navigator.of(context).pop();
          },
          child: const Text('Use Local for All'),
        ),
      ],
    );
  }
}
