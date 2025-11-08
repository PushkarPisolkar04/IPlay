/// Pagination helper for managing paginated lists
class PaginationHelper<T> {
  final int itemsPerPage;
  final List<T> allItems;
  
  int _currentPage = 1;
  
  PaginationHelper({
    required this.allItems,
    this.itemsPerPage = 20,
  });
  
  /// Get items for current page
  List<T> get currentItems {
    final startIndex = 0;
    final endIndex = _currentPage * itemsPerPage;
    
    if (endIndex >= allItems.length) {
      return allItems;
    }
    
    return allItems.sublist(startIndex, endIndex);
  }
  
  /// Check if there are more items to load
  bool get hasMore {
    return _currentPage * itemsPerPage < allItems.length;
  }
  
  /// Load next page
  void loadMore() {
    if (hasMore) {
      _currentPage++;
    }
  }
  
  /// Reset pagination
  void reset() {
    _currentPage = 1;
  }
  
  /// Get current page number
  int get currentPage => _currentPage;
  
  /// Get total pages
  int get totalPages => (allItems.length / itemsPerPage).ceil();
  
  /// Get total items count
  int get totalItems => allItems.length;
  
  /// Get displayed items count
  int get displayedItems => currentItems.length;
}
