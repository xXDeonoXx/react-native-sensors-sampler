package com.dayzz.sensors;


import android.util.Log;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;

import kotlin.Pair;

public class SensorsSamplerModule extends ReactContextBaseJavaModule {

    private final String LOG_TAG = "SensorsSampler";

    // constants
    private final String INTERVAL_KEY = "interval";
    private final String PERIOD_KEY = "period";


    private final ReactApplicationContext reactContext;
    private NoiseSampler noiseSampler;
    private SensorSampler sensorSampler;

    private int interval = 100; // update interval, default 100 millis
    private int period = 10000; // subscription period, default 10000 millis

    public SensorsSamplerModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
    }

    @Override
    public String getName() {
        return "SensorsSampler";
    }

    @ReactMethod
    public void settings(ReadableMap settings) {
        if (settings.hasKey(INTERVAL_KEY)) {
            interval = settings.getInt(INTERVAL_KEY);
        }
        if (settings.hasKey(PERIOD_KEY)) {
            period = settings.getInt(PERIOD_KEY);
        }
    }

    @ReactMethod
    public void subscribeToEvent(String event, Promise promise) {
        Pair pair;
				switch (event) {
						case "noise":
								if (noiseSampler == null) {
										noiseSampler = new NoiseSampler(reactContext, interval, period);
								}
								pair = noiseSampler.startSampling();
								if ((Boolean) pair.getFirst()) {
										promise.resolve(null);
								} else {
										WritableMap map = Arguments.createMap();
										map.putString("code", pair.getSecond().toString());
										promise.reject("NoiseSamplerError", map);
								}
								break;
						case "light":
								if (sensorSampler == null) {
										sensorSampler = new SensorSampler(reactContext, interval, period, event);
								} else {
										sensorSampler.setEvent(event);
								}
								pair = sensorSampler.startSampling();
								if ((Boolean) pair.getFirst()) {
										promise.resolve(null);
								} else {
										WritableMap map = Arguments.createMap();
										map.putString("code", pair.getSecond().toString());
										map.putString("msg", "sensor is null");
										promise.reject("NoiseSamplerError", map);
								}
								break;
						default:
								promise.reject("SensorsSamplerError", "undefined_event");
				}
    }

    @ReactMethod
    public void unsubscribeFromEvent(String event) {
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
