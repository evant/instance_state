import 'dart:async';

import 'package:flutter/material.dart';
import 'package:instance_state/instance_state.dart';

void main() => runApp(InstanceStateWidget(child: MyApp()));

class MyApp extends StatelessWidget {
  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      onGenerateRoute: (settings) => null,
      builder: (context, widget) => InstanceStateNavigator.routes(
              navigatorKey: navigatorKey,
              routes: {
                "/": (context) => CounterWidget(),
                "/hello": (context) => HelloWidget()
              }),
    );
  }
}

class CounterWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => CounterState();
}

class CounterState extends State<CounterWidget> with HasInstanceState {
  var _counter = 0;

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
            Text('Count: $_counter\n'),
            MaterialButton(
              child: Text("Increment"),
              onPressed: () {
                setState(() {
                  _counter++;
                });
              },
            ),
            MaterialButton(
              child: Text("Hello"),
              onPressed: () {
                InstanceStateNavigator.pushNamed(context, "/hello");
              },
            )
          ],
        ),
      ),
    );
  }

  @override
  String get instanceStateKey => "counter";

  @override
  void restoreInstanceState(state) {
    _counter = state;
  }

  @override
  saveInstanceState() {
    return _counter;
  }
}

class HelloWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Hello"),
    );
  }
}

class InstanceStateWidget extends InheritedWidget {
  InstanceStateWidget(
      {Key key,
      @required Widget child,
      this.instanceStateStore = const InstanceStateStore()})
      : super(key: key, child: child);

  final InstanceStateStore instanceStateStore;

  static InstanceStateWidget of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(InstanceStateWidget);
  }

  Future<dynamic> restore(HasInstanceState mixin) {
    return instanceStateStore.restore(_key(mixin));
  }

  void save(HasInstanceState mixin, dynamic value) {
    instanceStateStore.save(_key(mixin), value);
  }

  String _key(HasInstanceState mixin) {
    HasInstanceState parent =
        mixin.context.ancestorStateOfType(TypeMatcher<HasInstanceState>());
    if (parent != null) {
      return _key(parent) + "." + mixin.instanceStateKey;
    } else {
      return mixin.instanceStateKey;
    }
  }

  @override
  bool updateShouldNotify(InstanceStateWidget oldWidget) {
    return this.instanceStateStore != oldWidget.instanceStateStore;
  }
}

mixin HasInstanceState<T extends StatefulWidget> on State<T> {
  String get instanceStateKey;

  Future<void> _initPlatformState() async {
    var state = await InstanceStateWidget.of(context).restore(this);
    if (!mounted) return;
    if (state != null) {
      setState(() {
        restoreInstanceState(state);
      });
    }
  }

  @override
  void didChangeDependencies() {
    _initPlatformState();
  }

  @override
  void setState(fn) {
    super.setState(fn);
    InstanceStateWidget.of(context).save(this, saveInstanceState());
  }

  dynamic saveInstanceState();

  void restoreInstanceState(dynamic state);
}

class InstanceStateNavigator extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final RouteFactory onGenerateRoute;

  InstanceStateNavigator(
      {Key key, this.navigatorKey, @required this.onGenerateRoute})
      : super(key: key);

  factory InstanceStateNavigator.routes(
      {GlobalKey<NavigatorState> navigatorKey,
      @required Map<String, WidgetBuilder> routes,
      PageRouteFactory pageRouteBuilder}) {
    return InstanceStateNavigator(
        navigatorKey: navigatorKey,
        onGenerateRoute: (settings) {
          final name = settings.name;
          final routes = {
            "/": (context) => CounterWidget(),
            "/hello": (context) => HelloWidget()
          };
          final pageContentBuilder = routes[name];
          final Route<dynamic> route = pageRouteBuilder != null
              ? pageRouteBuilder(settings, pageContentBuilder)
              : MaterialPageRoute(
                  builder: pageContentBuilder, settings: settings);
          return route;
        });
  }

  static InstanceStateNavigatorState of(BuildContext context) {
    return context
        .ancestorStateOfType(TypeMatcher<InstanceStateNavigatorState>());
  }

  static void pushNamed(BuildContext context, String routeName) {
    of(context).pushNamed(routeName);
  }

  static bool pop(BuildContext context) {
    return of(context).pop();
  }

  @override
  State<StatefulWidget> createState() => InstanceStateNavigatorState();
}

class InstanceStateNavigatorState extends State<InstanceStateNavigator>
    with HasInstanceState {
  List<dynamic> stack = [];

  @override
  Widget build(BuildContext context) {
    return Navigator(
        key: widget.navigatorKey, onGenerateRoute: widget.onGenerateRoute);
  }

  @override
  String get instanceStateKey => "navigator";

  @override
  void restoreInstanceState(state) {
    stack = state;
    for (var routeName in stack) {
      widget.navigatorKey.currentState.pushNamed(routeName);
    }
  }

  @override
  saveInstanceState() {
    return stack;
  }

  void pushNamed(String routeName) {
    widget.navigatorKey.currentState.pushNamed(routeName);
    setState(() {
      stack.add(routeName);
    });
  }

  bool pop() {
    bool result = widget.navigatorKey.currentState.pop();
    if (result) {
      setState(() {
        stack.removeLast();
      });
    }
    return result;
  }
}
