import '../utils/date_formatter.dart';

/// DTO for entity changes (created, updated, deleted)
class EntityChangesDto {
  final List<Map<String, dynamic>> created;
  final List<Map<String, dynamic>> updated;
  final List<int> deleted;

  EntityChangesDto({
    this.created = const [],
    this.updated = const [],
    this.deleted = const [],
  });

  factory EntityChangesDto.fromJson(Map<String, dynamic> json) {
    return EntityChangesDto(
      created: (json['created'] as List?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      updated: (json['updated'] as List?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      deleted:
          (json['deleted'] as List?)?.map((e) => e as int).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'created': created,
      'updated': updated,
      'deleted': deleted,
    };
  }

  bool get hasChanges =>
      created.isNotEmpty || updated.isNotEmpty || deleted.isNotEmpty;

  int get totalChanges => created.length + updated.length + deleted.length;
}

/// DTO for all changes across entity types
class ChangesDataDto {
  final EntityChangesDto expenses;
  final EntityChangesDto incoming;
  final EntityChangesDto transfers;

  ChangesDataDto({
    required this.expenses,
    required this.incoming,
    required this.transfers,
  });

  factory ChangesDataDto.fromJson(Map<String, dynamic> json) {
    return ChangesDataDto(
      expenses: EntityChangesDto.fromJson(
        json['expenses'] as Map<String, dynamic>,
      ),
      incoming: EntityChangesDto.fromJson(
        json['incoming'] as Map<String, dynamic>,
      ),
      transfers: EntityChangesDto.fromJson(
        json['transfers'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expenses': expenses.toJson(),
      'incoming': incoming.toJson(),
      'transfers': transfers.toJson(),
    };
  }

  bool get hasChanges =>
      expenses.hasChanges || incoming.hasChanges || transfers.hasChanges;

  int get totalChanges =>
      expenses.totalChanges + incoming.totalChanges + transfers.totalChanges;
}

/// DTO for sync changes response
/// Matches Laravel API specification: GET /sync/changes response
class SyncChangesDto {
  final DateTime timestamp;
  final ChangesDataDto changes;

  SyncChangesDto({
    required this.timestamp,
    required this.changes,
  });

  factory SyncChangesDto.fromJson(Map<String, dynamic> json) {
    return SyncChangesDto(
      timestamp: DateFormatter.fromApiTimestamp(json['timestamp'] as String),
      changes: ChangesDataDto.fromJson(
        json['changes'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': DateFormatter.toApiTimestamp(timestamp),
      'changes': changes.toJson(),
    };
  }
}
