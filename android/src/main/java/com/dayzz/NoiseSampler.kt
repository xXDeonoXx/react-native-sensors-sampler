package com.dayzz

import android.Manifest
import android.content.pm.PackageManager
import android.media.MediaRecorder
import android.os.Environment
import android.support.v4.content.ContextCompat
import android.util.Log
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.modules.core.DeviceEventManagerModule
import java.io.File
import java.io.FileInputStream
import java.io.FileNotFoundException
import java.io.IOException
import java.lang.IllegalStateException
import java.util.*
import kotlin.concurrent.schedule

class NoiseSampler(val context: ReactApplicationContext, val interval: Long, val period: Long) {

    private val LOG_TAG = "NoiseSampler"
    private val EMITTED_EVENT = "SensorsSamplerUpdate_noise"

    private val permissions: Array<String> = arrayOf(Manifest.permission.RECORD_AUDIO)
    private val timer = Timer("schedule", true)
    private var mediaRecorder: MediaRecorder? = null
    private var timestamp: Long? = null
    private var file: File? = null
    private var timerStarted = false

    private fun checkForPermissions(): Boolean {
        var hasPermissions = true
        permissions.forEach {
            if (ContextCompat.checkSelfPermission(context, it) != PackageManager.PERMISSION_GRANTED) {
                hasPermissions = false;
            }
        }
        return hasPermissions
    }

    fun startSampling(): Pair<Boolean, String> {
        if (!checkForPermissions()) {
            return Pair(false, "permissions not granted")
        }

        try {
            file = File(context.externalMediaDirs[0], "noise-sampler.acc")
            file?.createNewFile()
        } catch (e: FileNotFoundException) {
            return Pair(false, "could not create audio file")
        }

        mediaRecorder = MediaRecorder().apply {
            setAudioSource(MediaRecorder.AudioSource.MIC)
            setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP)
            setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB)
            setOutputFile(FileInputStream(file).fd)

            try {
                prepare()
            } catch (e: IOException) {
                file?.delete()
                return Pair(false, "prepare recording failed")
            }

            try {
                start()
                startSchedule()
                return Pair(true, "")
            } catch (e: IllegalStateException) {
                file?.delete()
                return Pair(false, "start recording failed")
            }
        }
    }

    fun stopSampling() {
        release()
    }

    private fun startSchedule() {
        timestamp = System.currentTimeMillis()
        timerStarted = true
        timer.schedule(0, interval) {
            val amp = mediaRecorder!!.maxAmplitude
            var db = 0
            if (amp != 0) {
                db = (20.0f * Math.log10(amp * 1.0)).toInt()
            }

            if (timestamp!! + period < System.currentTimeMillis()) {
                sendEvent("end", db)
                release()
            } else {
                sendEvent("update", db)
            }
        }
    }

    private fun sendEvent(type: String, value: Int) {
        val params: WritableMap = Arguments.createMap()
        params.putString("type", type)
        params.putInt("value", value)

        context.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
                .emit(EMITTED_EVENT, params)
    }

    private fun release() {
        file?.delete()
        if (timerStarted) {
            timer.cancel()
            timerStarted = false
        }
        mediaRecorder?.apply {
            try{
                stop()
            } catch (e: IllegalStateException) {
                Log.i(LOG_TAG, "exception while stop media recorder")
            }
            release()
        }
        mediaRecorder = null
    }
}