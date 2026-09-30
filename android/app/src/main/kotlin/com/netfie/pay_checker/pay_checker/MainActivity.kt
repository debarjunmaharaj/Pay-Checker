package com.netfie.pay_checker.pay_checker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val METHOD_CHANNEL = "com.netfie.pay_checker/native_methods"
    private val EVENT_CHANNEL = "com.netfie.pay_checker/sms_events"
    private var eventSink: EventChannel.EventSink? = null
    private var smsBroadcastReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isIgnoringBatteryOptimizations" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    } else {
                        result.success(true)
                    }
                }
                "requestIgnoreBatteryOptimizations" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        try {
                            val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            try {
                                val fallbackIntent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                    data = android.net.Uri.parse("package:$packageName")
                                }
                                startActivity(fallbackIntent)
                                result.success(true)
                            } catch (fallbackEx: Exception) {
                                result.error("BATTERY_OPT_ERROR", fallbackEx.message, null)
                            }
                        }
                    } else {
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    registerSmsInternalReceiver()
                }

                override fun onCancel(arguments: Any?) {
                    unregisterSmsInternalReceiver()
                    eventSink = null
                }
            }
        )
    }

    private fun registerSmsInternalReceiver() {
        if (smsBroadcastReceiver == null) {
            smsBroadcastReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    if (intent?.action == "com.netfie.pay_checker.SMS_RECEIVED") {
                        val sender = intent.getStringExtra("sender") ?: ""
                        val body = intent.getStringExtra("body") ?: ""
                        val timestamp = intent.getLongExtra("timestamp", System.currentTimeMillis())

                        val dataMap = mapOf(
                            "sender" to sender,
                            "body" to body,
                            "timestamp" to timestamp
                        )
                        eventSink?.success(dataMap)
                    }
                }
            }
            val filter = IntentFilter("com.netfie.pay_checker.SMS_RECEIVED")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(smsBroadcastReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                registerReceiver(smsBroadcastReceiver, filter)
            }
        }
    }

    private fun unregisterSmsInternalReceiver() {
        smsBroadcastReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (e: Exception) {
                // Ignore if not registered
            }
            smsBroadcastReceiver = null
        }
    }
}
