package com.dayzz;


import android.util.Log;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;

import kotlin.Pair;

public class SensorsSamplerModule extends ReactContextBaseJavaModule {

    private final String LOG_TAG = "SensorsSampler";

    private final ReactApplicationContext reactContext;
    private NoiseSampler noiseSampler;
    private SensorSampler sensorSampler;

    public SensorsSamplerModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
    }

    @Override
    public String getName() {
        return "SensorsSampler";
    }

    @ReactMethod
    public void subscribe(int interval, int period, String event, Promise promise) {
        switch (event) {
            case "noise":
                if (noiseSampler == null) {
                    noiseSampler = new NoiseSampler(reactContext, interval, period);
                }
                Pair pair = noiseSampler.startSampling();
                if ((Boolean) pair.getFirst()) {
                    promise.resolve(null);
                } else {
                    promise.reject("NoiseSamplerError", pair.getSecond().toString());
                }
                break;
            case "light":
                if (sensorSampler == null) {
                    sensorSampler = new SensorSampler(reactContext, interval, period, event);
                } else {
                    sensorSampler.setEvent(event);
                }
                sensorSampler.startSampling();
                promise.resolve(null);
                break;
            default:
                promise.reject("SensorsSamplerError", "undefined event");
        }
    }

    @ReactMethod
    public void unsubscribe(String event) {
        switch (event) {
            case "noise":
                if (noiseSampler != null) {
                    noiseSampler.stopSampling();
                }
                break;
            case "light":
                if (sensorSampler != null) {
                    sensorSampler.stopSampling();
                }
                break;
            default:
                Log.i(LOG_TAG, "undefined event");
        }
    }
}
