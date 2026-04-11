import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../models/exchange_dto.dart';

/// API Data Source for Exchange operations
/// Implements the Exchange API endpoints from EXCHANGE_FEATURE_FLUTTER_GUIDE.md
/// Supports balance-based exchanges (optional transferId) and multi-currency (SYP/TRY)
/// Backend v3.1+ supports converted_amount as alternative to exchange_rate
abstract class ExchangeApiDataSource {
  /// Create a new exchange (balance-based, optional transferId)
  /// 
  /// Either exchangeRate OR convertedAmount must be provided (not both required).
  /// If both are provided, backend will validate they match.
  /// If only convertedAmount is provided, backend will calculate exchangeRate automatically.
  /// If only exchangeRate is provided, backend will calculate convertedAmount automatically.
  Future<ExchangeDto> createExchange({
    int? transferId, // Optional - for balance-based exchanges
    required String targetCurrency, // 'SYP' or 'TRY'
    required double amountUsd,
    double? exchangeRate, // Optional if convertedAmount is provided
    double? convertedAmount, // Optional if exchangeRate is provided (Backend v3.1+)
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
    double? exchangeRate,
    double? convertedAmount,
    required String exchangeDate,
    String? notes,
  }) async {
    try {
      // Validate that at least one of exchangeRate or convertedAmount is provided
      if (exchangeRate == null && convertedAmount == null) {
        throw ApiException(
          message: 'Either exchange_rate or converted_amount must be provided',
          statusCode: 422,
        );
      }

      final body = <String, dynamic>{
        if (transferId != null) 'transfer_id': transferId, // Optional
        'target_currency': targetCurrency,
        'amount_usd': amountUsd,
        'exchange_date': exchangeDate,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      // Add exchange_rate if provided
      if (exchangeRate != null) {
        body['exchange_rate'] = exchangeRate;
      }

      // Add converted_amount if provided (Backend v3.1+)
      if (convertedAmount != null) {
        body['converted_amount'] = convertedAmount;
      }

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
