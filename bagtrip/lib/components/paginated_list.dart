import 'package:flutter/material.dart';

class PaginatedList<T> extends StatefulWidget {
  final List<T> items;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final Widget? emptyWidget;
  final EdgeInsetsGeometry? padding;
  final Future<void> Function()? onRefresh;
  final double loadMoreThreshold;

  /// For grouped lists (notifications by date, activities by day).
  final Map<String, List<T>> Function(List<T>)? groupBy;
  final Widget Function(BuildContext, String)? sectionHeaderBuilder;

  const PaginatedList({
    super.key,
    required this.items,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.itemBuilder,
    this.emptyWidget,
    this.padding,
    this.onRefresh,
    this.loadMoreThreshold = 200,
    this.groupBy,
    this.sectionHeaderBuilder,
  });

  @override
  State<PaginatedList<T>> createState() => _PaginatedListState<T>();
}

class _PaginatedListState<T> extends State<PaginatedList<T>> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.hasMore || widget.isLoadingMore) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - widget.loadMoreThreshold) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && widget.emptyWidget != null) {
      return widget.emptyWidget!;
    }

    final Widget listView;

    if (widget.groupBy != null) {
      listView = _buildGroupedList();
    } else {
      listView = _buildFlatList();
    }

    if (widget.onRefresh != null) {
      return RefreshIndicator(onRefresh: widget.onRefresh!, child: listView);
    }
    return listView;
  }

  Widget _buildFlatList() {
    final itemCount = widget.items.length + (widget.isLoadingMore ? 1 : 0);
    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index >= widget.items.length) {
          return _buildLoadingIndicator();
        }
        return widget.itemBuilder(context, widget.items[index], index);
      },
    );
  }

  Widget _buildGroupedList() {
    final grouped = widget.groupBy!(widget.items);
    final sortedKeys = grouped.keys.toList()..sort();

    // Build a flat list of widgets: header + items for each group
    final children = <Widget>[];
    var globalIndex = 0;
    for (final key in sortedKeys) {
      if (widget.sectionHeaderBuilder != null) {
        children.add(widget.sectionHeaderBuilder!(context, key));
      }
      for (final item in grouped[key]!) {
        children.add(widget.itemBuilder(context, item, globalIndex));
        globalIndex++;
      }
    }
    if (widget.isLoadingMore) {
      children.add(_buildLoadingIndicator());
    }

    return ListView(
      controller: _scrollController,
      padding: widget.padding,
      children: children,
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: CircularProgressIndicator.adaptive()),
    );
  }
}
