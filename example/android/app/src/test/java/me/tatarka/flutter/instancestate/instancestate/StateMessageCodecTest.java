package me.tatarka.flutter.instancestate.instancestate;

import org.junit.Test;

import java.nio.ByteBuffer;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNull;

public class StateMessageCodecTest {

    private final StateMessageCodec codec = StateMessageCodec.INSTANCE;

    @Test
    public void round_trips_null() {
        StateMessage newMessage = codec.decodeMessage(codec.encodeMessage(null));
        assertNull(newMessage);
    }

    @Test
    public void round_trips_get_message_with_no_data() {
        StateMessage message = new StateMessage(StateMessage.TYPE_GET, "test", null);
        ByteBuffer buffer = codec.encodeMessage(message);
        buffer.rewind();
        StateMessage newMessage = codec.decodeMessage(buffer);

        assertEquals(StateMessage.TYPE_GET, newMessage.type);
        assertEquals("test", newMessage.key);
        assertNull(newMessage.data);
        assertFalse(buffer.hasRemaining());
    }

    @Test
    public void round_trips_set_message_with_data() {
        StateMessage message = new StateMessage(StateMessage.TYPE_SET, "test", new byte[]{1, 2, 3});
        ByteBuffer buffer = codec.encodeMessage(message);
        buffer.rewind();
        StateMessage newMessage = codec.decodeMessage(buffer);

        assertEquals(StateMessage.TYPE_SET, newMessage.type);
        assertEquals("test", newMessage.key);
        assertArrayEquals(new byte[]{1, 2, 3}, newMessage.data);
        assertFalse(buffer.hasRemaining());
    }
}