import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/group_member.dart';
import 'group_member_card.dart';

/// Widget to display a list of group members with search, filter, and pagination
class GroupMemberList extends StatefulWidget {
  final List<GroupMember> members;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback? onLoadMore;
  final Function(int userId)? onRemoveMember;
  final int? currentUserId;
  final bool showRemoveButtons;

  const GroupMemberList({
    super.key,
    required this.members,
    this.isLoading = false,
    this.hasMore = false,
    this.onLoadMore,
    this.onRemoveMember,
    this.currentUserId,
    this.showRemoveButtons = true,
  });

  @override
  State<GroupMemberList> createState() => _GroupMemberListState();
}

class _GroupMemberListState extends State<GroupMemberList> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String? _selectedDepartment;
  List<String> _availableDepartments = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _updateAvailableDepartments();
  }

  @override
  void didUpdateWidget(GroupMemberList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.members != widget.members) {
      _updateAvailableDepartments();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (widget.hasMore && !widget.isLoading && widget.onLoadMore != null) {
        widget.onLoadMore!();
      }
    }
  }

  void _updateAvailableDepartments() {
    final departments = widget.members
        .where((m) => m.departmentName != null && m.departmentName!.isNotEmpty)
        .map((m) => m.departmentName!)
        .toSet()
        .toList()
      ..sort();
    
    setState(() {
      _availableDepartments = departments;
      // Reset selected department if it's no longer available
      if (_selectedDepartment != null && !_availableDepartments.contains(_selectedDepartment)) {
        _selectedDepartment = null;
      }
    });
  }

  List<GroupMember> _getFilteredMembers() {
    var filtered = widget.members;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((member) {
        final query = _searchQuery.toLowerCase();
        return member.name.toLowerCase().contains(query) ||
            member.email.toLowerCase().contains(query) ||
            (member.departmentName?.toLowerCase().contains(query) ?? false) ||
            (member.organizationName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply department filter
    if (_selectedDepartment != null) {
      filtered = filtered.where((member) {
        return member.departmentName == _selectedDepartment;
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredMembers = _getFilteredMembers();

    // Use a single ListView with all content to avoid overflow issues
    return ListView(
      controller: _scrollController,
      children: [
        // Search and filter section
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)?.searchMembers ??
                      'Search members...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              
              // Department filter
              if (_availableDepartments.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDepartment,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)?.filterByDepartment ??
                        'Filter by Department',
                    prefixIcon: const Icon(Icons.filter_list),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(
                        AppLocalizations.of(context)?.allDepartments ??
                            'All Departments',
                      ),
                    ),
                    ..._availableDepartments.map((dept) {
                      return DropdownMenuItem<String>(
                        value: dept,
                        child: Text(dept),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartment = value;
                    });
                  },
                ),
              ],
            ],
          ),
        ),

        // Results count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '${filteredMembers.length} ${AppLocalizations.of(context)?.membersCount ?? 'members'}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Member list or empty state
        if (widget.isLoading && filteredMembers.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (filteredMembers.isEmpty)
          _buildEmptyState(context)
        else
          ...filteredMembers.map((member) {
            final isCurrentUser = widget.currentUserId != null &&
                member.id == widget.currentUserId;

            return GroupMemberCard(
              member: member,
              showRemoveButton: widget.showRemoveButtons,
              isCurrentUser: isCurrentUser,
              onRemove: widget.onRemoveMember != null
                  ? () => widget.onRemoveMember!(member.id)
                  : null,
            );
          }),

        // Loading indicator for pagination
        if (widget.hasMore && filteredMembers.isNotEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    String message;
    IconData icon;
    
    if (_searchQuery.isNotEmpty || _selectedDepartment != null) {
      message = AppLocalizations.of(context)?.noMembersFound ??
          'No members found matching your filters';
      icon = Icons.search_off;
    } else if (widget.members.isEmpty && !widget.isLoading) {
      message = AppLocalizations.of(context)?.noMembersYet ??
          'No members in this group yet';
      icon = Icons.people_outline;
    } else {
      message = AppLocalizations.of(context)?.loadingMembers ??
          'Loading members...';
      icon = Icons.hourglass_empty;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty || _selectedDepartment != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedDepartment = null;
                  });
                },
                icon: const Icon(Icons.clear_all),
                label: Text(
                  AppLocalizations.of(context)?.clearFilters ??
                      'Clear Filters',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
