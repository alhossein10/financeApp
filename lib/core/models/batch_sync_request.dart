import 'batch_record.dart';

/// Model for batch sync request
class BatchSyncRequest {
  final List<BatchRecord> records;

  BatchSyncRequest({
    required this.records,
  });

  Map<String, dynamic> toJson() {
    return {
      'records': records.map((r) => r.toJson()).toList(),
    };
  }

  factory BatchSyncRequest.fromJson(Map<String, dynamic> json) {
    return BatchSyncRequest(
      records: (json['records'] as List)
          .map((r) => BatchRecord.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}
