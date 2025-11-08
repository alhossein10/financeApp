import '../utils/date_formatter.dart';

/// DTO for created item in sync response
class CreatedItemDto {
  final String localId;
  final int serverId;
  final Map<String, dynamic> data;

  CreatedItemDto({
    required this.localId,
    required this.serverId,
    required this.data,
  });

  factory CreatedItemDto.fromJson(Map<String, dynamic> json) {
    return CreatedItemDto(
      localId: json['local_id'] as String,
      serverId: json['server_id'] as int,
      data: json['data'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'local_id': localId,
      'server_id': serverId,
      'data': data,
    };
  }
}

/// DTO for conflict item in sync response
class ConflictItemDto {
  final String? localId;
  final int? serverId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> serverData;
  final String reason;

  ConflictItemDto({
    this.localId,
    this.serverId,
    required this.localData,
    required this.serverData,
    required this.reason,
  });

  factory ConflictItemDto.fromJson(Map<String, dynamic> json) {
    return ConflictItemDto(
      localId: json['local_id'] as String?,
      serverId: json['server_id'] as int?,
      localData: json['local_data'] as Map<String, dynamic>,
      serverData: json['server_data'] as Map<String, dynamic>,
      reason: json['reason'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (localId != null) 'local_id': localId,
      if (serverId != null) 'server_id': serverId,
      'local_data': localData,
      'server_data': serverData,
      'reason': reason,
    };
  }
}

/// DTO for entity sync result (expenses, incoming, or transfers)
class EntitySyncResultDto {
  final List<CreatedItemDto> created;
  final List<ConflictItemDto> conflicts;

  EntitySyncResultDto({
    this.created = const [],
    this.conflicts = const [],
  });

  factory EntitySyncResultDto.fromJson(Map<String, dynamic> json) {
    return EntitySyncResultDto(
      created: (json['created'] as List?)
              ?.map((e) => CreatedItemDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      conflicts: (json['conflicts'] as List?)
              ?.map((e) => ConflictItemDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'created': created.map((e) => e.toJson()).toList(),
      'conflicts': conflicts.map((e) => e.toJson()).toList(),
    };
  }

  bool get hasConflicts => conflicts.isNotEmpty;
  bool get hasCreated => created.isNotEmpty;
  int get totalCreated => created.length;
  int get totalConflicts => conflicts.length;
}

/// DTO for batch sync response
/// Matches Laravel API specification: POST /sync/batch response
class SyncResponseDto {
  final DateTime syncedAt;
  final EntitySyncResultDto expenses;
  final EntitySyncResultDto incoming;
  final EntitySyncResultDto transfers;

  SyncResponseDto({
    required this.syncedAt,
    required this.expenses,
    required this.incoming,
    required this.transfers,
  });

  factory SyncResponseDto.fromJson(Map<String, dynamic> json) {
    return SyncResponseDto(
      syncedAt: DateFormatter.fromApiTimestamp(json['synced_at'] as String),
      expenses: EntitySyncResultDto.fromJson(
        json['expenses'] as Map<String, dynamic>,
      ),
      incoming: json.containsKey('incoming')
          ? EntitySyncResultDto.fromJson(
              json['incoming'] as Map<String, dynamic>,
            )
          : EntitySyncResultDto(),
      transfers: json.containsKey('transfers')
          ? EntitySyncResultDto.fromJson(
              json['transfers'] as Map<String, dynamic>,
            )
          : EntitySyncResultDto(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'synced_at': DateFormatter.toApiTimestamp(syncedAt),
      'expenses': expenses.toJson(),
      'incoming': incoming.toJson(),
      'transfers': transfers.toJson(),
    };
  }

  bool get hasConflicts =>
      expenses.hasConflicts ||
      incoming.hasConflicts ||
      transfers.hasConflicts;

  int get totalConflicts =>
      expenses.totalConflicts +
      incoming.totalConflicts +
      transfers.totalConflicts;

  int get totalCreated =>
      expenses.totalCreated + incoming.totalCreated + transfers.totalCreated;

  List<ConflictItemDto> get allConflicts => [
        ...expenses.conflicts,
        ...incoming.conflicts,
        ...transfers.conflicts,
      ];
}
