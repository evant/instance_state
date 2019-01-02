// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instance_state/instance_state.dart';
import 'package:instance_state_example/main.dart';

void main() {
  testWidgets('Saves counter', (tester) async {
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

  testWidgets('Saves navigation', (tester) async {
    final store = TestInstanceStateStore();

    await tester.pumpWidget(testStorage(store: store, child: MyApp()));

    await tester.tap(find.widgetWithText(MaterialButton, 'Nav'));

    expect(store.store, {
      '.navigator': ['/nav']
    });
  });

  testWidgets('Restores navigation', (tester) async {
    final store = TestInstanceStateStore();
    store.store['.navigator'] = ['/nav'];

    await tester.pumpWidget(testStorage(store: store, child: MyApp()));

    expect(tester.widget(find.byType(NavWidget)), isNotNull);
  }, skip: true);

  testWidgets('Saves scroll position', (tester) async {
    final store = TestInstanceStateStore();

    await tester.pumpWidget(testStorage(
        store: store,
        child: MaterialApp(home: ScrolledWidget(InstanceStateKey('scroll')))));

    await tester.drag(find.byType(ListView), Offset(0, -10));

    expect(store.store, {'.scroll': 10.0});
  });

  testWidgets('Restores scroll position', (tester) async {
    final store = TestInstanceStateStore();
    store.store['.scroll'] = 10.0;

    await tester.pumpWidget(testStorage(
        store: store,
        child: MaterialApp(home: ScrolledWidget(InstanceStateKey('scroll')))));

    expect((tester.state(find.byType(ScrolledWidget)) as ScrolledWidgetState).controller.offset, 10.0);
  });

  test("standard codec round-trips float64", () {
    final codec = StandardMessageCodec();
    final write = WriteBuffer();
    codec.writeValue(write, 553.9091095205873);
    final bytes = write.done();
    print("encoded: ${bytes.buffer.asUint8List(0, bytes.lengthInBytes)}");
//    final read = ReadBuffer(ByteData.view(Uint8List.fromList([6, 0, 0, 0, 0, 61, 91, 54, 219, 69, 79, 129, 64]).buffer));
    final read = ReadBuffer(bytes);
    final value = codec.readValue(read);
    expect(value, 553.9091095205873);
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
