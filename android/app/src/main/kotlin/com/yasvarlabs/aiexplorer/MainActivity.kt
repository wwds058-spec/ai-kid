package com.yasvarlabs.aiexplorer

import android.os.SystemClock
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Monotonic time since boot (includes deep sleep). Unlike the wall
        // clock it cannot be changed by the user, so the parent-PIN lockout
        // can't be bypassed by setting the device clock forward.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ai_explorer/clock")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "elapsedRealtime" -> result.success(SystemClock.elapsedRealtime())
                    else -> result.notImplemented()
                }
            }
    }
}
