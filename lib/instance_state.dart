import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show ReadBuffer, WriteBuffer;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class StateMessage {
  static const TYPE_GET = 0;
  static const TYPE_SET = 1;
  static const TYPE_REMOVE = 2;

  int type;
  String key;
  dynamic data;

  StateMessage(this.type, this.key, this.data);

  static StateMessage get(String key) => StateMessage(TYPE_GET, key, null);

  static StateMessage set(String key, dynamic data) =>
      StateMessage(TYPE_SET, key, data);

  static StateMessage remove(String key) =>
      StateMessage(TYPE_REMOVE, key, null);
}

const Utf8Codec utf8 = const Utf8Codec();

/// Encodes/decodes a [StateMessage]. Note: this is asymmetric as we only need
/// extra information on the request side. [encodeMessage] will encode to a
/// [StateMessage], the expected byte format is:
/// <pre>
/// type (1 byte)
/// key length (1 byte)
/// key (key length bytes, utf8-encoded)
/// padding to align to 8 bytes
/// data (remaining bytes, encoded using [StandardMessageCodec])
/// </pre>
/// Alignment padding is included before the data so that everything else can be
/// stripped without changing how the data is encoded.
///
/// [decodeMessage] will just decode the data using [StandardMessageCodec].
class StateMessageCodec implements MessageCodec<dynamic> {
  const StateMessageCodec([this.messageCodec = const StandardMessageCodec()]);

  final StandardMessageCodec messageCodec;

  @override
  ByteData encodeMessage(dynamic message) {
    if (message == null) {
      return null;
    }
    final buffer = WriteBuffer();
    buffer.putUint8(message.type);
    buffer.putUint8(message.key.length);
    List<int> chars = utf8.encoder.convert(message.key);
    buffer.putUint8List(chars);
    if (message.data != null) {
      _writeAlignment8(buffer);
      messageCodec.writeValue(buffer, message.data);
    }
    return buffer.done();
  }

  @override
  dynamic decodeMessage(ByteData bytes) {
    if (bytes == null) {
      return null;
    }
    return messageCodec.readValue(ReadBuffer(bytes));
  }

  void _writeAlignment8(WriteBuffer buffer) {
    // We need to force an alignment but we don't know how much data has been
    // written in the buffer already. Luckily, putFloat64List() can do this for
    // us, as it uses _alignTo(8) under the hood. By passing an empty list we
    // can trigger this without adding any additional data.
    buffer.putFloat64List(Float64List(0));
  }
}

class InstanceStateStore {
  factory InstanceStateStore.withCodec(StandardMessageCodec messageCodec) {
    return InstanceStateStore(
        BasicMessageChannel('internal_state', StateMessageCodec(messageCodec)));
  }

  const InstanceStateStore(
      [this._channel = const BasicMessageChannel(
          'instance_state', const StateMessageCodec())]);

  final BasicMessageChannel _channel;

  Future<void> save(String key, dynamic value) {
    if (key == null) {
      throw ArgumentError.notNull("key");
    }
    return _channel.send(StateMessage.set(key, value));
  }

  Future<void> remove(String key) {
    if (key == null) {
      throw ArgumentError.notNull("key");
    }
    return _channel.send(StateMessage.remove(key));
  }

  Future<dynamic> restore(String key) {
    if (key == null) {
      throw ArgumentError.notNull("key");
    }
    return _channel.send(StateMessage.get(key));
  }
}

class InstanceStateKey extends ValueKey<String> {
  const InstanceStateKey(String value) : super(value);
}

class InstanceStateBucket {
  final InstanceStateKey key;
  final InstanceStateStore store;
  final Map<BuildContext, String> _identifiers = {};

  InstanceStateBucket({this.key, this.store = const InstanceStateStore()});

  Future<dynamic> restore(BuildContext context) {
    final identifier =
        _identifiers.putIfAbsent(context, () => _computeIdentifier(context));
    return store.restore(identifier);
  }

  void save(BuildContext context, dynamic value) {
    final identifier =
        _identifiers.putIfAbsent(context, () => _computeIdentifier(context));
    store.save(identifier, value);
  }

  void remove(BuildContext context) {
    final identifier = _identifiers.remove(context);
    if (identifier != null) {
      store.remove(identifier);
    }
  }

  static bool _maybeAddKey(BuildContext context, StringBuffer result) {
    final Widget widget = context.widget;
    final Key key = widget.key;
    if (key is InstanceStateKey) {
      result.write('.');
      result.write(key.value);
    }
    return widget is! InstanceStateKey;
  }

  String _computeIdentifier(BuildContext context) {
    final StringBuffer result = new StringBuffer();
    if (_maybeAddKey(context, result)) {
      context.visitAncestorElements((element) {
        return _maybeAddKey(element, result);
      });
    }
    if (key != null) {
      result.write('.');
      result.write(key.value);
    }
    return result.toString();
  }
}

class InstanceStateStorage extends StatelessWidget {
  final Widget child;
  final InstanceStateBucket bucket;

  const InstanceStateStorage(
      {Key key, @required this.bucket, @required this.child})
      : assert(bucket != null),
        super(key: key);

  static InstanceStateBucket of(BuildContext context) {
    final InstanceStateStorage widget =
        context.ancestorWidgetOfExactType(InstanceStateStorage);
    return widget?.bucket;
  }

  @override
  Widget build(BuildContext context) => child;
}

mixin HasInstanceState<T extends StatefulWidget> on State<T> {
  InstanceStateBucket bucket;

  Future<void> _initPlatformState() async {
    var state = await bucket.restore(context);
    if (!mounted) return;
    if (state != null) {
      setState(() {
        restoreInstanceState(state);
      });
    }
  }

  @override
  void didChangeDependencies() {
    assert(context.widget.key is InstanceStateKey,
        "Widget must have an InstanceStateKey");
    bucket = InstanceStateStorage.of(context);
    _initPlatformState();
  }

  @override
  void dispose() {
    bucket.remove(context);
    super.dispose();
  }

  @override
  void setState(fn) {
    super.setState(fn);
    save();
  }

  void save() {
    bucket.save(context, saveInstanceState());
  }

  dynamic saveInstanceState();

  void restoreInstanceState(dynamic state);
}

class NavigatorInstanceState extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final NavigatorInstanceStateObserver observer;
  final Widget child;

  NavigatorInstanceState(
      {@required InstanceStateKey key,
      @required this.navigatorKey,
      @required this.observer,
      this.child})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => NavigatorInstanceStateState();

  static NavigatorObserver createObserver() => NavigatorInstanceStateObserver();
}

class NavigatorInstanceStateState extends State<NavigatorInstanceState>
    with HasInstanceState {
  final List<dynamic> stack = [];

  @override
  void initState() {
    super.initState();
    widget.observer._state = this;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void restoreInstanceState(state) {
    stack.addAll(state);
    widget.observer._restoring = true;
    for (var routeName in stack) {
      widget.navigatorKey.currentState.pushNamed(routeName);
    }
    widget.observer._restoring = false;
  }

  @override
  saveInstanceState() {
    return stack;
  }
}

class NavigatorInstanceStateObserver extends NavigatorObserver {
  NavigatorInstanceStateState _state;
  bool _restoring = false;

  @override
  void didPush(Route route, Route previousRoute) {
    if (!_restoring && previousRoute != null) {
      String routeName = route.settings.name;
      assert(routeName != null, "Anonomous routes are not supported.");
      _state.setState(() {
        _state.stack.add(routeName);
      });
    }
  }

  @override
  void didPop(Route route, Route previousRoute) {
    _state.setState(() {
      _state.stack.removeLast();
    });
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
  InstanceStateScrollPosition(
      {ScrollPhysics physics,
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
        forcePixels(value);
      }
    }
  }
}
