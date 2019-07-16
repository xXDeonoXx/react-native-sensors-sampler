package com.dayzz.pub

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.modules.core.DeviceEventManagerModule

abstract class Sampler(val context: ReactApplicationContext, val interval: Long, val period: Long) {

    abstract fun startSampling(): Pair<Boolean, String>
    abstract fun stopSampling()

    fun sendEvent(event: String, type: String, value: Double) {
        val params: WritableMap = Arguments.createMap()
        params.putString("type", type)
        params.putInt("value", value.toInt())

        context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
                .emit(event, params)
    }
}