class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;

  const PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.totalPages,
  });
}
