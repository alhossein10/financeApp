import '../models/incoming_model.dart';
import 'incoming_local_datasource.dart';

/// Stub implementation for Laravel version
/// Local datasource not used - all operations go through API
class IncomingLocalDataSourceImpl implements IncomingLocalDataSource {
  IncomingLocalDataSourceImpl();

  @override
  Future<IncomingModel> createIncoming({
    required int userId,
    required String description,
    required double amountUsd,
    DateTime? transactionDate,
  }) async {
    throw UnimplementedError('Local datasource not used in Laravel version');
  }

  @override
  Future<List<IncomingModel>> getIncomingByUser(int userId) async {
    throw UnimplementedError('Local datasource not used in Laravel version');
  }

  @override
  Future<void> updateIncoming(IncomingModel incoming) async {
    throw UnimplementedError('Local datasource not used in Laravel version');
  }

  @override
  Future<void> deleteIncoming(int id, int userId, {bool refund = false}) async {
    throw UnimplementedError('Local datasource not used in Laravel version');
  }
}
