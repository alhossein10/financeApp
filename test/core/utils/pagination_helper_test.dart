import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/utils/pagination_helper.dart';

void main() {
  group('PaginationHelper', () {
    group('getPaginationParams', () {
      test('returns correct params with default values', () {
        final params = PaginationHelper.getPaginationParams();
        
        expect(params['page'], 1);
        expect(params['per_page'], PaginationHelper.defaultPageSize);
      });

      test('returns correct params with custom values', () {
        final params = PaginationHelper.getPaginationParams(
          page: 3,
          perPage: 20,
        );
        
        expect(params['page'], 3);
        expect(params['per_page'], 20);
      });

      test('ensures page is at least 1', () {
        final params = PaginationHelper.getPaginationParams(page: 0);
        expect(params['page'], 1);
        
        final params2 = PaginationHelper.getPaginationParams(page: -5);
        expect(params2['page'], 1);
      });

      test('ensures perPage is within limits', () {
        final params1 = PaginationHelper.getPaginationParams(perPage: 0);
        expect(params1['per_page'], PaginationHelper.defaultPageSize);
        
        final params2 = PaginationHelper.getPaginationParams(perPage: -10);
        expect(params2['per_page'], PaginationHelper.defaultPageSize);
        
        final params3 = PaginationHelper.getPaginationParams(perPage: 200);
        expect(params3['per_page'], PaginationHelper.maxPageSize);
      });
    });

    group('hasMorePages', () {
      test('returns true when current page is less than total pages', () {
        expect(
          PaginationHelper.hasMorePages(currentPage: 2, totalPages: 5),
          true,
        );
      });

      test('returns false when current page equals total pages', () {
        expect(
          PaginationHelper.hasMorePages(currentPage: 5, totalPages: 5),
          false,
        );
      });

      test('returns false when current page exceeds total pages', () {
        expect(
          PaginationHelper.hasMorePages(currentPage: 6, totalPages: 5),
          false,
        );
      });
    });

    group('calculateTotalPages', () {
      test('calculates correct total pages', () {
        expect(
          PaginationHelper.calculateTotalPages(totalItems: 47, perPage: 15),
          4,
        );
        
        expect(
          PaginationHelper.calculateTotalPages(totalItems: 45, perPage: 15),
          3,
        );
        
        expect(
          PaginationHelper.calculateTotalPages(totalItems: 15, perPage: 15),
          1,
        );
      });

      test('returns 0 for zero items', () {
        expect(
          PaginationHelper.calculateTotalPages(totalItems: 0, perPage: 15),
          0,
        );
      });

      test('returns 0 for zero perPage', () {
        expect(
          PaginationHelper.calculateTotalPages(totalItems: 100, perPage: 0),
          0,
        );
      });
    });

    group('getNextPage', () {
      test('returns next page number when more pages available', () {
        expect(
          PaginationHelper.getNextPage(currentPage: 2, totalPages: 5),
          3,
        );
      });

      test('returns null when on last page', () {
        expect(
          PaginationHelper.getNextPage(currentPage: 5, totalPages: 5),
          null,
        );
      });

      test('returns null when beyond last page', () {
        expect(
          PaginationHelper.getNextPage(currentPage: 6, totalPages: 5),
          null,
        );
      });
    });

    group('getPreviousPage', () {
      test('returns previous page number when not on first page', () {
        expect(PaginationHelper.getPreviousPage(currentPage: 3), 2);
      });

      test('returns null when on first page', () {
        expect(PaginationHelper.getPreviousPage(currentPage: 1), null);
      });

      test('returns null when page is less than 1', () {
        expect(PaginationHelper.getPreviousPage(currentPage: 0), null);
      });
    });
  });

  group('PaginationMeta', () {
    test('creates from JSON correctly', () {
      final json = {
        'current_page': 2,
        'per_page': 15,
        'total': 47,
        'last_page': 4,
        'next_page': 3,
        'prev_page': 1,
      };

      final meta = PaginationMeta.fromJson(json);

      expect(meta.currentPage, 2);
      expect(meta.perPage, 15);
      expect(meta.totalItems, 47);
      expect(meta.totalPages, 4);
      expect(meta.nextPage, 3);
      expect(meta.previousPage, 1);
    });

    test('uses defaults for missing fields', () {
      final json = <String, dynamic>{};
      final meta = PaginationMeta.fromJson(json);

      expect(meta.currentPage, 1);
      expect(meta.perPage, PaginationHelper.defaultPageSize);
      expect(meta.totalItems, 0);
      expect(meta.totalPages, 0);
    });

    test('hasNextPage returns correct value', () {
      final meta1 = PaginationMeta(
        currentPage: 2,
        perPage: 15,
        totalItems: 47,
        totalPages: 4,
        nextPage: 3,
      );
      expect(meta1.hasNextPage, true);

      final meta2 = PaginationMeta(
        currentPage: 4,
        perPage: 15,
        totalItems: 47,
        totalPages: 4,
      );
      expect(meta2.hasNextPage, false);
    });

    test('hasPreviousPage returns correct value', () {
      final meta1 = PaginationMeta(
        currentPage: 2,
        perPage: 15,
        totalItems: 47,
        totalPages: 4,
        previousPage: 1,
      );
      expect(meta1.hasPreviousPage, true);

      final meta2 = PaginationMeta(
        currentPage: 1,
        perPage: 15,
        totalItems: 47,
        totalPages: 4,
      );
      expect(meta2.hasPreviousPage, false);
    });

    test('isFirstPage returns correct value', () {
      final meta1 = PaginationMeta(
        currentPage: 1,
        perPage: 15,
        totalItems: 47,
        totalPages: 4,
      );
      expect(meta1.isFirstPage, true);

      final meta2 = PaginationMeta(
        currentPage: 2,
        perPage: 15,
        totalItems: 47,
        totalPages: 4,
      );
      expect(meta2.isFirstPage, false);
    });

    test('isLastPage returns correct value', () {
      final meta1 = PaginationMeta(
        currentPage: 4,
        perPage: 15,
        totalItems: 47,
        totalPages: 4,
      );
      expect(meta1.isLastPage, true);

      final meta2 = PaginationMeta(
        currentPage: 2,
        perPage: 15,
        totalItems: 47,
        totalPages: 4,
      );
      expect(meta2.isLastPage, false);
    });
  });

  group('PaginatedResponse', () {
    test('creates from JSON correctly', () {
      final json = {
        'data': [
          {'id': 1, 'name': 'Item 1'},
          {'id': 2, 'name': 'Item 2'},
        ],
        'current_page': 1,
        'per_page': 15,
        'total': 2,
        'last_page': 1,
      };

      final response = PaginatedResponse<Map<String, dynamic>>.fromJson(
        json,
        (item) => item,
      );

      expect(response.data.length, 2);
      expect(response.data[0]['id'], 1);
      expect(response.meta.currentPage, 1);
      expect(response.meta.totalItems, 2);
    });

    test('handles empty data array', () {
      final json = {
        'data': <dynamic>[],
        'current_page': 1,
        'per_page': 15,
        'total': 0,
        'last_page': 0,
      };

      final response = PaginatedResponse<Map<String, dynamic>>.fromJson(
        json,
        (item) => item,
      );

      expect(response.data.isEmpty, true);
      expect(response.meta.totalItems, 0);
    });

    test('merge combines data correctly', () {
      final page1 = PaginatedResponse<int>(
        data: [1, 2, 3],
        meta: PaginationMeta(
          currentPage: 1,
          perPage: 3,
          totalItems: 6,
          totalPages: 2,
          nextPage: 2,
        ),
      );

      final page2 = PaginatedResponse<int>(
        data: [4, 5, 6],
        meta: PaginationMeta(
          currentPage: 2,
          perPage: 3,
          totalItems: 6,
          totalPages: 2,
        ),
      );

      final merged = page1.merge(page2);

      expect(merged.data, [1, 2, 3, 4, 5, 6]);
      expect(merged.meta.currentPage, 2);
      expect(merged.meta.totalPages, 2);
    });

    test('empty factory creates empty response', () {
      final empty = PaginatedResponse<String>.empty();

      expect(empty.data.isEmpty, true);
      expect(empty.meta.currentPage, 1);
      expect(empty.meta.totalItems, 0);
      expect(empty.meta.totalPages, 0);
    });

    test('hasMore returns correct value', () {
      final response1 = PaginatedResponse<int>(
        data: [1, 2, 3],
        meta: PaginationMeta(
          currentPage: 1,
          perPage: 3,
          totalItems: 6,
          totalPages: 2,
          nextPage: 2,
        ),
      );
      expect(response1.hasMore, true);

      final response2 = PaginatedResponse<int>(
        data: [4, 5, 6],
        meta: PaginationMeta(
          currentPage: 2,
          perPage: 3,
          totalItems: 6,
          totalPages: 2,
        ),
      );
      expect(response2.hasMore, false);
    });

    test('nextPage returns correct value', () {
      final response = PaginatedResponse<int>(
        data: [1, 2, 3],
        meta: PaginationMeta(
          currentPage: 1,
          perPage: 3,
          totalItems: 6,
          totalPages: 2,
          nextPage: 2,
        ),
      );
      expect(response.nextPage, 2);
    });
  });
}
