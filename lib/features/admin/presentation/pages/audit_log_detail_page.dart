import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../../../injection_container.dart';
import '../bloc/audit_log_bloc.dart';
import '../bloc/audit_log_event.dart';
import '../bloc/audit_log_state.dart';

/// Page for displaying audit log details
class AuditLogDetailPage extends StatelessWidget {
  final int logId;

  const AuditLogDetailPage({
    super.key,
    required this.logId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AuditLogBloc>()
        ..add(FetchAuditLogDetailsRequested(logId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Audit Log Details'),
        ),
        body: BlocConsumer<AuditLogBloc, AuditLogState>(
          listener: (context, state) {
            if (state is AuditLogError) {
              if (state.requiresLogin) {
                Navigator.of(context).pushReplacementNamed('/login');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          builder: (context, state) {
            if (state is AuditLogLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is AuditLogDetailsLoaded) {
              return _AuditLogDetailContent(log: state.auditLog);
            }

            if (state is AuditLogError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<AuditLogBloc>().add(
                              FetchAuditLogDetailsRequested(logId),
                            );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return const Center(child: Text('No data'));
          },
        ),
      ),
    );
  }
}

class _AuditLogDetailContent extends StatelessWidget {
  final dynamic log;

  const _AuditLogDetailContent({required this.log});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm:ss');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            context,
            title: 'Basic Information',
            children: [
              _buildInfoRow('ID', log.id.toString()),
              _buildInfoRow('Action', log.action),
              _buildInfoRow('Entity Type', log.entityType),
              _buildInfoRow('Entity ID', log.entityId.toString()),
              _buildInfoRow('Date', dateFormat.format(log.createdAt)),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            context,
            title: 'User Information',
            children: [
              _buildInfoRow('User ID', log.userId.toString()),
              if (log.userName != null)
                _buildInfoRow('User Name', log.userName!),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            context,
            title: 'Request Information',
            children: [
              _buildInfoRow('IP Address', log.ipAddress),
              _buildInfoRow('User Agent', log.userAgent, maxLines: 3),
            ],
          ),
          if (log.changes != null && log.changes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildChangesCard(context, log.changes!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangesCard(BuildContext context, Map<String, dynamic> changes) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Changes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _formatJson(changes),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatJson(Map<String, dynamic> json) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(json);
    } catch (e) {
      return json.toString();
    }
  }
}
