import 'package:flutter/material.dart';
import '../../../../core/config/flavor_config.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../fund_box/domain/entities/fund_box.dart';
import '../../../fund_box/domain/usecases/get_fund_box_usecase.dart';
import '../../../../injection_container.dart' as di;
import 'package:intl/intl.dart';

/// Widget to display fund box balance for a group member
/// Only shows for SuperAdmin (to view Admin balances) and Admin (to view User balances)
class MemberFundBoxBalance extends StatefulWidget {
  final int userId;
  final String userRole;
  final bool isCurrentUser;

  const MemberFundBoxBalance({
    super.key,
    required this.userId,
    required this.userRole,
    this.isCurrentUser = false,
  });

  @override
  State<MemberFundBoxBalance> createState() => _MemberFundBoxBalanceState();
}

class _MemberFundBoxBalanceState extends State<MemberFundBoxBalance> {
  FundBox? _fundBox;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFundBox();
  }

  Future<void> _loadFundBox() async {
    // Only load if we should show balances
    if (!_shouldShowBalance()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final getFundBoxUseCase = di.sl<GetFundBoxUseCase>();
      final result = await getFundBoxUseCase(widget.userId);

      result.fold(
        (failure) {
          setState(() {
            _error = failure.message;
            _isLoading = false;
          });
        },
        (fundBox) {
          setState(() {
            _fundBox = fundBox;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to load balance';
        _isLoading = false;
      });
    }
  }

  bool _shouldShowBalance() {
    final flavorConfig = FlavorConfig.instance;
    
    // SuperAdmin should see Admin balances
    if (flavorConfig.isSuperAdmin) {
      return widget.userRole.toLowerCase() == 'admin';
    }
    
    // Admin should see User balances
    if (flavorConfig.isAdmin) {
      return widget.userRole.toLowerCase() == 'user';
    }
    
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Don't show if we shouldn't display balances
    if (!_shouldShowBalance()) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)?.loadingBalance ?? 'Loading balance...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 14,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    if (_fundBox == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final numberFormat = NumberFormat('#,##0.00');

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _buildBalanceChip(
                    context,
                    'USD',
                    '\$${numberFormat.format(_fundBox!.balanceUsd)}',
                    Colors.green,
                  ),
                  _buildBalanceChip(
                    context,
                    'SYP',
                    NumberFormat('#,###').format(_fundBox!.balanceSyp),
                    Colors.orange,
                  ),
                  _buildBalanceChip(
                    context,
                    'TRY',
                    NumberFormat('#,###').format(_fundBox!.balanceTry),
                    Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceChip(BuildContext context, String currency, String balance, MaterialColor color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currency,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            balance,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color.shade900,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

