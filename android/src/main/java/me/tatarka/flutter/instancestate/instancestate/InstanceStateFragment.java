package me.tatarka.flutter.instancestate.instancestate;

import android.app.Fragment;
import android.os.Bundle;

import io.flutter.plugin.common.BasicMessageChannel;

public class InstanceStateFragment extends Fragment implements BasicMessageChannel.MessageHandler<StateMessage> {

    private Bundle restoreState;
    private Bundle saveState;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (savedInstanceState != null) {
            restoreState = savedInstanceState;
        }
    }

    @Override
    public void onSaveInstanceState(Bundle outState) {
        super.onSaveInstanceState(outState);
        if (saveState != null) {
            outState.putAll(saveState);
        }
    }

    public void setChannel(BasicMessageChannel<StateMessage> channel) {
        channel.setMessageHandler(this);
    }

    @Override
    public void onMessage(StateMessage message, BasicMessageChannel.Reply<StateMessage> reply) {
        if (message.type == StateMessage.TYPE_GET) {
            if (restoreState != null) {
                byte[] data = restoreState.getByteArray(message.key);
                restoreState.remove(message.key);
                message.data = data;
            }
            reply.reply(message);
        } else {
            if (saveState == null) {
                saveState = new Bundle();
            }
            saveState.putByteArray(message.key, message.data);
        }
    }
}
