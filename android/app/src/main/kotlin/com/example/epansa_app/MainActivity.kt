package com.example.epansa_app

import android.Manifest
import android.content.pm.PackageManager
import android.telephony.SmsManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.epansa.app/sms"
    private var smsChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        smsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        smsChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "sendSms" -> {
                    val phoneNumber = call.argument<String>("phoneNumber")
                    val message = call.argument<String>("message")
                    
                    if (phoneNumber != null && message != null) {
                        sendSms(phoneNumber, message, result)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Phone number and message are required", null)
                    }
                }
                "readSms" -> {
                    val limit = call.argument<Int>("limit") ?: 10
                    val phoneNumber = call.argument<String>("phoneNumber")
                    readSms(limit, phoneNumber, result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun sendSms(phoneNumber: String, message: String, result: MethodChannel.Result) {
        try {
            val smsManager = SmsManager.getDefault()
            
            // Split message if it's too long
            val parts = smsManager.divideMessage(message)
            
            if (parts.size == 1) {
                smsManager.sendTextMessage(phoneNumber, null, message, null, null)
            } else {
                smsManager.sendMultipartTextMessage(phoneNumber, null, parts, null, null)
            }
            
            result.success(true)
        } catch (e: Exception) {
            result.error("SMS_SEND_ERROR", "Failed to send SMS: ${e.message}", null)
        }
    }

    private fun readSms(limit: Int, phoneNumber: String?, result: MethodChannel.Result) {
        try {
            val messages = mutableListOf<Map<String, Any>>()
            val uri = android.net.Uri.parse("content://sms/inbox")
            
            var selection: String? = null
            var selectionArgs: Array<String>? = null
            
            if (phoneNumber != null) {
                selection = "address = ?"
                selectionArgs = arrayOf(phoneNumber)
            }
            
            val cursor = contentResolver.query(
                uri,
                arrayOf("_id", "address", "body", "date", "read", "type"),
                selection,
                selectionArgs,
                "date DESC"
            )
            
            cursor?.use {
                var count = 0
                while (it.moveToNext() && count < limit) {
                    val id = it.getString(it.getColumnIndexOrThrow("_id"))
                    val address = it.getString(it.getColumnIndexOrThrow("address"))
                    val body = it.getString(it.getColumnIndexOrThrow("body"))
                    val date = it.getLong(it.getColumnIndexOrThrow("date"))
                    val isRead = it.getInt(it.getColumnIndexOrThrow("read")) == 1
                    val type = it.getInt(it.getColumnIndexOrThrow("type"))
                    
                    messages.add(
                        mapOf(
                            "id" to id,
                            "address" to address,
                            "body" to body,
                            "date" to date,
                            "isRead" to isRead,
                            "type" to type
                        )
                    )
                    count++
                }
            }
            
            result.success(messages)
        } catch (e: Exception) {
            result.error("SMS_READ_ERROR", "Failed to read SMS: ${e.message}", null)
        }
    }

    override fun onDestroy() {
        smsChannel?.setMethodCallHandler(null)
        super.onDestroy()
    }
}
