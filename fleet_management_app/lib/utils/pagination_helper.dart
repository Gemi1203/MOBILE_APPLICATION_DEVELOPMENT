import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Pagination helper for Firestore queries
class PaginationHelper {
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  final int pageSize;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;

  PaginationHelper({this.pageSize = defaultPageSize})
    : assert(pageSize > 0 && pageSize <= maxPageSize);

  /// Reset pagination
  void reset() {
    _lastDocument = null;
    _hasMore = true;
  }

  /// Load next page of documents
  Future<List<QueryDocumentSnapshot>> loadNextPage(Query query) async {
    if (!_hasMore) return [];

    try {
      Query q = query.limit(
        pageSize + 1,
      ); // Load one extra to check if more exist

      if (_lastDocument != null) {
        q = q.startAfterDocument(_lastDocument!);
      }

      final snapshot = await q.get();
      final docs = snapshot.docs;

      if (docs.length <= pageSize) {
        _hasMore = false;
        return docs;
      } else {
        // Remove the extra document
        _lastDocument = docs[pageSize - 1];
        return docs.sublist(0, pageSize);
      }
    } catch (e) {
      debugPrint('Error loading next page: $e');
      return [];
    }
  }

  /// Check if more pages are available
  bool get hasMore => _hasMore;

  /// Get current page size
  int get currentPageSize => pageSize;
}

/// Stream-based pagination helper
class StreamPaginationHelper {
  final int pageSize;
  DocumentSnapshot? _lastDocument;

  StreamPaginationHelper({this.pageSize = PaginationHelper.defaultPageSize})
    : assert(pageSize > 0 && pageSize <= PaginationHelper.maxPageSize);

  /// Reset pagination
  void reset() {
    _lastDocument = null;
  }

  /// Create paginated stream
  Stream<List<QueryDocumentSnapshot>> createPaginatedStream(
    Query query,
  ) async* {
    Query currentQuery = query;
    bool hasMore = true;

    while (hasMore) {
      final q = currentQuery.limit(pageSize + 1);

      final snapshot = await q.get();
      final docs = snapshot.docs;

      if (docs.isEmpty) {
        hasMore = false;
      } else if (docs.length <= pageSize) {
        yield docs;
        hasMore = false;
      } else {
        yield docs.sublist(0, pageSize);
        _lastDocument = docs[pageSize - 1];
        currentQuery = query.startAfterDocument(_lastDocument!);
      }
    }
  }
}

/// Memory-efficient list builder for large lists
class OptimizedListBuilder {
  /// Build optimized list from paginated data
  static Widget buildPaginatedList({
    required List<dynamic> items,
    required Widget Function(BuildContext, int, dynamic) itemBuilder,
    required VoidCallback onLoadMore,
    bool isLoading = false,
    bool hasMore = true,
    int scrollThreshold = 5,
  }) {
    return ListView.builder(
      itemCount: items.length + (hasMore && isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading indicator
        if (index == items.length) {
          return hasMore
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                )
              : const SizedBox.shrink();
        }

        // Check if we need to load more
        if (!isLoading && hasMore && index >= items.length - scrollThreshold) {
          onLoadMore();
        }

        return itemBuilder(context, index, items[index]);
      },
    );
  }
}
