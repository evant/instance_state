package me.tatarka.flutter.instancestate.instancestate;

import android.app.Activity;
import android.os.Debug;

import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.MessageCodec;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugin.common.StringCodec;

/**
 * InstanceStatePlugin
 */
public class InstanceStatePlugin {

    private static final String TAG = "flutterState";

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        Activity activity = registrar.activity();
        InstanceStateFragment fragment = (InstanceStateFragment) activity.getFragmentManager().findFragmentByTag(TAG);
        if (fragment == null) {
            fragment = new InstanceStateFragment();
            activity.getFragmentManager().beginTransaction()
                    .add(fragment, TAG)
                    .commitNow();
        }
        final BasicMessageChannel<StateMessage> channel = new BasicMessageChannel<>(registrar.messenger(), "instance_state", StateMessageCodec.INSTANCE);
        fragment.setChannel(channel);
    }
}
