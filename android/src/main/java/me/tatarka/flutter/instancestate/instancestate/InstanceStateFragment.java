package me.tatarka.flutter.instancestate.instancestate;

import android.app.Fragment;
import android.os.Bundle;
import android.util.Log;

import io.flutter.plugin.common.BasicMessageChannel;

public class InstanceStateFragment extends Fragment implements BasicMessageChannel.MessageHandler<StateMessage> {

    private Bundle restoreState;
    private Bundle saveState;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.d("flutter", "onCreate");
        if (savedInstanceState != null) {
            Log.d("flutter", "restoring: " + savedInstanceState);
            restoreState = savedInstanceState;
        }
    }

    @Override
    public void onSaveInstanceState(Bundle outState) {
        super.onSaveInstanceState(outState);
        if (saveState != null) {
            outState.putAll(saveState);
            Log.d("flutter", "saving: " + saveState);
        }
    }

    public void setChannel(BasicMessageChannel<StateMessage> channel) {
        channel.setMessageHandler(this);
    }

    @Override
    public void onMessage(StateMessage message, BasicMessageChannel.Reply<StateMessage> reply) {
        Log.d("flutter", "onMessage");
        if (message.type == StateMessage.TYPE_GET) {
            if (restoreState != null) {
                message.data = restoreState.getByteArray(message.key);
            } else {
                //TODO: wait for onCreate?
            }
            reply.reply(message);
        } else {
            if (saveState == null) {
                saveState = new Bundle();
            }
            saveState.putByteArray(message.key, message.data);
        }
    }

    private static String toString(byte[] bytes) {
        StringBuilder b = new StringBuilder();
        for (int i = 0; i < bytes.length; i++) {
            b.append(bytes[i]);
            if (i != bytes.length - 1) {
                b.append(", ");
            }
        }
        return b.toString();
    }
}
