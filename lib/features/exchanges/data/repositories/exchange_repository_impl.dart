import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/exchange.dart';
import '../../domain/repositories/exchange_repository.dart';
import '../datasources/exchange_api_datasource.dart';

class ExchangeRepositoryImpl implements ExchangeRepository {
  final ExchangeApiDataSource apiDataSource;

  ExchangeRepositoryImpl({required this.apiDataSource});

  @override
  Future<Either<Failure, Exchange>> createExchange({
    int? transferId,
    required String targetCurrency,
    required double amountUsd,
    required double exchangeRate,
    required DateTime exchangeDate,
    String? notes,
  }) async {
    try {
      final exchangeDateStr = DateFormatter.toApiDate(exchangeDate);
      
      final dto = await apiDataSource.createExchange(
        transferId: transferId,
        targetCurrency: targetCurrency,
        amountUsd: amountUsd,
        exchangeRate: exchangeRate,
        exchangeDate: exchangeDateStr,
        notes: notes,
      );

      final exchange = Exchange(
        id: dto.id,
        transferId: dto.transferId,
        userId: dto.userId,
        adminGroupId: dto.adminGroupId,
        targetCurrency: dto.targetCurrency,
        amountUsd: dto.amountUsd,
        exchangeRate: dto.exchangeRate,
        amountSyp: dto.amountSyp,
        amountTry: dto.amountTry,
        exchangeDate: DateFormatter.fromApiDate(dto.exchangeDate),
        notes: dto.notes,
        createdAt: dto.createdAt,
        updatedAt: dto.updatedAt,
        recipientName: dto.transfer?.recipientName,
        userName: dto.user?.name,
      );

      return Right(exchange);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Exchange>>> getAllExchanges({String? currency}) async {
    try {
      final dtos = await apiDataSource.getAllExchanges(currency: currency);
      
      final exchanges = dtos.map((dto) => Exchange(
        id: dto.id,
        transferId: dto.transferId,
        userId: dto.userId,
        adminGroupId: dto.adminGroupId,
        targetCurrency: dto.targetCurrency,
        amountUsd: dto.amountUsd,
        exchangeRate: dto.exchangeRate,
        amountSyp: dto.amountSyp,
        amountTry: dto.amountTry,
        exchangeDate: DateFormatter.fromApiDate(dto.exchangeDate),
        notes: dto.notes,
        createdAt: dto.createdAt,
        updatedAt: dto.updatedAt,
        recipientName: dto.transfer?.recipientName,
        userName: dto.user?.name,
      )).toList();

      return Right(exchanges);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Exchange>> getExchangeById(int id) async {
    try {
      final dto = await apiDataSource.getExchangeById(id);
      
      final exchange = Exchange(
        id: dto.id,
        transferId: dto.transferId,
        userId: dto.userId,
        adminGroupId: dto.adminGroupId,
        targetCurrency: dto.targetCurrency,
        amountUsd: dto.amountUsd,
        exchangeRate: dto.exchangeRate,
        amountSyp: dto.amountSyp,
        amountTry: dto.amountTry,
        exchangeDate: DateFormatter.fromApiDate(dto.exchangeDate),
        notes: dto.notes,
        createdAt: dto.createdAt,
        updatedAt: dto.updatedAt,
        recipientName: dto.transfer?.recipientName,
        userName: dto.user?.name,
      );

      return Right(exchange);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Exchange>>> getExchangesByTransfer(int transferId) async {
    try {
      final dtos = await apiDataSource.getExchangesByTransfer(transferId);
      
      final exchanges = dtos.map((dto) => Exchange(
        id: dto.id,
        transferId: dto.transferId,
        userId: dto.userId,
        adminGroupId: dto.adminGroupId,
        targetCurrency: dto.targetCurrency,
        amountUsd: dto.amountUsd,
        exchangeRate: dto.exchangeRate,
        amountSyp: dto.amountSyp,
        amountTry: dto.amountTry,
        exchangeDate: DateFormatter.fromApiDate(dto.exchangeDate),
        notes: dto.notes,
        createdAt: dto.createdAt,
        updatedAt: dto.updatedAt,
        recipientName: dto.transfer?.recipientName,
        userName: dto.user?.name,
      )).toList();

      return Right(exchanges);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TransferBalance>> getTransferBalance(int transferId) async {
    try {
      final dto = await apiDataSource.getTransferBalance(transferId);
      
      final balance = TransferBalance(
        transferId: dto.transferId,
        originalAmount: dto.originalAmount,
        totalExchanged: dto.totalExchanged,
        remainingBalance: dto.remainingBalance,
        recipientName: dto.recipientName,
        transferDate: DateFormatter.fromApiDate(dto.transferDate),
      );

      return Right(balance);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
