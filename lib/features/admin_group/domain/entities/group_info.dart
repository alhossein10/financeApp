import 'package:equatable/equatable.dart';

/// GroupInfo entity representing a user's group information
/// This is the information a regular user sees about their group
class GroupInfo extends Equatable {
  final String groupCode;
  final String? groupName;
  final String adminName;
  final String adminEmail;
  final int membersCount;
  final DateTime joinedAt;

  const GroupInfo({
    required this.groupCode,
    this.groupName,
    required this.adminName,
    required this.adminEmail,
    required this.membersCount,
    required this.joinedAt,
  });

  /// Create a copy of GroupInfo with updated fields
  GroupInfo copyWith({
    String? groupCode,
    String? groupName,
    String? adminName,
    String? adminEmail,
    int? membersCount,
    DateTime? joinedAt,
  }) {
    return GroupInfo(
      groupCode: groupCode ?? this.groupCode,
      groupName: groupName ?? this.groupName,
      adminName: adminName ?? this.adminName,
      adminEmail: adminEmail ?? this.adminEmail,
      membersCount: membersCount ?? this.membersCount,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  @override
  List<Object?> get props => [
        groupCode,
        groupName,
        adminName,
        adminEmail,
        membersCount,
        joinedAt,
      ];
}
