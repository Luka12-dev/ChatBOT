// android/app/src/main/kotlin/com/yourpackage/localai/RamHelper.kt
package com.yourpackage.localai

import android.app.ActivityManager
import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object RamHelper {
    private const val CHANNEL = "local_ai_chatbot/ram"
    fun registerWith(flutterEngine: FlutterEngine, context: Context) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getTotalRam") {
                try {
                    val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                    val mi = ActivityManager.MemoryInfo()
                    am.getMemoryInfo(mi)
                    val total = mi.totalMem // bytes (long)
                    result.success(total)
                } catch (e: Exception) {
                    result.error("RAM_ERROR", e.localizedMessage, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}