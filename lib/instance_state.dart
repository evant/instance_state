import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show ReadBuffer, WriteBuffer;
import 'package:flutter/services.dart';

class StateMessage {
  static const TYPE_GET = 0;
  static const TYPE_SET = 1;

  int type;
  String key;
  dynamic data;

  StateMessage(this.type, this.key, this.data);

  static StateMessage get(String key) => StateMessage(TYPE_GET, key, null);

  static StateMessage set(String key, dynamic data) =>
      StateMessage(TYPE_SET, key, data);
}

const Utf8Codec utf8 = const Utf8Codec();

class StateMessageCodec implements MessageCodec<dynamic> {
  const StateMessageCodec([this.messageCodec = const StandardMessageCodec()]);

  final StandardMessageCodec messageCodec;

  @override
  ByteData encodeMessage(dynamic message) {
    if (message == null) {
      return null;
    }
    var buffer = WriteBuffer();
    buffer.putUint8(message.type);
    buffer.putUint8(message.key.length);
    List<int> chars = utf8.encoder.convert(message.key);
    buffer.putUint8List(chars);
    if (message.data != null) {
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

  Future<dynamic> restore(String key) {
    if (key == null) {
      throw ArgumentError.notNull("key");
    }
    return _channel.send(StateMessage.get(key));
  }
}
