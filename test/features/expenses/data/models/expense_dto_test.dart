import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/utils/date_formatter.dart';
import 'package:finance_app/features/expenses/data/models/expense_dto.dart';
import 'package:finance_app/features/expenses/domain/entities/expense.dart';

void main() {
  group('ExpenseDto', () {
    group('fromJson', () {
      test('should correctly parse JSON response from API', () {
        // Arrange
        final json = {
          'id': 1,
          'user_id': 123,
          'description': 'Lunch',
          'price_usd': '150.00',
          'price_syp': null,
          'price_try': null,
          'has_invoice': false,
          'invoice_path': null,
          'expense_date': '2024-10-23T00:00:00.000000Z',
          'sync_status': 'synced',
          'synced_at': '2024-10-23T10:00:00.000000Z',
          'created_at': '2024-10-23T10:00:00.000000Z',
          'updated_at': '2024-10-23T11:00:00.000000Z',
          'user': {
            'id': 123,
            'name': 'Test User',
            'email': 'test@example.com',
          },
        };

        // Act
        final dto = ExpenseDto.fromJson(json);

        // Assert
        expect(dto.id, 1);
        expect(dto.userId, 123);
        expect(dto.priceUsd, 150.0);
        expect(dto.description, 'Lunch');
        expect(dto.expenseDate, '2024-10-23T00:00:00.000000Z');
        expect(dto.hasInvoice, false);
        expect(dto.syncStatus, 'synced');
        expect(dto.createdAt, isNotNull);
        expect(dto.updatedAt, isNotNull);
        expect(dto.user, isNotNull);
      });

      test('should handle missing optional fields', () {
        // Arrange
        final json = {
          'expense_date': '2024-10-23',
        };

        // Act
        final dto = ExpenseDto.fromJson(json);

        // Assert
        expect(dto.id, isNull);
        expect(dto.userId, isNull);
        expect(dto.description, isNull);
        expect(dto.priceUsd, isNull);
        expect(dto.priceSyp, isNull);
        expect(dto.priceTry, isNull);
        expect(dto.createdAt, isNull);
        expect(dto.updatedAt, isNull);
      });

      test('should handle has_invoice flag', () {
        // Arrange
        final json = {
          'expense_date': '2024-10-23',
          'has_invoice': true,
          'invoice_path': '/path/to/invoice.pdf',
        };

        // Act
        final dto = ExpenseDto.fromJson(json);

        // Assert
        expect(dto.hasInvoice, true);
        expect(dto.invoicePath, '/path/to/invoice.pdf');
      });
    });

    group('toJson', () {
      test('should correctly convert DTO to JSON for API request', () {
        // Arrange
        final dto = ExpenseDto(
          userId: 123,
          amount: 150.0,
          category: 'Food',
          description: 'Lunch',
          expenseDate: '2024-10-23',
          paymentMethod: 'card',
        );

        // Act
        final json = dto.toJson();

        // Assert
        expect(json['amount'], 150.0);
        expect(json['category'], 'Food');
        expect(json['description'], 'Lunch');
        expect(json['expense_date'], '2024-10-23');
        expect(json['payment_method'], 'card');
        // user_id should not be in request body
        expect(json.containsKey('user_id'), false);
        expect(json.containsKey('id'), false);
      });

      test('should exclude null description from JSON', () {
        // Arrange
        final dto = ExpenseDto(
          amount: 150.0,
          category: 'Food',
          expenseDate: '2024-10-23',
          paymentMethod: 'cash',
        );

        // Act
        final json = dto.toJson();

        // Assert
        expect(json.containsKey('description'), false);
      });

      test('should include price fields when provided', () {
        // Arrange
        final dto = ExpenseDto(
          priceUsd: 150.0,
          priceSyp: 50000.0,
          expenseDate: '2024-10-23',
        );

        // Act
        final json = dto.toJson();

        // Assert
        expect(json['price_usd'], '150.0');
        expect(json['price_syp'], '50000.0');
        expect(json['expense_date'], '2024-10-23');
      });
    });

    group('validate', () {
      test('should not throw for valid payment methods', () {
        // Arrange
        final validMethods = ['cash', 'card', 'bank_transfer'];

        for (final method in validMethods) {
          final dto = ExpenseDto(
            amount: 150.0,
            category: 'Food',
            expenseDate: '2024-10-23',
            paymentMethod: method,
          );

          // Act & Assert
          expect(() => dto.validate(), returnsNormally);
        }
      });

      test('should throw for invalid payment method', () {
        // Arrange
        final dto = ExpenseDto(
          amount: 150.0,
          category: 'Food',
          expenseDate: '2024-10-23',
          paymentMethod: 'invalid_method',
        );

        // Act & Assert
        expect(() => dto.validate(), throwsArgumentError);
      });

      test('should not throw when payment method is null', () {
        // Arrange
        final dto = ExpenseDto(
          priceUsd: 150.0,
          expenseDate: '2024-10-23',
        );

        // Act & Assert
        expect(() => dto.validate(), returnsNormally);
      });
    });

    group('toEntity', () {
      test('should correctly convert DTO to domain entity', () {
        // Arrange
        final dto = ExpenseDto(
          id: 1,
          userId: 123,
          priceUsd: 150.0,
          description: 'Lunch',
          expenseDate: '2024-10-23',
          hasInvoice: false,
          syncStatus: 'synced',
          createdAt: DateTime(2024, 10, 23, 10, 0),
        );

        // Act
        final entity = dto.toEntity();

        // Assert
        expect(entity.id, 1);
        expect(entity.userId, 123);
        expect(entity.priceUsd, 150.0);
        expect(entity.description, 'Lunch');
        expect(entity.expenseDate.year, 2024);
        expect(entity.expenseDate.month, 10);
        expect(entity.expenseDate.day, 23);
        expect(entity.invoiceStatus, InvoiceStatus.noInvoice);
        expect(entity.syncStatus, SyncStatus.synced);
      });

      test('should handle null description', () {
        // Arrange
        final dto = ExpenseDto(
          id: 1,
          userId: 123,
          priceUsd: 150.0,
          expenseDate: '2024-10-23',
        );

        // Act
        final entity = dto.toEntity();

        // Assert
        expect(entity.description, '');
      });

      test('should map invoice status correctly', () {
        // Arrange
        final dtoWithInvoice = ExpenseDto(
          id: 1,
          userId: 123,
          priceUsd: 150.0,
          expenseDate: '2024-10-23',
          hasInvoice: true,
          invoicePath: '/path/to/invoice.pdf',
        );

        // Act
        final entity = dtoWithInvoice.toEntity();

        // Assert
        expect(entity.invoiceStatus, InvoiceStatus.invoiceAvailable);
        expect(entity.invoiceFilePath, '/path/to/invoice.pdf');
      });

      test('should extract user information', () {
        // Arrange
        final dto = ExpenseDto(
          id: 1,
          userId: 123,
          priceUsd: 150.0,
          expenseDate: '2024-10-23',
          user: {
            'id': 123,
            'name': 'Test User',
            'email': 'test@example.com',
          },
        );

        // Act
        final entity = dto.toEntity();

        // Assert
        expect(entity.creatorUsername, 'Test User');
        expect(entity.creatorEmail, 'test@example.com');
      });
    });

    group('fromEntity', () {
      test('should correctly convert domain entity to DTO with USD price', () {
        // Arrange
        final entity = Expense(
          id: 1,
          userId: 123,
          description: 'Lunch',
          priceUsd: 150.0,
          invoiceStatus: InvoiceStatus.noInvoice,
          expenseDate: DateTime(2024, 10, 23),
          createdAt: DateTime(2024, 10, 23, 10, 0),
        );

        // Act
        final dto = ExpenseDto.fromEntity(entity);

        // Assert
        expect(dto.id, 1);
        expect(dto.userId, 123);
        expect(dto.amount, 150.0);
        expect(dto.category, 'USD');
        expect(dto.description, 'Lunch');
        expect(dto.expenseDate, '2024-10-23');
        expect(dto.paymentMethod, 'card');
        expect(dto.priceUsd, 150.0);
      });

      test('should convert entity with SYP price', () {
        // Arrange
        final entity = Expense(
          id: 1,
          userId: 123,
          description: 'Local purchase',
          priceSyp: 50000.0,
          invoiceStatus: InvoiceStatus.noInvoice,
          expenseDate: DateTime(2024, 10, 23),
          createdAt: DateTime(2024, 10, 23, 10, 0),
        );

        // Act
        final dto = ExpenseDto.fromEntity(entity);

        // Assert
        expect(dto.amount, 50000.0);
        expect(dto.category, 'SYP');
        expect(dto.paymentMethod, 'cash');
        expect(dto.priceSyp, 50000.0);
      });

      test('should convert entity with TRY price', () {
        // Arrange
        final entity = Expense(
          id: 1,
          userId: 123,
          description: 'Turkish purchase',
          priceTry: 500.0,
          invoiceStatus: InvoiceStatus.noInvoice,
          expenseDate: DateTime(2024, 10, 23),
          createdAt: DateTime(2024, 10, 23, 10, 0),
        );

        // Act
        final dto = ExpenseDto.fromEntity(entity);

        // Assert
        expect(dto.amount, 500.0);
        expect(dto.category, 'TRY');
        expect(dto.paymentMethod, 'cash');
        expect(dto.priceTry, 500.0);
      });
    });

    group('Date formatting', () {
      test('should use YYYY-MM-DD format for expenseDate field', () {
        // Arrange
        final dto = ExpenseDto(
          amount: 150.0,
          category: 'Food',
          expenseDate: DateFormatter.toApiDate(DateTime(2024, 1, 5)),
          paymentMethod: 'cash',
        );

        // Assert
        expect(dto.expenseDate, '2024-01-05');
      });
    });

    group('ExpenseListResponse', () {
      test('should correctly parse paginated response with meta object', () {
        // Arrange
        final json = {
          'data': [
            {
              'id': 1,
              'price_usd': '150.00',
              'description': 'Food',
              'expense_date': '2024-10-23',
            },
            {
              'id': 2,
              'price_syp': '50000.00',
              'description': 'Transport',
              'expense_date': '2024-10-24',
            },
              'payment_method': 'cash',
            },
          ],
          'current_page': 1,
          'last_page': 3,
          'per_page': 15,
          'total': 45,
        };

        // Act
        final response = ExpenseListResponse.fromJson(json);

        // Assert
        expect(response.data.length, 2);
        expect(response.currentPage, 1);
        expect(response.lastPage, 3);
        expect(response.perPage, 15);
        expect(response.total, 45);
        expect(response.hasMorePages, true);
      });

      test('should indicate no more pages when on last page', () {
        // Arrange
        final json = {
          'data': [],
          'current_page': 3,
          'last_page': 3,
          'per_page': 15,
          'total': 45,
        };

        // Act
        final response = ExpenseListResponse.fromJson(json);

        // Assert
        expect(response.hasMorePages, false);
      });
    });
  });
}
