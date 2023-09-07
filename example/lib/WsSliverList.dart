import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:great_list_view/great_list_view.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'main.dart';

abstract class DiffableWidget extends Widget {
  bool areItemsTheSame(DiffableWidget oldWidget);

  bool areContentsTheSame(DiffableWidget oldWidget);

  double? estimateWidgetMainAxisSize();
}

class WsSliverListPaging extends StatefulWidget {
  const WsSliverListPaging({
    super.key,
    required this.widgets,
    required this.builder,
    required this.loadMore,
  });

  final List<DiffableWidget> widgets;
  final Widget Function(BuildContext, AnimatedSliverList) builder;
  final Future<bool> Function() loadMore;

  @override
  State<WsSliverListPaging> createState() => _WsSliverListPagingState();
}

class _WsSliverListPagingState extends State<WsSliverListPaging> {
  final Key detectorKey = UniqueKey();
  final Key detectorKey2 = UniqueKey();
  var loadingMore = false;
  var shouldTryToLoadMore = true;

  void onLoadMoreRendered() {
    if (!loadingMore && shouldTryToLoadMore) {
      loadingMore = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        tryToLoadMore();
      });
    }
  }

  void tryToLoadMore() async {
    final result = await widget.loadMore();
    if (!result) {
      shouldTryToLoadMore = false;
    }
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      loadingMore = false; // Wait for scroll to update first
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      /*NotificationListener<ScrollUpdateNotification>(
      onNotification: (it) {
        final diff = it.metrics.maxScrollExtent - it.metrics.pixels;
        print('diff $diff');
        if (diff < 100) {
          onLoadMoreRendered();
        }
        return false;
      },*/
      child: WsSliverList(
        widgets: [
          for (int i = 0; i < widget.widgets.length; i++)
            if (i == widget.widgets.length - 3)
              _LoadMoreWhenVisibleDetector(
                detectorKey: detectorKey,
                onLoadMoreRendered: onLoadMoreRendered,
                child: widget.widgets[i],
              )
            else
              widget.widgets[i],
          if (shouldTryToLoadMore)
            _LoadMore(
              detectorKey: detectorKey2,
              index: widget.widgets.length,
              loadMoreRendered: onLoadMoreRendered,
            )
        ],
        builder: widget.builder,
      ),
    );
  }
}

class WsSliverList extends StatefulWidget {
  const WsSliverList({super.key, required this.widgets, required this.builder});

  final List<DiffableWidget> widgets;
  final Widget Function(BuildContext, AnimatedSliverList) builder;

  @override
  State<WsSliverList> createState() => _WsSliverListState();
}

class _WsSliverListState extends State<WsSliverList> {
  final controller = AnimatedListController();
  late AnimatedListDiffListDispatcher<DiffableWidget> dispatcher;

  @override
  void didUpdateWidget(covariant WsSliverList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.widgets != widget.widgets) {
      dispatcher.dispatchNewList(widget.widgets, detectMoves: false);
    }
  }

  @override
  void initState() {
    super.initState();
    dispatcher = AnimatedListDiffListDispatcher<DiffableWidget>(
      controller: controller,
      itemBuilder: (BuildContext _, DiffableWidget widget, AnimatedWidgetBuilderData ___) => widget,
      currentList: widget.widgets,
      comparator: AnimatedListDiffListComparator<DiffableWidget>(
        sameItem: (a, b) => a.areItemsTheSame(b),
        sameContent: (a, b) => a.areContentsTheSame(b),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      AnimatedSliverList(
        controller: controller,
        delegate: AnimatedSliverChildBuilderDelegate(
          (context, index, data) {
            final size = dispatcher.currentList[index].estimateWidgetMainAxisSize();
            return (data.measuring && size != null) ? SizedBox(height: size) : dispatcher.currentList[index];
          },
          dispatcher.currentList.length,
          holdScrollOffset: true,
        ),
      ),
    );
  }
}

class _LoadMore extends StatelessWidget implements DiffableWidget {
  const _LoadMore({super.key, required this.detectorKey, required this.index, required this.loadMoreRendered});

  final Key detectorKey;
  final int index;
  final void Function() loadMoreRendered;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: detectorKey,
      onVisibilityChanged: (visibilityInfo) {
        var visiblePercentage = visibilityInfo.visibleFraction * 100;
        if (visiblePercentage > 50) {
          print('visiblePercentage: $visiblePercentage');
          loadMoreRendered();
        }
      },
      child: SizedBox(
        height: 100,
        width: double.infinity,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  @override
  bool areContentsTheSame(DiffableWidget oldWidget) => oldWidget is _LoadMore;

  @override
  bool areItemsTheSame(DiffableWidget oldWidget) => oldWidget is _LoadMore && oldWidget.index == index;

  @override
  double? estimateWidgetMainAxisSize() => 100;
}

class _LoadMoreWhenVisibleDetector extends StatelessWidget implements DiffableWidget {
  const _LoadMoreWhenVisibleDetector({
    super.key,
    required this.detectorKey,
    required this.onLoadMoreRendered,
    required this.child,
  });

  final Key detectorKey;
  final DiffableWidget child;
  final void Function() onLoadMoreRendered;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: detectorKey,
      onVisibilityChanged: (visibilityInfo) {
        var visiblePercentage = visibilityInfo.visibleFraction * 100;
        if (visiblePercentage > 50) {
          onLoadMoreRendered();
        }
      },
      child: child,
    );
  }

  @override
  bool areContentsTheSame(DiffableWidget oldWidget) => child.areContentsTheSame(oldWidget);

  @override
  bool areItemsTheSame(DiffableWidget oldWidget) => child.areItemsTheSame(oldWidget);

  @override
  double? estimateWidgetMainAxisSize() => child.estimateWidgetMainAxisSize();
}
