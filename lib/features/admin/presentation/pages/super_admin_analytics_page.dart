import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/super_admin_analytics_bloc.dart';
import '../bloc/super_admin_analytics_event.dart';
import '../bloc/super_admin_analytics_state.dart';
import '../../domain/entities/super_admin_analytics.dart';
import 'package:intl/intl.dart';

class SuperAdminAnalyticsPage extends StatefulWidget {
  const SuperAdminAnalyticsPage({super.key});

  @override
  State<SuperAdminAnalyticsPage> createState() => _SuperAdminAnalyticsPageState();
}

class _SuperAdminAnalyticsPageState extends State<SuperAdminAnalyticsPage> {
  String selectedPeriod = 'month'; // '15days', 'month', 'all'

  @override
  void initState() {
    super.initState();
    // Load analytics on page load
    context.read<SuperAdminAnalyticsBloc>().add(
      LoadSuperAdminAnalyticsEvent(selectedPeriod),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SuperAdmin Analytics'),
      ),
      body: Column(
        children: [
          // Period Filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: '15days', label: Text('15 Days')),
                ButtonSegment(value: 'month', label: Text('Month')),
                ButtonSegment(value: 'all', label: Text('All Time')),
              ],
              selected: {selectedPeriod},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  selectedPeriod = newSelection.first;
                });
                context.read<SuperAdminAnalyticsBloc>().add(
                  LoadSuperAdminAnalyticsEvent(selectedPeriod),
                );
              },
            ),
          ),

          // Analytics Content
          Expanded(
            child: BlocBuilder<SuperAdminAnalyticsBloc, SuperAdminAnalyticsState>(
              builder: (context, state) {
                if (state is SuperAdminAnalyticsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is SuperAdminAnalyticsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          state.isForbidden
                              ? Icons.lock_outline
                              : Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        if (state.isForbidden) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'SuperAdmin access required',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                if (state is SuperAdminAnalyticsLoaded) {
                  final analytics = state.analytics;

                  if (analytics.adminGroups.isEmpty) {
                    return const Center(
                      child: Text('No admin groups found'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: analytics.adminGroups.length,
                    itemBuilder: (context, index) {
                      final groupAnalytics = analytics.adminGroups[index];
                      return AdminGroupAnalyticsCard(
                        analytics: groupAnalytics,
                      );
                    },
                  );
                }

                return const Center(child: Text('No data'));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AdminGroupAnalyticsCard extends StatelessWidget {
  final AdminGroupAnalytics analytics;

  const AdminGroupAnalyticsCard({
    super.key,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Group Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        analytics.adminGroup.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Code: ${analytics.adminGroup.code}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Admin: ${analytics.adminGroup.adminUser.name}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Statistics
            Row(
              children: [
                // Transfers Stats
                Expanded(
                  child: _StatCard(
                    title: 'Transfers',
                    count: analytics.transfers.count,
                    total: analytics.transfers.totalUsd,
                    currency: 'USD',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                // Expenses Stats
                Expanded(
                  child: _StatCard(
                    title: 'Expenses',
                    count: analytics.expenses.count,
                    totalUsd: analytics.expenses.totalUsd,
                    totalSyp: analytics.expenses.totalSyp,
                    totalTry: analytics.expenses.totalTry,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final double? total;
  final double? totalUsd;
  final double? totalSyp;
  final double? totalTry;
  final String? currency;
  final Color color;

  const _StatCard({
    required this.title,
    required this.count,
    this.total,
    this.totalUsd,
    this.totalSyp,
    this.totalTry,
    this.currency,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final numberFormat = NumberFormat('#,###');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (total != null && currency != null)
            Text(
              currencyFormat.format(total),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            )
          else if (totalUsd != null || totalSyp != null || totalTry != null) ...[
            if (totalUsd != null && totalUsd! > 0)
              Text(
                'USD: ${currencyFormat.format(totalUsd)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            if (totalSyp != null && totalSyp! > 0)
              Text(
                'SYP: ${numberFormat.format(totalSyp)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            if (totalTry != null && totalTry! > 0)
              Text(
                'TRY: ${numberFormat.format(totalTry)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

