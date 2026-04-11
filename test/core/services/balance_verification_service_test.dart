import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:finance_app/core/services/balance_verification_service.dart';
import 'package:finance_app/core/exceptions/insufficient_balance_exception.dart';
import 'package:finance_app/features/fund_box/data/datasources/fund_box_api_datasource.dart';
import 'package:finance_app/features/fund_box/data/models/fund_box_dto.dart';
import 'package:finance_app/core/api/api_exception.dart';

@GenerateMocks([FundBoxApiDataSource])
import 'balance_verification_service_test.mocks.dart';

void main() {
  late BalanceVerificationService balanceVerificationService;
  late MockFundBoxApiDataSource mockFundBoxApiDataSource;

  setUp(() {
    mockFundBoxApiDataSource = MockFundBoxApiDataSource();
    balanceVerificationService = BalanceVerificationService(
      fundBoxApiDataSource: mockFundBoxApiDataSource,
    );
  });

  group('BalanceVerificationService', () {
    group('verifyBalance', () {
      test('should return true when sufficient balance exists', () async {
        // Arrange
        final fundBoxDto = FundBoxDto(
          id: 1,
          balanceUsd: 1000.0,
          balanceSyp: 50000.0,
          balanceTry: 30000.0,
          lastUpdated: DateTime.now(),
        );

        when(mockFundBoxApiDataSource.getFundBox())
            .thenAnswer((_) async => fundBoxDto);

        // Act
        final result = await balanceVerificationService.verifyBalance(
          currency: 'USD',
          amount: 500.0,
        );

        // Assert
        expect(result, true);
        verify(mockFundBoxApiDataSource.getFundBox()).called(1);
      });

      test('should throw InsufficientBalanceException when balance is insufficient', () async {
        // Arrange
        final fundBoxDto = FundBoxDto(
          id: 1,
          balanceUsd: 100.0,
          balanceSyp: 50000.0,
          balanceTry: 30000.0,
          lastUpdated: DateTime.now(),
        );

        when(mockFundBoxApiDataSource.getFundBox())
            .thenAnswer((_) async => fundBoxDto);

        // Act & Assert
        expect(
          () => balanceVerificationService.verifyBalance(
            currency: 'USD',
            amount: 500.0,
            context: 'expense creation',
          ),
          throwsA(isA<InsufficientBalanceException>()
              .having((e) => e.currency, 'currency', 'USD')
              .having((e) => e.required, 'required', 500.0)
              .having((e) => e.available, 'available', 100.0)
              .having((e) => e.context, 'context', 'expense creation')),
        );
      });

      test('should verify SYP balance correctly', () async {
        // Arrange
        final fundBoxDto = FundBoxDto(
          id: 1,
          balanceUsd: 1000.0,
          balanceSyp: 50000.0,
          balanceTry: 30000.0,
          lastUpdated: DateTime.now(),
        );

        when(mockFundBoxApiDataSource.getFundBox())
            .thenAnswer((_) async => fundBoxDto);

        // Act
        final result = await balanceVerificationService.verifyBalance(
          currency: 'SYP',
          amount: 40000.0,
        );

        // Assert
        expect(result, true);
      });

      test('should verify TRY balance correctly', () async {
        // Arrange
        final fundBoxDto = FundBoxDto(
          id: 1,
          balanceUsd: 1000.0,
          balanceSyp: 50000.0,
          balanceTry: 30000.0,
          lastUpdated: DateTime.now(),
        );

        when(mockFundBoxApiDataSource.getFundBox())
            .thenAnswer((_) async => fundBoxDto);

        // Act
        final result = await balanceVerificationService.verifyBalance(
          currency: 'TRY',
          amount: 25000.0,
        );

        // Assert
        expect(result, true);
      });

      test('should handle lowercase currency codes', () async {
        // Arrange
        final fundBoxDto = FundBoxDto(
          id: 1,
          balanceUsd: 1000.0,
          balanceSyp: 50000.0,
          balanceTry: 30000.0,
          lastUpdated: DateTime.now(),
        );

        when(mockFundBoxApiDataSource.getFundBox())
            .thenAnswer((_) async => fundBoxDto);

        // Act
        final result = await balanceVerificationService.verifyBalance(
          currency: 'usd',
          amount: 500.0,
        );

        // Assert
        expect(result, true);
      });

      test('should throw ArgumentError for invalid currency', () async {
        // Act & Assert
        expect(
          () => balanceVerificationService.verifyBalance(
            currency: 'EUR',
            amount: 100.0,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw ArgumentError for negative amount', () async {
        // Act & Assert
        expect(
          () => balanceVerificationService.verifyBalance(
            currency: 'USD',
            amount: -100.0,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should use getFundBoxByUserId when userId is provided', () async {
        // Arrange
        final fundBoxDto = FundBoxDto(
          id: 1,
          balanceUsd: 1000.0,
          balanceSyp: 50000.0,
          balanceTry: 30000.0,
          lastUpdated: DateTime.now(),
        );

        when(mockFundBoxApiDataSource.getFundBoxByUserId(123))
            .thenAnswer((_) async => fundBoxDto);

        // Act
        final result = await balanceVerificationService.verifyBalance(
          currency: 'USD',
          amount: 500.0,
          userId: 123,
        );

        // Assert
        expect(result, true);
        verify(mockFundBoxApiDataSource.getFundBoxByUserId(123)).called(1);
        verifyNever(mockFundBoxApiDataSource.getFundBox());
      });

      test('should rethrow ApiException from data source', () async {
        // Arrange
        when(mockFundBoxApiDataSource.getFundBox())
            .thenThrow(ApiException(statusCode: 500, message: 'Server error'));

        // Act & Assert
        expect(
          () => balanceVerificationService.verifyBalance(
            currency: 'USD',
            amount: 100.0,
          ),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('getCurrentBalances', () {
      test('should return all currency balances', () async {
        // Arrange
        final fundBoxDto = FundBoxDto(
          id: 1,
          balanceUsd: 1000.0,
          balanceSyp: 50000.0,
          balanceTry: 30000.0,
          lastUpdated: DateTime.now(),
        );

        when(mockFundBoxApiDataSource.getFundBox())
            .thenAnswer((_) async => fundBoxDto);

        // Act
        final result = await balanceVerificationService.getCurrentBalances();

        // Assert
        expect(result, {
          'USD': 1000.0,
          'SYP': 50000.0,
          'TRY': 30000.0,
        });
      });

      test('should handle null balances as zero', () async {
        // Arrange
        final fundBoxDto = FundBoxDto(
          id: 1,
          balanceUsd: null,
          balanceSyp: null,
          balanceTry: null,
          lastUpdated: DateTime.now(),
        );

        when(mockFundBoxApiDataSource.getFundBox())
            .thenAnswer((_) async => fundBoxDto);

        // Act
        final result = await balanceVerificationService.getCurrentBalances();

        // Assert
        expect(result, {
          'USD': 0.0,
          'SYP': 0.0,
          'TRY': 0.0,
        });
      });

      test('should use getFundBoxByUserId when userId is provided', () async {
        // Arrange
        final fundBoxDto = FundBoxDto(
          id: 1,
          balanceUsd: 1000.0,
          balanceSyp: 50000.0,
          balanceTry: 30000.0,
          lastUpdated: DateTime.now(),
        );

        when(mockFundBoxApiDataSource.getFundBoxByUserId(456))
            .thenAnswer((_) async => fundBoxDto);

        // Act
        final result = await balanceVerificationService.getCurrentBalances(userId: 456);

        // Assert
        expect(result, {
          'USD': 1000.0,
          'SYP': 50000.0,
          'TRY': 30000.0,
        });
        verify(mockFundBoxApiDataSource.getFundBoxByUserId(456)).called(1);
      });
    });

    group('verifyCalculatedBalance', () {
      test('should return true when sufficient calculated balance exists', () async {
        // Arrange
        final fundBoxDto = FundBoxDto(
          id: 1,
          balanceUsd: 1000.0,
          balanceSyp: 50000.0,
          balanceTry: 30000.0,
          lastUpdated: DateTime.now(),
        );

        when(mockFundBoxApiDataSource.getCalculatedBalance())
            .thenAnswer((_) async => fundBoxDto);

        // Act
        final result = await balanceVerificationService.verifyCalculatedBalance(
          currency: 'USD',
          amount: 500.0,
        );

        // Assert
        expect(result, true);
        verify(mockFundBoxApiDataSource.getCalculatedBalance()).called(1);
      });

      test('should throw InsufficientBalanceException when calculated balance is insufficient', () async {
        // Arrange
        final fundBoxDto = FundBoxDto(
          id: 1,
          balanceUsd: 100.0,
          balanceSyp: 50000.0,
          balanceTry: 30000.0,
          lastUpdated: DateTime.now(),
        );

        when(mockFundBoxApiDataSource.getCalculatedBalance())
            .thenAnswer((_) async => fundBoxDto);

        // Act & Assert
        expect(
          () => balanceVerificationService.verifyCalculatedBalance(
            currency: 'USD',
            amount: 500.0,
          ),
          throwsA(isA<InsufficientBalanceException>()),
        );
      });
    });

    group('getCalculatedBalances', () {
      test('should return all calculated currency balances', () async {
        // Arrange
        final fundBoxDto = FundBoxDto(
          id: 1,
          balanceUsd: 1000.0,
          balanceSyp: 50000.0,
          balanceTry: 30000.0,
          lastUpdated: DateTime.now(),
        );

        when(mockFundBoxApiDataSource.getCalculatedBalance())
            .thenAnswer((_) async => fundBoxDto);

        // Act
        final result = await balanceVerificationService.getCalculatedBalances();

        // Assert
        expect(result, {
          'USD': 1000.0,
          'SYP': 50000.0,
          'TRY': 30000.0,
        });
      });
    });

    group('verifyMultipleBalances', () {
      test('should return true when all balances are sufficient', () async {
        // Arrange
        final fundBoxDto = FundBoxDto(
          id: 1,
          balanceUsd: 1000.0,
          balanceSyp: 50000.0,
          balanceTry: 30000.0,
          lastUpdated: DateTime.now(),
        );

        when(mockFundBoxApiDataSource.getFundBox())
            .thenAnswer((_) async => fundBoxDto);

        // Act
        final result = await balanceVerificationService.verifyMultipleBalances(
          amounts: {
            'USD': 500.0,
            'SYP': 40000.0,
          },
        );

        // Assert
        expect(result, true);
        verify(mockFundBoxApiDataSource.getFundBox()).called(1);
      });

      test('should throw InsufficientBalanceException for first insufficient balance', () async {
        // Arrange
        final fundBoxDto = FundBoxDto(
          id: 1,
          balanceUsd: 100.0,
          balanceSyp: 50000.0,
          balanceTry: 30000.0,
          lastUpdated: DateTime.now(),
        );

        when(mockFundBoxApiDataSource.getFundBox())
            .thenAnswer((_) async => fundBoxDto);

        // Act & Assert
        expect(
          () => balanceVerificationService.verifyMultipleBalances(
            amounts: {
              'USD': 500.0,
              'SYP': 40000.0,
            },
          ),
          throwsA(isA<InsufficientBalanceException>()
              .having((e) => e.currency, 'currency', 'USD')),
        );
      });

      test('should handle lowercase currency codes in multiple balances', () async {
        // Arrange
        final fundBoxDto = FundBoxDto(
          id: 1,
          balanceUsd: 1000.0,
          balanceSyp: 50000.0,
          balanceTry: 30000.0,
          lastUpdated: DateTime.now(),
        );

        when(mockFundBoxApiDataSource.getFundBox())
            .thenAnswer((_) async => fundBoxDto);

        // Act
        final result = await balanceVerificationService.verifyMultipleBalances(
          amounts: {
            'usd': 500.0,
            'syp': 40000.0,
          },
        );

        // Assert
        expect(result, true);
      });

      test('should use getFundBoxByUserId when userId is provided', () async {
        // Arrange
        final fundBoxDto = FundBoxDto(
          id: 1,
          balanceUsd: 1000.0,
          balanceSyp: 50000.0,
          balanceTry: 30000.0,
          lastUpdated: DateTime.now(),
        );

        when(mockFundBoxApiDataSource.getFundBoxByUserId(789))
            .thenAnswer((_) async => fundBoxDto);

        // Act
        final result = await balanceVerificationService.verifyMultipleBalances(
          amounts: {
            'USD': 500.0,
            'SYP': 40000.0,
          },
          userId: 789,
        );

        // Assert
        expect(result, true);
        verify(mockFundBoxApiDataSource.getFundBoxByUserId(789)).called(1);
      });
    });
  });

  group('InsufficientBalanceException', () {
    test('should format message correctly', () {
      // Arrange
      final exception = InsufficientBalanceException(
        currency: 'USD',
        required: 500.0,
        available: 100.0,
      );

      // Assert
      expect(
        exception.message,
        'Insufficient USD balance. Required: 500.00, Available: 100.00',
      );
    });

    test('should include context in message when provided', () {
      // Arrange
      final exception = InsufficientBalanceException(
        currency: 'USD',
        required: 500.0,
        available: 100.0,
        context: 'expense creation',
      );

      // Assert
      expect(
        exception.message,
        'Insufficient USD balance (expense creation). Required: 500.00, Available: 100.00',
      );
    });
  });
}
