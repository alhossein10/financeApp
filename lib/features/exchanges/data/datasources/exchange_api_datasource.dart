import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../models/exchange_dto.dart';

/// API Data Source for Exchange operations
/// Implements the Exchange API endpoints from EXCHANGE_FEATURE_FLUTTER_GUIDE.md
/// Supports balance-based exchanges (optional transferId) and multi-currency (SYP/TRY)
abstract class ExchangeApiDataSource {
  /// Create a new exchange (balance-based, optional transferId)
  Future<ExchangeDto> createExchange({
    int? transferId, // Optional - for balance-based exchanges
    required String targetCurrency, // 'SYP' or 'TRY'
    required double amountUsd,
    required double exchangeRate,
    required String exchangeDate,
    String? notes,
  });

  /// Get all exchanges for the authenticated user
  /// [currency] optional filter: 'all', 'SYP', or 'TRY'
  Future<List<ExchangeDto>> getAllExchanges({String? currency});

  /// Get exchange by ID
  Future<ExchangeDto> getExchangeById(int id);

  /// Get all exchanges for a specific transfer
  Future<List<ExchangeDto>> getExchangesByTransfer(int transferId);

  /// Get transfer balance
  Future<TransferBalanceDto> getTransferBalance(int transferId);
}

class ExchangeApiDataSourceImpl implements ExchangeApiDataSource {
  final ApiClient apiClient;

  ExchangeApiDataSourceImpl({required this.apiClient});

  @override
  Future<ExchangeDto> createExchange({
    int? transferId,
    required String targetCurrency,
    required double amountUsd,
    required double exchangeRate,
    required String exchangeDate,
    String? notes,
  }) async {
    try {
      final body = {
        if (transferId != null) 'transfer_id': transferId, // Optional
        'target_currency': targetCurrency,
        'amount_usd': amountUsd,
        'exchange_rate': exchangeRate,
        'exchange_date': exchangeDate,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await apiClient.post('/exchanges', body: body);

      if (response.statusCode == 201) {
        final data = response.data['data'] as Map<String, dynamic>;
        return ExchangeDto.fromJson(data);
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to create exchange',
          statusCode: response.statusCode,
          errors: response.data['errors'],
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to create exchange: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<ExchangeDto>> getAllExchanges({String? currency}) async {
    try {
      String url = '/exchanges';
      if (currency != null && currency.isNotEmpty && currency != 'all') {
        url += '?currency=$currency';
      }
      
      final response = await apiClient.get(url);

      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>;
        return data
            .map((json) => ExchangeDto.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to load exchanges',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to load exchanges: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ExchangeDto> getExchangeById(int id) async {
    try {
      final response = await apiClient.get('/exchanges/$id');

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return ExchangeDto.fromJson(data);
      } else if (response.statusCode == 404) {
        throw ApiException(
          message: 'Exchange not found',
          statusCode: 404,
        );
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to load exchange',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to load exchange: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<ExchangeDto>> getExchangesByTransfer(int transferId) async {
    try {
      final response = await apiClient.get('/exchanges/transfer/$transferId');

      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>;
        return data
            .map((json) => ExchangeDto.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to load transfer exchanges',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to load transfer exchanges: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  @override
  Future<TransferBalanceDto> getTransferBalance(int transferId) async {
    try {
      final response = await apiClient.get('/exchanges/transfer/$transferId/balance');

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return TransferBalanceDto.fromJson(data);
      } else {
        throw ApiException(
          message: response.data['message'] ?? 'Failed to load transfer balance',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to load transfer balance: ${e.toString()}',
        statusCode: 500,
      );
    }
  }
}
