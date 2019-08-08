package com.dayzz.sensors

import android.Manifest
import android.content.pm.PackageManager
import android.media.MediaRecorder
import android.net.Uri
import android.support.v4.content.ContextCompat
import android.util.Log
import com.facebook.react.bridge.ReactApplicationContext
import java.io.*
import java.lang.Exception
import java.lang.IllegalStateException
import java.util.*
import kotlin.concurrent.schedule

class NoiseSampler(context: ReactApplicationContext, interval: Long, period: Long):
    Sampler(context, interval, period) {

    private val LOG_TAG = "NoiseSampler"
    private val EMITTED_EVENT = "SensorsSamplerUpdate_noise"

    private val permissions: Array<String> = arrayOf(Manifest.permission.RECORD_AUDIO)
    private var timer: Timer? = null;
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

    private fun getUriFromFilePath(filePath: String): Uri {
        var uri = Uri.parse(filePath)
        if (uri.scheme == null) {
            uri = Uri.parse("file://${filePath}")
        }
        return uri
    }

    override fun startSampling(): Pair<Boolean, String> {
        if (!checkForPermissions()) {
            return Pair(false, "permissions_not_granted")
        }

        val filePath = "${context.filesDir.absolutePath}/noise-sampler.acc"
        val uri = getUriFromFilePath(filePath)
        val fd: FileDescriptor
        try {
            file = File(filePath)
            fd = context.contentResolver.openFileDescriptor(uri, "w")!!.fileDescriptor
        } catch (e: Exception) {
            return Pair(false, "could_not_create_audio_file")
        }

        MediaRecorder().apply {
            setAudioSource(MediaRecorder.AudioSource.MIC)
            setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP)
            setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB)
            setOutputFile(fd)

            try {
                prepare()
            } catch (e: IOException) {
                file?.delete()
                return Pair(false, "prepare_recording_failed")
            }

            try {
                start()
                mediaRecorder = this
                startSchedule()
                return Pair(true, "")
            } catch (e: IllegalStateException) {
                file?.delete()
                return Pair(false, "start_recording_failed")
            }
        }
    }

    override fun stopSampling() {
        release()
    }

    private fun startSchedule() {
        timestamp = System.currentTimeMillis()
        timerStarted = true
        timer = Timer("schedule", true)
        timer?.schedule(0, interval) {
            val amp = mediaRecorder?.maxAmplitude ?: 0
            var db = 0.0
            if (amp != 0) {
                db = 20.0f * Math.log10(amp * 1.0)
            }

            if (timestamp!! + period < System.currentTimeMillis()) {
                sendEvent(EMITTED_EVENT,"end", db)
                release()
            } else {
                sendEvent(EMITTED_EVENT,"update", db)
            }
        }
    }

    private fun release() {
        file?.delete()
        if (timerStarted) {
            timer?.cancel()
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