import 'package:bagtrip/core/paginated_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaginatedResponse', () {
    test('hasMore is true when page < totalPages', () {
      const response = PaginatedResponse<String>(
        items: ['a', 'b'],
        total: 40,
        page: 1,
        totalPages: 2,
      );
      expect(response.hasMore, isTrue);
    });

    test('hasMore is false when page == totalPages', () {
      const response = PaginatedResponse<String>(
        items: ['a'],
        total: 1,
        page: 1,
        totalPages: 1,
      );
      expect(response.hasMore, isFalse);
    });

    test('hasMore is false when page > totalPages', () {
      const response = PaginatedResponse<String>(
        items: [],
        total: 0,
        page: 2,
        totalPages: 1,
      );
      expect(response.hasMore, isFalse);
    });

    test('stores items correctly', () {
      const response = PaginatedResponse<int>(
        items: [1, 2, 3],
        total: 10,
        page: 1,
        totalPages: 4,
      );
      expect(response.items, [1, 2, 3]);
      expect(response.total, 10);
      expect(response.page, 1);
      expect(response.totalPages, 4);
    });
  });
}
