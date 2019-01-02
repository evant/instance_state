// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instance_state/instance_state.dart';

import 'package:instance_state_example/main.dart';

void main() {
  testWidgets('Saves counter', (WidgetTester tester) async {
    final store = TestInstanceStateStore();

    await tester.pumpWidget(testStorage(
        store: store,
        child: MaterialApp(home: CounterWidget(InstanceStateKey('counter')))));

    await tester.tap(find.widgetWithText(MaterialButton, 'Increment'));

    expect(store.store, {'.counter': 1});
  });

  testWidgets('Restores counter', (tester) async {
    final store = TestInstanceStateStore();
    store.store['.counter'] = 1;

    await tester.pumpWidget(testStorage(
        store: store,
        child: MaterialApp(home: CounterWidget(InstanceStateKey('counter')))));

    expect(
        (tester.state(find.byType(CounterWidget)) as CounterState).counter, 1);
  });
}

InstanceStateStorage testStorage({TestInstanceStateStore store, Widget child}) {
  return InstanceStateStorage(
      bucket: InstanceStateBucket(store: store), child: child);
}

class TestInstanceStateStore extends InstanceStateStore {
  final Map<String, dynamic> store = {};

  @override
  Future<void> save(String key, value) {
    store[key] = value;
    return Future.value(null);
  }

  @override
  Future restore(String key) {
    return Future.value(store.remove(key));
  }

  @override
  Future<void> remove(String key) {
    store.remove(key);
    return Future.value(null);
  }
}
