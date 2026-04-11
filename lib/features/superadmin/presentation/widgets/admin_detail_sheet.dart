import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/api_client.dart';
import '../../../../injection_container.dart' as di;
import '../../../fund_box/data/datasources/fund_box_api_datasource.dart';
import '../../../fund_box/data/models/fund_box_dto.dart';
import '../../data/models/admin_member_dto.dart';

/// Bottom sheet widget to display Admin's detailed financial information
/// Shows Admin's financial box balances in all three currencies (USD, SYP, TRY)
class AdminDetailSheet extends StatefulWidget {
  final AdminMemberDto admin;

  const AdminDetailSheet({
    super.key,
    required this.admin,
  });

  @override
  State<AdminDetailSheet> createState() => _AdminDetailSheetState();
}

class _AdminDetailSheetState extends State<AdminDetailSheet> {
  late final FundBoxApiDataSource _fundBoxDataSource;
  FundBoxDto? _fundBox;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fundBoxDataSource = FundBoxApiDataSourceImpl(
      apiClient: di.sl<ApiClient>(),
      roleService: di.sl(),
    );
    _loadFundBox();
  }

  Future<void> _loadFundBox() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fundBox = await _fundBoxDataSource.getFundBoxByUserId(widget.admin.id);
      setState(() {
        _fundBox = fundBox;
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
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Avatar with photo
                CircleAvatar(
                  radius: 32,
                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                  backgroundImage: widget.admin.profileImageUrl != null && widget.admin.profileImageUrl!.isNotEmpty
                      ? NetworkImage(widget.admin.profileImageUrl!)
                      : null,
                  child: widget.admin.profileImageUrl == null || widget.admin.profileImageUrl!.isEmpty
                      ? Icon(
                          Icons.person,
                          color: theme.primaryColor,
                          size: 36,
                        )
                      : null,
                ),
                const SizedBox(width: 16),

                // Admin Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.admin.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.admin.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (widget.admin.adminGroupName != null)
                        Text(
                          '${isArabic ? 'المجموعة:' : 'Group:'} ${widget.admin.adminGroupName}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),

                // Close Button
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Flexible(
            child: _buildContent(context, theme, isArabic),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, bool isArabic) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'خطأ في تحميل البيانات' : 'Error loading data',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadFundBox,
              icon: const Icon(Icons.refresh),
              label: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
            ),
          ],
        ),
      );
    }

    if (_fundBox == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            isArabic ? 'لا توجد بيانات' : 'No data available',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            isArabic ? 'الأرصدة المالية' : 'Financial Balances',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // USD Balance Card
          _buildBalanceCard(
            context,
            theme,
            isArabic,
            currency: 'USD',
            symbol: '\$',
            balance: _fundBox!.balanceUsd ?? 0.0,
            color: Colors.green,
          ),
          const SizedBox(height: 12),

          // SYP Balance Card
          _buildBalanceCard(
            context,
            theme,
            isArabic,
            currency: 'SYP',
            symbol: 'ل.س',
            balance: _fundBox!.balanceSyp ?? 0.0,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),

          // TRY Balance Card
          _buildBalanceCard(
            context,
            theme,
            isArabic,
            currency: 'TRY',
            symbol: '₺',
            balance: _fundBox!.balanceTry ?? 0.0,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),

          // Last Updated
          if (_fundBox!.lastCalculatedAt != null)
            Center(
              child: Text(
                '${isArabic ? 'آخر تحديث:' : 'Last updated:'} ${_formatDateTime(_fundBox!.lastCalculatedAt!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    ThemeData theme,
    bool isArabic, {
    required String currency,
    required String symbol,
    required double balance,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Currency Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Currency Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currency,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(balance, symbol),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount, String symbol) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '$symbol ${formatter.format(amount)}';
  }

  String _formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('MMM dd, yyyy HH:mm', 'en_US');
    return formatter.format(dateTime);
  }
}
