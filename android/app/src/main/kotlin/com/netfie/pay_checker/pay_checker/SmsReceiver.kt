package com.netfie.pay_checker.pay_checker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.telephony.SmsMessage
import android.util.Log

class SmsReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "android.provider.Telephony.SMS_RECEIVED") {
            val bundle = intent.extras
            if (bundle != null) {
                try {
                    val pdus = bundle.get("pdus") as Array<*>?
                    if (pdus != null) {
                        for (pdu in pdus) {
                            val format = bundle.getString("format")
                            val sms = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                SmsMessage.createFromPdu(pdu as ByteArray, format)
                            } else {
                                @Suppress("DEPRECATION")
                                SmsMessage.createFromPdu(pdu as ByteArray)
                            }
                            val sender = sms.originatingAddress ?: ""
                            val body = sms.messageBody ?: ""
                            val timestamp = sms.timestampMillis

                            Log.d("PayCheckerSmsReceiver", "SMS received from $sender: $body")

                            val eventIntent = Intent("com.netfie.pay_checker.SMS_RECEIVED").apply {
                                putExtra("sender", sender)
                                putExtra("body", body)
                                putExtra("timestamp", timestamp)
                                setPackage(context.packageName)
                            }
                            context.sendBroadcast(eventIntent)
                        }
                    }
                } catch (e: Exception) {
                    Log.e("PayCheckerSmsReceiver", "Error parsing SMS: ${e.message}", e)
                }
            }
        }
    }
}
