import 'dart:math';

import 'package:flutter/material.dart';
import 'package:great_list_view/great_list_view.dart';
import 'package:testlib/WsSliverList.dart';

import 'WsSliverList2.dart';

void main() {
  Executor().warmUp();
  runApp(App());
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Test App',
        home: SafeArea(
            child: Scaffold(
          body: Body(key: gkey),
        )));
  }
}

class Body extends StatefulWidget {
  Body({Key? key}) : super(key: key);

  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  var list = listA;

  void swapList() {
    setState(() {
      list = newList(0);
    });
  }

  void removeItem(int id) {
    setState(() {
      list = list.where((e) => e.id != id).toList();
    });
  }

  void loadMore() {
    setState(() {
      list = list + newList(list.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WsSliverListPaging(
      widgets: list.map((e) => Item(data: e)).toList(),
      loadMore: () async {
        loadMore();
        return true;
      },
      builder: (context, animatedSliverList) => Scrollbar(
        controller: scrollController,
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverAppBar(
              stretch: true,
              pinned: true,
              onStretchTrigger: () async {
                // Triggers when stretching
              },
              stretchTriggerOffset: 300.0,
              expandedHeight: 200.0,
              flexibleSpace: const FlexibleSpaceBar(
                title: Text('SliverAppBar'),
                background: FlutterLogo(),
              ),
            ),
            animatedSliverList,
          ],
        ),
      ),
    );
  }
}

class Item extends StatelessWidget implements DiffableWidget {
  final ItemData data;

  const Item({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () => gkey.currentState?.swapList(),
        child: AnimatedContainer(
            height: 140,
            duration: kDefaultMorphTransitionDuration,
            margin: EdgeInsets.all(5),
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: data.color,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black12)],
                border: Border.all(color: Colors.black12, width: 0)),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    'https://source.unsplash.com/random/' + data.id.toString(),
                    gaplessPlayback: true,
                    height: 100,
                    width: 100,
                    fit: BoxFit.fill,
                  ),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Item ${data.id}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Wow this is so cool!',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                Spacer(),
                FilledButton(
                    onPressed: () {
                      gkey.currentState?.removeItem(data.id);
                    },
                    child: Text("Click me")),
              ],
            )));
  }

  @override
  bool areContentsTheSame(DiffableWidget oldWidget) => oldWidget is Item && oldWidget.data == data;

  @override
  bool areItemsTheSame(DiffableWidget oldWidget) => oldWidget is Item && oldWidget.data.id == data.id;

  @override
  double? estimateWidgetMainAxisSize() => null;
}

Widget itemBuilder(BuildContext context, ItemData item, AnimatedWidgetBuilderData data) {
  if (data.measuring) {
    return Container(margin: EdgeInsets.all(5), height: 60);
  }
  return Item(data: item);
}

class ItemData {
  final int id;
  final Color color;
  final double? fixedHeight;

  const ItemData(this.id, [this.color = Colors.blue, this.fixedHeight]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemData &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          color == other.color &&
          fixedHeight == other.fixedHeight;

  @override
  int get hashCode => id.hashCode ^ color.hashCode ^ fixedHeight.hashCode;
}

List<ItemData> listA =
    List.generate(10, (index) => ItemData(index, [Colors.orange, Colors.blue, Colors.green][Random().nextInt(3)]))
      ..shuffle(Random());

List<ItemData> newList(int offset) => List.generate(
    10, (index) => ItemData(index + offset, [Colors.orange, Colors.blue, Colors.green][Random().nextInt(3)]))
  ..shuffle(Random());

final scrollController = ScrollController();
final gkey = GlobalKey<_BodyState>();
