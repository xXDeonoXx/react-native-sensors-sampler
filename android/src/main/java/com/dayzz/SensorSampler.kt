package com.dayzz

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.util.Log
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.modules.core.DeviceEventManagerModule
import java.util.*
import kotlin.concurrent.schedule

class SensorSampler(val context: ReactApplicationContext, val interval: Long, val period: Long, var event: String): SensorEventListener {

    private val LOG_TAG = "SensorSampler"
    private val EMITTED_EVENT = "SensorsSamplerUpdate"

    private lateinit var sensorManager: SensorManager
    private var light: Sensor? = null
    private var lastValue: Float = 0F

    private val timer = Timer("schedule", true)
    private var timestamp: Long? = null
    private var timerStarted = false

    override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {
        // Do something here if sensor accuracy changes.
        // accuracy: SensorManager.SENSOR_STATUS_*
        // SensorManager.SENSOR_STATUS_ACCURACY_HIGH, ...
        Log.i(LOG_TAG, "onAccuracyChanged ${accuracy}")
        if (accuracy >= SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM && !timerStarted) {
            startSchedule()
        }
    }

    override fun onSensorChanged(event: SensorEvent) {
        lastValue = event.values[0]
        // Do something with this sensor data.
        Log.i(LOG_TAG, "onSensorChanged ${lastValue}")
    }

    fun startSampling() {
        // Get an instance of the sensor service, and use that to get an instance of
        // a particular sensor.
        sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        light = sensorManager.getDefaultSensor(Sensor.TYPE_LIGHT)
        sensorManager.registerListener(this, light, SensorManager.SENSOR_DELAY_NORMAL)
    }

    fun stopSampling() {
        release()
    }

    private fun startSchedule() {
        timestamp = System.currentTimeMillis()
        timerStarted = true
        timer.schedule(0, interval) {
            if (timestamp!! + period < System.currentTimeMillis()) {
                sendEvent("end", lastValue.toDouble())
                release()
            } else {
                sendEvent("update", lastValue.toDouble())
            }
        }
    }

    private fun sendEvent(type: String, value: Double) {
        val params: WritableMap = Arguments.createMap()
        params.putString("type", type)
        params.putDouble("value", value)

        context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
                .emit("${EMITTED_EVENT}_${event}", params)
    }

    private fun release() {
        sensorManager.unregisterListener(this)
        if (timerStarted) {
            timer.cancel()
            timerStarted = false
        }
    }
}