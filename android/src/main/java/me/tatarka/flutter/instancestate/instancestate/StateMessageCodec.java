package me.tatarka.flutter.instancestate.instancestate;

import java.nio.ByteBuffer;
import java.nio.charset.Charset;

import io.flutter.plugin.common.MessageCodec;

public class StateMessageCodec implements MessageCodec<StateMessage> {

    public static final StateMessageCodec INSTANCE = new StateMessageCodec();
    private final Charset charset = Charset.forName("UTF-8");

    @Override
    public ByteBuffer encodeMessage(StateMessage message) {
        if (message == null || message.data == null) {
            return null;
        }
        ByteBuffer buffer = ByteBuffer.allocateDirect(length(message));
        buffer.put(message.type);
        buffer.put((byte) message.key.length());
        byte[] chars = message.key.getBytes(charset);
        buffer.put(chars);
        buffer.put(message.data);
        return buffer;
    }

    @Override
    public StateMessage decodeMessage(ByteBuffer buffer) {
        if (buffer == null) {
            return null;
        }
        byte type = buffer.get();
        byte keyLength = buffer.get();
        byte[] chars = new byte[keyLength];
        buffer.get(chars);
        String key = new String(chars, charset);
        byte[] data = null;
        if (buffer.hasRemaining()) {
            data = new byte[buffer.remaining()];
            buffer.get(data);
        }
        return new StateMessage(type, key, data);
    }

    private static final int length(StateMessage message) {
        int length = message.key.length() + 2;
        if (message.data != null) {
            length += message.data.length;
        }
        return length;
    }
}
