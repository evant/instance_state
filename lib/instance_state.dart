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
const StandardMessageCodec standardMessageCodec = StandardMessageCodec();

class StateMessageCodec implements MessageCodec<StateMessage> {
  const StateMessageCodec();

  @override
  ByteData encodeMessage(StateMessage message) {
    if (message == null) {
      return null;
    }
    var buffer = WriteBuffer();
    buffer.putUint8(message.type);
    buffer.putUint8(message.key.length);
    List<int> chars = utf8.encoder.convert(message.key);
    buffer.putUint8List(chars);
    if (message.data != null) {
      var data = standardMessageCodec.encodeMessage(message.data);
      buffer.putUint8List(data.buffer.asUint8List());
    }
    return buffer.done();
  }

  @override
  StateMessage decodeMessage(ByteData bytes) {
    if (bytes == null) {
      return null;
    }
    var buffer = ReadBuffer(bytes);
    int type = buffer.getUint8();
    int keyLength = buffer.getUint8();
    String key = utf8.decoder.convert(buffer.getUint8List(keyLength));
    dynamic data;
    if (buffer.hasRemaining) {
      int remaining = bytes.lengthInBytes - keyLength - 2;
      data = standardMessageCodec
          .decodeMessage(buffer.getUint8List(remaining).buffer.asByteData());
    }
    return StateMessage(type, key, data);
  }
}

class InstanceStateStore {
  static const BasicMessageChannel _channel =
      const BasicMessageChannel('instance_state', StateMessageCodec());

  static Future<void> save(String key, dynamic value) {
    if (key == null) {
      throw ArgumentError.notNull("key");
    }
    return _channel.send(StateMessage.set(key, value));
  }

  static Future<dynamic> restore(String key) async {
    if (key == null) {
      throw ArgumentError.notNull("key");
    }
    var message = await _channel.send(StateMessage.get(key));
    return message.data;
  }
}
