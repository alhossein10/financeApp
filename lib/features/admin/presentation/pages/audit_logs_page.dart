import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/flavor_config.dart';
import '../../../../core/widgets/role_based_widget.dart';
import '../../../../injection_container.dart';
import '../bloc/audit_log_bloc.dart';
import '../bloc/audit_log_event.dart';
import '../bloc/audit_log_state.dart';
import 'audit_log_detail_page.dart';

/// Page for displaying audit logs with pagination
class AuditLogsPage extends StatelessWidget {
  const AuditLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if admin flavor is enabled
    if (!FlavorConfig.instance.enableAuditLogs) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Audit Logs'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Feature Not Available',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Audit logs are only available in the admin version.',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    // Check if user has admin role
    if (!context.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Audit Logs'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.admin_panel_settings_outlined, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Access Denied',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Admin privileges required to view audit logs.',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return BlocProvider(
      create: (context) => sl<AuditLogBloc>()
        ..add(const FetchAuditLogsRequested()),
      child: const _AuditLogsPageContent(),
    );
  }
}

class _AuditLogsPageContent extends StatefulWidget {
  const _AuditLogsPageContent();

  @override
  State<_AuditLogsPageContent> createState() => _AuditLogsPageContentState();
}

class _AuditLogsPageContentState extends State<_AuditLogsPageContent> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<AuditLogBloc>().add(const LoadMoreAuditLogsRequested());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AuditLogBloc>().add(const RefreshAuditLogsRequested());
            },
          ),
        ],
      ),
      body: BlocConsumer<AuditLogBloc, AuditLogState>(
        listener: (context, state) {
          if (state is AuditLogError) {
            if (state.requiresLogin) {
              Navigator.of(context).pushReplacementNamed('/login');
            } else if (state.isForbidden) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 5),
                ),
              );
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

          if (state is AuditLogLoaded || state is AuditLogLoadingMore) {
            final logs = state is AuditLogLoaded
                ? state.logs
                : (state as AuditLogLoadingMore).currentLogs;
            final hasMorePages =
                state is AuditLogLoaded ? state.hasMorePages : true;
            final isLoadingMore = state is AuditLogLoadingMore;

            if (logs.isEmpty) {
              return const Center(
                child: Text('No audit logs found'),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<AuditLogBloc>().add(const RefreshAuditLogsRequested());
              },
              child: ListView.builder(
                controller: _scrollController,
                itemCount: logs.length + (hasMorePages ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= logs.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final log = logs[index];
                  return _AuditLogListItem(
                    log: log,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AuditLogDetailPage(logId: log.id),
                        ),
                      );
                    },
                  );
                },
              ),
            );
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
                      context.read<AuditLogBloc>().add(const RefreshAuditLogsRequested());
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
    );
  }
}

class _AuditLogListItem extends StatelessWidget {
  final dynamic log;
  final VoidCallback onTap;

  const _AuditLogListItem({
    required this.log,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getActionColor(log.action),
          child: Icon(
            _getActionIcon(log.action),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          log.action,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${log.entityType} #${log.entityId}'),
            Text(
              'User ID: ${log.userId}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              dateFormat.format(log.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Color _getActionColor(String action) {
    if (action.contains('created')) return Colors.green;
    if (action.contains('updated')) return Colors.blue;
    if (action.contains('deleted')) return Colors.red;
    if (action.contains('login')) return Colors.purple;
    return Colors.grey;
  }

  IconData _getActionIcon(String action) {
    if (action.contains('created')) return Icons.add_circle;
    if (action.contains('updated')) return Icons.edit;
    if (action.contains('deleted')) return Icons.delete;
    if (action.contains('login')) return Icons.login;
    return Icons.info;
  }
}
