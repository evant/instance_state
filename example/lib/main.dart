import 'dart:async';

import 'package:flutter/material.dart';
import 'package:instance_state/instance_state.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends InstanceState<MyApp> {
  var _counter = 0;

  _MyAppState() : super("counter");

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
  saveInstanceState() {
    return _counter;
  }

  @override
  void restoreInstanceState(state) {
    _counter = state;
  }
}

abstract class InstanceState<T extends StatefulWidget> extends State<T> {
  String key;

  InstanceState(this.key);

  @override
  void initState() {
    super.initState();
    _initPlatformState();
  }

  Future<void> _initPlatformState() async {
    var state = await InstanceStateStore.restore(key);
    if (!mounted) return;
    setState(() {
      restoreInstanceState(state);
    });
  }

  @override
  void setState(fn) {
    super.setState(fn);
    InstanceStateStore.save(key, saveInstanceState());
  }

  dynamic saveInstanceState();

  void restoreInstanceState(dynamic state);
}
