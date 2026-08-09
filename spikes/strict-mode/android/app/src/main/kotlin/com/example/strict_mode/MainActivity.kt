package com.example.strict_mode

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "force/strict")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "info" -> result.success(
                        mapOf(
                            "sdk" to android.os.Build.VERSION.SDK_INT,
                            "canDrawOverlays" to Settings.canDrawOverlays(this),
                            "serviceRunning" to isServiceRunning(),
                            "logPath" to File(filesDir, "gate-events.log").absolutePath,
                            "launchedByBoot" to intent.getBooleanExtra("fromBoot", false)
                        )
                    )

                    // Q6 — deep-link into the system grant screen. There is no way to
                    // grant SYSTEM_ALERT_WINDOW from inside the app.
                    "requestOverlayPermission" -> {
                        startActivity(
                            Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            )
                        )
                        result.success(Settings.canDrawOverlays(this))
                    }

                    "startService" -> {
                        startForegroundService(
                            Intent(this, GateService::class.java).setAction(GateService.ACTION_ARM)
                        )
                        result.success(true)
                    }

                    "stopService" -> {
                        stopService(Intent(this, GateService::class.java))
                        result.success(true)
                    }

                    "showOverlay" -> {
                        startForegroundService(
                            Intent(this, GateService::class.java).setAction(GateService.ACTION_SHOW)
                        )
                        result.success(Settings.canDrawOverlays(this))
                    }

                    "hideOverlay" -> {
                        startForegroundService(
                            Intent(this, GateService::class.java).setAction(GateService.ACTION_HIDE)
                        )
                        result.success(true)
                    }

                    "readLog" -> result.success(
                        runCatching { File(filesDir, "gate-events.log").readText() }
                            .getOrElse { "<no log> $it" }
                    )

                    // Q6b — can the app pull ITSELF to the foreground from the background,
                    // the way macOS can? This is the Android equivalent of raiseToFront.
                    "raiseToFront" -> {
                        val i = Intent(this, MainActivity::class.java)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                        startActivity(i)
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    private fun isServiceRunning(): Boolean {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        return am.getRunningServices(Int.MAX_VALUE)
            .any { it.service.className == GateService::class.java.name }
    }
}
