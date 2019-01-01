import 'dart:async';

import 'package:flutter/material.dart';
import 'package:instance_state/instance_state.dart';

void main() => runApp(InstanceStateWidget(child: MyApp()));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with HasInstanceState {
  var _counter = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
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
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  String get instanceStateKey => "counter";

  @override
  saveInstanceState() {
    return _counter;
  }

  @override
  void restoreInstanceState(state) {
    _counter = state;
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

  @override
  Widget build(BuildContext context) {}

  dynamic saveInstanceState();

  void restoreInstanceState(dynamic state);
}
