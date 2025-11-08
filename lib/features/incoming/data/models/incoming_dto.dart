import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/incoming.dart';
import 'incoming_model.dart';

/// Data Transfer Object for Incoming API communication
/// Handles JSON serialization/deserialization for Laravel API
class IncomingDto {
  final int? id;
  final int? userId;
  final double amountUsd;
  final String source;
  final String? description;
  final String date; // YYYY-MM-DD format
  final String paymentMethod; // cash, card, bank_transfer
  final String? sourceType; // 'incoming' or 'transfer' - indicates if this is from incoming table or transfers table
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const IncomingDto({
    this.id,
    this.userId,
    required this.amountUsd,
    required this.source,
    this.description,
    required this.date,
    required this.paymentMethod,
    this.sourceType,
    this.createdAt,
    this.updatedAt,
  });

  /// Valid payment methods according to API spec
  static const validPaymentMethods = ['cash', 'card', 'bank_transfer'];

  /// Validate payment method
  void validate() {
    if (!validPaymentMethods.contains(paymentMethod)) {
      throw ArgumentError('Invalid payment method: $paymentMethod. Must be one of: ${validPaymentMethods.join(", ")}');
    }
  }

  /// Create DTO from JSON response from Laravel API
  factory IncomingDto.fromJson(Map<String, dynamic> json) {
    return IncomingDto(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      amountUsd: _parseDouble(json['amount_usd']) ?? 0.0,
      source: json['source'] as String? ?? '',
      description: json['description'] as String?,
      date: _parseDateField(json['incoming_date'] ?? json['date'] ?? json['transfer_date']),
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      sourceType: json['source_type'] as String?, // 'incoming' or 'transfer'
      createdAt: DateFormatter.fromApiTimestampNullable(json['created_at'] as String?),
      updatedAt: DateFormatter.fromApiTimestampNullable(json['updated_at'] as String?),
    );
  }
  
  /// Check if this is a transfer (from transfers table) vs incoming (from incoming table)
  bool get isTransfer => sourceType == 'transfer';
  
  /// Check if this is a regular incoming record
  bool get isIncoming => sourceType == null || sourceType == 'incoming';

  /// Convert DTO to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'amount_usd': amountUsd,
      'source': source,
      if (description != null) 'description': description,
      'incoming_date': date,
      'payment_method': paymentMethod,
    };
  }

  /// Convert DTO to domain entity (IncomingModel)
  IncomingModel toEntity() {
    return IncomingModel(
      id: id,
      userId: userId ?? 0,
      description: description ?? '',
      amountUsd: amountUsd,
      transactionDate: DateFormatter.fromApiDate(date),
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt,
    );
  }

  /// Create DTO from domain entity
  factory IncomingDto.fromEntity(Incoming incoming, {String paymentMethod = 'cash'}) {
    return IncomingDto(
      id: incoming.id,
      userId: incoming.userId,
      amountUsd: incoming.amountUsd,
      source: incoming.description, // Use description as source for now
      description: incoming.description,
      date: DateFormatter.toApiDate(incoming.transactionDate),
      paymentMethod: paymentMethod,
      createdAt: incoming.createdAt,
      updatedAt: incoming.updatedAt,
    );
  }

  /// Helper method to parse double values from various formats
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  /// Helper method to parse date field from API
  /// Handles both YYYY-MM-DD format and ISO 8601 timestamp format
  static String _parseDateField(dynamic value) {
    if (value == null) return DateFormatter.toApiDate(DateTime.now());
    
    final dateStr = value as String;
    
    // If it's already in YYYY-MM-DD format, return as is
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateStr)) {
      return dateStr;
    }
    
    // If it's an ISO 8601 timestamp, extract the date part
    if (dateStr.contains('T')) {
      try {
        final dateTime = DateTime.parse(dateStr);
        return DateFormatter.toApiDate(dateTime);
      } catch (e) {
        return DateFormatter.toApiDate(DateTime.now());
      }
    }
    
    // Fallback to current date
    return DateFormatter.toApiDate(DateTime.now());
  }

  IncomingDto copyWith({
    int? id,
    int? userId,
    double? amountUsd,
    String? source,
    String? description,
    String? date,
    String? paymentMethod,
    String? sourceType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IncomingDto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amountUsd: amountUsd ?? this.amountUsd,
      source: source ?? this.source,
      description: description ?? this.description,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      sourceType: sourceType ?? this.sourceType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Paginated response wrapper for incoming list
class IncomingListResponse {
  final List<IncomingDto> data;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const IncomingListResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory IncomingListResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    
    // Check if pagination info is in 'meta' object or at root level
    final meta = json['meta'] as Map<String, dynamic>?;
    final currentPage = (meta?['current_page'] ?? json['current_page']) as int? ?? 1;
    final lastPage = (meta?['last_page'] ?? json['last_page']) as int? ?? 1;
    final perPage = (meta?['per_page'] ?? json['per_page']) as int? ?? 15;
    final total = (meta?['total'] ?? json['total']) as int? ?? 0;
    
    return IncomingListResponse(
      data: dataList.map((item) => IncomingDto.fromJson(item as Map<String, dynamic>)).toList(),
      currentPage: currentPage,
      lastPage: lastPage,
      perPage: perPage,
      total: total,
    );
  }

  bool get hasMorePages => currentPage < lastPage;
}
