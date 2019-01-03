package me.tatarka.flutter.instancestate.instancestate;

import java.nio.ByteBuffer;
import java.nio.charset.Charset;

import io.flutter.plugin.common.MessageCodec;

/**
 * Encodes/decodes a {@link StateMessage}. Note: this is asymmetric as we only need extra
 * information on the request side. {@link #decodeMessage(ByteBuffer)} will decode to a
 * {@code StateMessage}, the expected byte format is:
 * <pre>
 * type (1 byte)
 * key length (1 byte)
 * key (key length bytes, utf8-encoded)
 * padding to align to 8 bytes
 * data (remaining bytes)
 * </pre>
 * Alignment padding is included before the data so that everything else can be stripped without
 * changing how the data is encoded.
 * <p>
 * {@link #encodeMessage(StateMessage)} will encode just the data.
 */
public class StateMessageCodec implements MessageCodec<StateMessage> {

    public static final StateMessageCodec INSTANCE = new StateMessageCodec();
    private final Charset charset = Charset.forName("UTF-8");

    @Override
    public ByteBuffer encodeMessage(StateMessage message) {
        if (message == null || message.data == null) {
            return null;
        }
        ByteBuffer buffer = ByteBuffer.allocateDirect(message.data.length);
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
            // data is aligned to 8 bytes so that the type and key can be removed without
            // changing it's result. This way they don't have to be sent in the response.
            readAlignment8(buffer);
            data = new byte[buffer.remaining()];
            buffer.get(data);
        }
        return new StateMessage(type, key, data);
    }

    private static void readAlignment8(ByteBuffer buffer) {
        int mod = buffer.position() % 8;
        if (mod != 0) {
            buffer.position(buffer.position() + 8 - mod);
        }
    }
}
