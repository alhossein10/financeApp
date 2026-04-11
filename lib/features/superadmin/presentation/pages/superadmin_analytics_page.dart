import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../injection_container.dart' as di;
import '../../data/datasources/superadmin_analytics_api_datasource.dart';
import '../../data/models/superadmin_analytics_dto.dart';
import '../../services/analytics_export_service.dart';
import '../widgets/global_summary_card.dart';
import '../widgets/admin_group_analytics_card.dart';

/// SuperAdmin Analytics Page
/// Displays aggregated analytics for all admin groups
class SuperAdminAnalyticsPage extends StatefulWidget {
  const SuperAdminAnalyticsPage({super.key});

  @override
  State<SuperAdminAnalyticsPage> createState() => _SuperAdminAnalyticsPageState();
}

class _SuperAdminAnalyticsPageState extends State<SuperAdminAnalyticsPage> {
  late final SuperAdminAnalyticsApiDatasource _datasource;
  late final AnalyticsExportService _exportService;
  String _selectedPeriod = 'all';
  int? _selectedAdminGroupId;
  SuperAdminAnalyticsDto? _analytics;
  bool _isLoading = false;
  bool _isExporting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _datasource = SuperAdminAnalyticsApiDatasource(
      apiClient: di.sl<ApiClient>(),
    );
    _exportService = AnalyticsExportService();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final analytics = await _datasource.getAnalytics(period: _selectedPeriod);
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'تحليلات SuperAdmin' : 'SuperAdmin Analytics'),
        centerTitle: true,
        actions: [
          // Export buttons
          if (_analytics != null && _analytics!.adminGroups.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: isArabic ? 'تصدير إلى PDF' : 'Export to PDF',
              onPressed: () => _exportToPdf(context, isArabic),
            ),
            IconButton(
              icon: const Icon(Icons.table_chart),
              tooltip: isArabic ? 'تصدير إلى Excel' : 'Export to Excel',
              onPressed: () => _exportToExcel(context, isArabic),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.cardColor,
            child: Column(
              children: [
                // Period Filter
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'الفترة:' : 'Period:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _selectedPeriod,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: '15days',
                          child: Text(isArabic ? '15 يوم' : '15 Days'),
                        ),
                        DropdownMenuItem(
                          value: 'month',
                          child: Text(isArabic ? 'شهر' : 'Month'),
                        ),
                        DropdownMenuItem(
                          value: 'all',
                          child: Text(isArabic ? 'الكل' : 'All Time'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null && value != _selectedPeriod) {
                          setState(() {
                            _selectedPeriod = value;
                          });
                          _loadAnalytics();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Admin Group Filter
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'مجموعة المسؤول:' : 'Admin Group:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<int?>(
                      value: _selectedAdminGroupId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text(
                            isArabic ? 'الكل' : 'All Groups',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_analytics != null)
                          ..._analytics!.adminGroups.map((group) {
                            return DropdownMenuItem<int?>(
                              value: group.adminGroupId,
                              child: Text(
                                group.adminGroupName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedAdminGroupId = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _buildContent(context, isArabic),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isArabic) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'خطأ في تحميل التحليلات' : 'Error loading analytics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAnalytics,
              icon: const Icon(Icons.refresh),
              label: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
            ),
          ],
        ),
      );
    }

    if (_analytics == null || _analytics!.adminGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'لا توجد بيانات تحليلية متاحة' : 'No analytics data available',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              isArabic
                  ? 'لا توجد مجموعات إدارية بعد'
                  : 'No admin groups yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      );
    }

    // Filter admin groups if a specific group is selected
    final filteredGroups = _selectedAdminGroupId == null
        ? _analytics!.adminGroups
        : _analytics!.adminGroups
            .where((group) => group.adminGroupId == _selectedAdminGroupId)
            .toList();

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          // Global Summary Card
          GlobalSummaryCard(adminGroups: filteredGroups),
          
          const SizedBox(height: 8),
          
          // Admin Group Analytics Cards
          ...filteredGroups.map((group) {
            return AdminGroupAnalyticsCard(group: group);
          }),
        ],
      ),
    );
  }

  /// Export analytics to PDF
  Future<void> _exportToPdf(BuildContext context, bool isArabic) async {
    if (_isExporting || _analytics == null) return;

    setState(() => _isExporting = true);

    try {
      // Show loading snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                isArabic
                    ? 'جاري تصدير التحليلات إلى PDF...'
                    : 'Exporting analytics to PDF...',
              ),
            ],
          ),
          duration: const Duration(seconds: 30),
        ),
      );

      // Get filtered groups
      final filteredGroups = _selectedAdminGroupId == null
          ? _analytics!.adminGroups
          : _analytics!.adminGroups
              .where((group) => group.adminGroupId == _selectedAdminGroupId)
              .toList();

      // Export to PDF
      final filePath = await _exportService.exportToPdf(
        adminGroups: filteredGroups,
        period: _selectedPeriod,
        generatedAt: _analytics!.generatedAt,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Show success dialog with options
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(isArabic ? 'تم التصدير بنجاح' : 'Export Successful'),
            content: Text(
              isArabic
                  ? 'تم تصدير التحليلات إلى PDF بنجاح'
                  : 'Analytics exported to PDF successfully',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(isArabic ? 'إغلاق' : 'Close'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _exportService.shareFile(
                    filePath,
                    'analytics_report.pdf',
                  );
                },
                child: Text(isArabic ? 'مشاركة' : 'Share'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _exportService.openFile(filePath);
                },
                child: Text(isArabic ? 'فتح' : 'Open'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'فشل تصدير PDF: ${e.toString()}'
                  : 'PDF export failed: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  /// Export analytics to Excel
  Future<void> _exportToExcel(BuildContext context, bool isArabic) async {
    if (_isExporting || _analytics == null) return;

    setState(() => _isExporting = true);

    try {
      // Show loading snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                isArabic
                    ? 'جاري تصدير التحليلات إلى Excel...'
                    : 'Exporting analytics to Excel...',
              ),
            ],
          ),
          duration: const Duration(seconds: 30),
        ),
      );

      // Get filtered groups
      final filteredGroups = _selectedAdminGroupId == null
          ? _analytics!.adminGroups
          : _analytics!.adminGroups
              .where((group) => group.adminGroupId == _selectedAdminGroupId)
              .toList();

      // Export to Excel
      final filePath = await _exportService.exportToExcel(
        adminGroups: filteredGroups,
        period: _selectedPeriod,
        generatedAt: _analytics!.generatedAt,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Show success dialog with options
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(isArabic ? 'تم التصدير بنجاح' : 'Export Successful'),
            content: Text(
              isArabic
                  ? 'تم تصدير التحليلات إلى Excel بنجاح'
                  : 'Analytics exported to Excel successfully',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(isArabic ? 'إغلاق' : 'Close'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _exportService.shareFile(
                    filePath,
                    'analytics_report.xlsx',
                  );
                },
                child: Text(isArabic ? 'مشاركة' : 'Share'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _exportService.openFile(filePath);
                },
                child: Text(isArabic ? 'فتح' : 'Open'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'فشل تصدير Excel: ${e.toString()}'
                  : 'Excel export failed: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }
}
