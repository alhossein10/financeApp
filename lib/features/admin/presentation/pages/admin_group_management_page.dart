import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/api/api_client.dart';
import '../../../../injection_container.dart' as di;
import '../../../admin_group/data/datasources/admin_group_api_datasource.dart';
import '../../../admin_group/data/models/admin_group_dto.dart';
import '../../../admin_group/data/models/group_member_dto.dart';
import '../widgets/user_list_card.dart';
import '../widgets/user_detail_sheet.dart';

/// Admin Group Management Page
/// Displays group info and manages user members
/// 
/// Requirements: 8.1, 8.5, 8.6, 8.7, 8.8
class AdminGroupManagementPage extends StatefulWidget {
  const AdminGroupManagementPage({super.key});

  @override
  State<AdminGroupManagementPage> createState() => _AdminGroupManagementPageState();
}

class _AdminGroupManagementPageState extends State<AdminGroupManagementPage> {
  late final AdminGroupApiDataSource _datasource;
  AdminGroupDto? _groupInfo;
  List<GroupMemberDto> _members = [];
  bool _isLoadingGroup = false;
  bool _isLoadingMembers = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _datasource = AdminGroupApiDataSourceImpl(
      apiClient: di.sl<ApiClient>(),
      roleService: di.sl(),
      tokenManager: di.sl(),
    );
    _loadGroupInfo();
    _loadMembers();
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
      final groupInfo = await _datasource.getAdminGroup();
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
      final response = await _datasource.getGroupMembers(page: 1);
      setState(() {
        _members = response.data;
        _hasMore = response.currentPage < response.lastPage;
        _isLoadingMembers = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingMembers = false;
      });
    }
  }

  Future<void> _loadMoreMembers() async {
    if (_isLoadingMembers || !_hasMore) return;

    setState(() {
      _isLoadingMembers = true;
    });

    try {
      final response = await _datasource.getGroupMembers(page: _currentPage + 1);
      setState(() {
        _members.addAll(response.data);
        _currentPage++;
        _hasMore = response.currentPage < response.lastPage;
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
      final newGroupInfo = await _datasource.regenerateGroupCode();
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

  Future<void> _removeMember(GroupMemberDto member) async {
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
        title: Text(isArabic ? 'إدارة مجموعة Admin' : 'Admin Group Management'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadGroupInfo(),
            _loadMembers(),
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

        // Members Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isArabic ? 'أعضاء المجموعة' : 'Group Members',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_groupInfo != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_groupInfo!.membersCount ?? _members.length} ${isArabic ? 'عضو' : 'members'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Members List
        if (_members.isEmpty && !_isLoadingMembers)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isArabic ? 'لا يوجد مستخدمين في مجموعتك بعد' : 'No users in your group yet',
                    style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._members.map((member) => _buildMemberCard(context, member, isArabic, theme)),

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
                        _groupInfo!.groupName ?? (isArabic ? 'مجموعتي' : 'My Group'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_groupInfo!.membersCount ?? 0} ${isArabic ? 'عضو' : 'members'}',
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

  Widget _buildMemberCard(
    BuildContext context,
    GroupMemberDto member,
    bool isArabic,
    ThemeData theme,
  ) {
    return UserListCard(
      user: member,
      onTap: () => _showUserDetails(context, member),
      onRemove: () => _removeMember(member),
      // Note: Balance data would need to be fetched separately or included in the API response
      // For now, we'll pass null and the card will show "Tap to view details"
    );
  }

  void _showUserDetails(BuildContext context, GroupMemberDto user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => UserDetailSheet(
          user: user,
        ),
      ),
    );
  }
}
