/// Model for a single record in a batch sync request
class BatchRecord {
  final String type; // 'expense', 'transfer', 'incoming'
  final String action; // 'create', 'update', 'delete'
  final int? id;
  final Map<String, dynamic> data;
  final String? localId; // Temporary local ID for offline records

  BatchRecord({
    required this.type,
    required this.action,
    this.id,
    required this.data,
    this.localId,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'action': action,
      if (id != null) 'id': id,
      'data': data,
      if (localId != null) 'local_id': localId,
    };
  }

  factory BatchRecord.fromJson(Map<String, dynamic> json) {
    return BatchRecord(
      type: json['type'] as String,
      action: json['action'] as String,
      id: json['id'] as int?,
      data: json['data'] as Map<String, dynamic>,
      localId: json['local_id'] as String?,
    );
  }
}
