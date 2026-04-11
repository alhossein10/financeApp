import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/api/api_client.dart';
import '../../../../injection_container.dart' as di;
import '../../data/datasources/superadmin_group_api_datasource.dart';
import '../../data/datasources/superadmin_analytics_api_datasource.dart';
import '../../data/models/superadmin_group_dto.dart';
import '../../data/models/admin_member_dto.dart';
import '../../data/models/superadmin_analytics_dto.dart';
import '../widgets/admin_list_card.dart';
import '../widgets/admin_detail_sheet.dart';

/// SuperAdmin Group Management Page
/// Displays group info and manages admin members
class SuperAdminGroupManagementPage extends StatefulWidget {
  const SuperAdminGroupManagementPage({super.key});

  @override
  State<SuperAdminGroupManagementPage> createState() => _SuperAdminGroupManagementPageState();
}

class _SuperAdminGroupManagementPageState extends State<SuperAdminGroupManagementPage> {
  late final SuperAdminGroupApiDatasource _datasource;
  late final SuperAdminAnalyticsApiDatasource _analyticsDatasource;
  SuperAdminGroupDto? _groupInfo;
  List<AdminMemberDto> _members = [];
  SuperAdminAnalyticsDto? _analytics;
  bool _isLoadingGroup = false;
  bool _isLoadingMembers = false;
  bool _isLoadingAnalytics = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _datasource = SuperAdminGroupApiDatasource(
      apiClient: di.sl<ApiClient>(),
    );
    _analyticsDatasource = SuperAdminAnalyticsApiDatasource(
      apiClient: di.sl<ApiClient>(),
    );
    _loadGroupInfo();
    _loadMembers();
    _loadAnalytics();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoadingMembers && _hasMore) {
        _loadMoreMembers();
      }
    }
  }

  Future<void> _loadGroupInfo() async {
    setState(() {
      _isLoadingGroup = true;
      _errorMessage = null;
    });

    try {
      final groupInfo = await _datasource.getGroupInfo();
      setState(() {
        _groupInfo = groupInfo;
        _isLoadingGroup = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingGroup = false;
      });
    }
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoadingMembers = true;
      _errorMessage = null;
      _currentPage = 1;
      _members = [];
    });

    try {
      final response = await _datasource.getMembers(page: 1);
      setState(() {
        _members = response.data;
        _hasMore = response.hasMore;
        _isLoadingMembers = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingMembers = false;
      });
    }
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoadingAnalytics = true;
    });

    try {
      final analytics = await _analyticsDatasource.getAnalytics(period: 'all');
      setState(() {
        _analytics = analytics;
        _isLoadingAnalytics = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAnalytics = false;
      });
    }
  }

  Future<void> _loadMoreMembers() async {
    if (_isLoadingMembers || !_hasMore) return;

    setState(() {
      _isLoadingMembers = true;
    });

    try {
      final response = await _datasource.getMembers(page: _currentPage + 1);
      setState(() {
        _members.addAll(response.data);
        _currentPage++;
        _hasMore = response.hasMore;
        _isLoadingMembers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMembers = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading more members: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _regenerateCode() async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'تأكيد إعادة إنشاء الرمز' : 'Confirm Code Regeneration'),
        content: Text(
          isArabic
              ? 'هل أنت متأكد من إعادة إنشاء رمز المجموعة؟ سيصبح الرمز القديم غير صالح.'
              : 'Are you sure you want to regenerate the group code? The old code will become invalid.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: Text(isArabic ? 'إعادة إنشاء' : 'Regenerate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final newGroupInfo = await _datasource.regenerateCode();
      setState(() {
        _groupInfo = newGroupInfo;
      });

      if (mounted) {
        // Show new code dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(isArabic ? 'رمز جديد' : 'New Code'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isArabic ? 'رمز المجموعة الجديد:' : 'New group code:',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  child: SelectableText(
                    newGroupInfo.groupCode,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          fontFamily: 'monospace',
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: newGroupInfo.groupCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isArabic ? 'تم نسخ الرمز!' : 'Code copied!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: Text(isArabic ? 'نسخ' : 'Copy'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(isArabic ? 'إغلاق' : 'Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error regenerating code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeMember(AdminMemberDto member) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'تأكيد الإزالة' : 'Confirm Removal'),
        content: Text(
          isArabic
              ? 'هل أنت متأكد من إزالة ${member.name} من المجموعة؟'
              : 'Are you sure you want to remove ${member.name} from the group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(isArabic ? 'إزالة' : 'Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _datasource.removeMember(member.id);
      
      // Refresh member list
      await _loadMembers();
      await _loadGroupInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? 'تم إزالة العضو بنجاح' : 'Member removed successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing member: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'إدارة مجموعة SuperAdmin' : 'SuperAdmin Group Management'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadGroupInfo(),
            _loadMembers(),
            _loadAnalytics(),
          ]);
        },
        child: _buildContent(context, isArabic, theme),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isArabic, ThemeData theme) {
    if (_isLoadingGroup && _groupInfo == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null && _groupInfo == null) {
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
              isArabic ? 'خطأ في تحميل البيانات' : 'Error loading data',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _loadGroupInfo();
                _loadMembers();
                _loadAnalytics();
              },
              icon: const Icon(Icons.refresh),
              label: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
            ),
          ],
        ),
      );
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        // Group Info Card
        if (_groupInfo != null) _buildGroupInfoCard(context, isArabic, theme),
        const SizedBox(height: 16),

        // Members Section with Balances
        Text(
          isArabic ? 'المسؤولون في المجموعة' : 'Admins in Group',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          isArabic 
              ? '${_groupInfo?.memberCount ?? 0} مسؤول' 
              : '${_groupInfo?.memberCount ?? 0} admins',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),

        // Members List with Balance Cards
        if (_members.isEmpty && !_isLoadingMembers)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                isArabic ? 'لا يوجد مسؤولون' : 'No admins',
                style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ),
          )
        else
          ..._members.map((member) => _buildAdminBalanceCard(context, member, isArabic, theme)),

        // Loading indicator for pagination
        if (_isLoadingMembers)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildGroupInfoCard(BuildContext context, bool isArabic, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Name
            Row(
              children: [
                Icon(
                  Icons.group,
                  color: theme.primaryColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _groupInfo!.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_groupInfo!.memberCount} ${isArabic ? 'عضو' : 'members'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Group Code
            Text(
              isArabic ? 'رمز المجموعة' : 'Group Code',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.primaryColor,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      _groupInfo!.groupCode,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _groupInfo!.groupCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isArabic ? 'تم نسخ الرمز!' : 'Code copied!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Regenerate Code Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _regenerateCode,
                icon: const Icon(Icons.refresh),
                label: Text(isArabic ? 'إعادة إنشاء الرمز' : 'Regenerate Code'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminBalanceCard(
    BuildContext context,
    AdminMemberDto member,
    bool isArabic,
    ThemeData theme,
  ) {
    // Find analytics for this admin
    AdminGroupAnalyticsData? adminAnalytics;
    if (_analytics != null) {
      try {
        adminAnalytics = _analytics!.adminGroups.firstWhere(
          (group) => group.adminUserId == member.id,
        );
      } catch (e) {
        // Admin not found in analytics
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showAdminDetails(context, member),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Admin Name and Email
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          member.email,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _removeMember(member),
                    tooltip: isArabic ? 'إزالة' : 'Remove',
                  ),
                ],
              ),
              
              if (adminAnalytics != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                
                // Total Balances in All Currencies
                Text(
                  isArabic ? 'الأرصدة الإجمالية:' : 'Total Balances:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Balance Row
                Row(
                  children: [
                    Expanded(
                      child: _buildBalanceChip(
                        'USD',
                        adminAnalytics.totalBalanceUsd,
                        Colors.green,
                        theme,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildBalanceChip(
                        'SYP',
                        adminAnalytics.totalBalanceSyp,
                        Colors.blue,
                        theme,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildBalanceChip(
                        'TRY',
                        adminAnalytics.totalBalanceTry,
                        Colors.orange,
                        theme,
                      ),
                    ),
                  ],
                ),
              ] else if (_isLoadingAnalytics) ...[
                const SizedBox(height: 16),
                const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceChip(
    String currency,
    double amount,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            currency,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount.toStringAsFixed(2),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showAdminDetails(BuildContext context, AdminMemberDto admin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => AdminDetailSheet(
          admin: admin,
        ),
      ),
    );
  }
}
