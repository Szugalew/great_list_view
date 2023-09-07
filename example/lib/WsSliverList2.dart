import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:great_list_view/great_list_view.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'WsSliverList.dart';
import 'main.dart';

class WsSliverListPaging2 extends StatefulWidget {
  const WsSliverListPaging2({
    super.key,
    required this.widgets,
    required this.builder,
    required this.loadMore,
  });

  final List<DiffableWidget> widgets;
  final Widget Function(BuildContext, SliverImplicitlyAnimatedList) builder;
  final Future<bool> Function() loadMore;

  @override
  State<WsSliverListPaging2> createState() => _WsSliverListPaging2State();
}

class _WsSliverListPaging2State extends State<WsSliverListPaging2> {
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
    loadingMore = false;
  }

  @override
  Widget build(BuildContext context) {
    return WsSliverList2(
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
    );
  }
}

class WsSliverList2 extends StatefulWidget {
  const WsSliverList2({super.key, required this.widgets, required this.builder});

  final List<DiffableWidget> widgets;
  final Widget Function(BuildContext, SliverImplicitlyAnimatedList) builder;

  @override
  State<WsSliverList2> createState() => _WsSliverList2State();
}

class _WsSliverList2State extends State<WsSliverList2> {
  final controller = AnimatedListController();

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      SliverImplicitlyAnimatedList<DiffableWidget>(
        items: widget.widgets,
        itemBuilder: (context, animation, item, index) => FadeTransition(
          opacity: animation,
          child: item,
        ),
        areItemsTheSame: (widget1, widget2) => widget1.areItemsTheSame(widget2),
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
