package me.tatarka.flutter.instancestate.instancestate;

public final class StateMessage {

    public static final byte TYPE_GET = 0;
    public static final byte TYPE_SET = 1;

    public final byte type;
    public final String key;
    public byte[] data;

    public StateMessage(byte type, String key, byte[] data) {
        this.type = type;
        this.key = key;
        this.data = data;
    }
}
