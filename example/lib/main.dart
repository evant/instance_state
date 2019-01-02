import 'package:flutter/material.dart';
import 'package:instance_state/instance_state.dart';

void main() =>
    runApp(InstanceStateStorage(bucket: InstanceStateBucket(), child: MyApp()));

class MyApp extends StatelessWidget {
  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final observer = NavigatorInstanceState.createObserver();
    return MaterialApp(
      navigatorKey: navigatorKey,
      routes: {
        '/': (context) => CounterWidget(InstanceStateKey('counter')),
        '/nav': (context) => NavWidget(InstanceStateKey('navigated')),
        '/scrolled': (context) => ScrolledWidget(InstanceStateKey('scroll')),
      },
      navigatorObservers: [observer],
      builder: (context, widget) =>
          NavigatorInstanceState(
            key: InstanceStateKey('navigator'),
            navigatorKey: navigatorKey,
            observer: observer,
            child: widget,
          ),
    );
  }
}

class CounterWidget extends StatefulWidget {
  CounterWidget(InstanceStateKey key) : super(key: key);

  @override
  State<StatefulWidget> createState() => CounterState();
}

class CounterState extends State<CounterWidget> with HasInstanceState {
  var counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Count: $counter\n'),
            MaterialButton(
              child: Text("Increment"),
              onPressed: () {
                setState(() {
                  counter++;
                });
              },
            ),
            MaterialButton(
              child: Text("Nav"),
              onPressed: () {
                Navigator.pushNamed(context, '/nav');
              },
            ),
            MaterialButton(
                child: Text("Scrolled"),
                onPressed: () {
                  Navigator.pushNamed(context, '/scrolled');
                })
          ],
        ),
      ),
    );
  }

  @override
  void restoreInstanceState(state) {
    counter = state;
  }

  @override
  saveInstanceState() {
    return counter;
  }
}

class NavWidget extends StatefulWidget {
  NavWidget(InstanceStateKey key) : super(key: key);

  @override
  NavWidgetState createState() {
    return new NavWidgetState();
  }
}

class NavWidgetState extends State<NavWidget> with HasInstanceState {
  bool checked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Navigated'),
      ),
      body: Center(
          child: CheckboxListTile(
            value: checked,
            onChanged: (checked) {
              setState(() {
                this.checked = checked;
              });
            },
            title: Text('Navigated'),
            controlAffinity: ListTileControlAffinity.leading,
          )),
    );
  }

  @override
  void restoreInstanceState(state) {
    checked = state;
  }

  @override
  saveInstanceState() {
    return checked;
  }
}

class ScrolledWidget extends StatefulWidget {

  ScrolledWidget(InstanceStateKey key): super(key: key);

  @override
  ScrolledWidgetState createState() => new ScrolledWidgetState();
}

class ScrolledWidgetState extends State<ScrolledWidget> {
  ScrollController _controller;

  @override
  void initState() {
    _controller = InstanceStateScrollController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scrolled'),
      ),
      body: ListView.builder(
        itemBuilder: (context, index) =>
            ListTile(
              title: Text("Item: $index"),
            ),
        itemCount: 30,
        controller: _controller,
      ),
    );
  }
}

class InstanceStateScrollController extends ScrollController {
  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics,
      ScrollContext context, ScrollPosition oldPosition) {
    return InstanceStateScrollPosition(
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }
}

class InstanceStateScrollPosition extends ScrollPositionWithSingleContext {
  InstanceStateScrollPosition({ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition oldPosition,
    double initialPixels,
    bool keepScrollOffset,
    String debugLabel})
      : super(
      physics: physics,
      context: context,
      oldPosition: oldPosition,
      initialPixels: initialPixels,
      keepScrollOffset: keepScrollOffset,
      debugLabel: debugLabel);

  @override
  void saveScrollOffset() {
    super.saveScrollOffset();
    InstanceStateStorage.of(context.storageContext)
        ?.save(context.storageContext, pixels);
  }

  @override
  void restoreScrollOffset() async {
    super.restoreScrollOffset();
    if (pixels == null) {
      double value = await InstanceStateStorage.of(context.storageContext)
          ?.restore(context.storageContext);
      if (value != null) {
        correctPixels(value);
      }
    }
  }
}
