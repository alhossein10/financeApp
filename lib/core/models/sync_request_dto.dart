import '../utils/date_formatter.dart';

/// DTO for batch sync request data arrays
class SyncDataDto {
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> incoming;
  final List<Map<String, dynamic>> transfers;

  SyncDataDto({
    this.expenses = const [],
    this.incoming = const [],
    this.transfers = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'expenses': expenses,
      'incoming': incoming,
      'transfers': transfers,
    };
  }

  factory SyncDataDto.fromJson(Map<String, dynamic> json) {
    return SyncDataDto(
      expenses: (json['expenses'] as List?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      incoming: (json['incoming'] as List?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      transfers: (json['transfers'] as List?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }

  bool get isEmpty =>
      expenses.isEmpty && incoming.isEmpty && transfers.isEmpty;

  int get totalCount => expenses.length + incoming.length + transfers.length;
}

/// DTO for batch sync request
/// Matches Laravel API specification: POST /sync/batch
class SyncRequestDto {
  final DateTime lastSync;
  final SyncDataDto data;

  SyncRequestDto({
    required this.lastSync,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'last_sync': DateFormatter.toApiTimestamp(lastSync),
      'data': data.toJson(),
    };
  }

  factory SyncRequestDto.fromJson(Map<String, dynamic> json) {
    return SyncRequestDto(
      lastSync: DateFormatter.fromApiTimestamp(json['last_sync'] as String),
      data: SyncDataDto.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}
