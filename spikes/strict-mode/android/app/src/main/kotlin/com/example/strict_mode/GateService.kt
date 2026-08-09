package com.example.strict_mode

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.WindowManager
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterTextureView
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import java.io.File

/**
 * Q6 + Q7 in one component.
 *
 * - Foreground service (specialUse) so the process survives Doze and can be
 *   re-armed on boot.
 * - Adds a TYPE_APPLICATION_OVERLAY window to the WindowManager, hosting a real
 *   FlutterView backed by a second FlutterEngine running the `overlayMain`
 *   Dart entrypoint. So the gate on Android is genuine Flutter UI, not a native
 *   stand-in.
 */
class GateService : Service() {

    companion object {
        const val TAG = "ForceGate"
        const val CHANNEL_ID = "force_gate"
        const val ACTION_SHOW = "SHOW_OVERLAY"
        const val ACTION_HIDE = "HIDE_OVERLAY"
        const val ACTION_ARM = "ARM"

        /** Written from the service and from BootReceiver so tests can prove boot start. */
        fun log(ctx: Context, line: String) {
            try {
                val f = File(ctx.filesDir, "gate-events.log")
                f.appendText("${System.currentTimeMillis()}  ${java.util.Date()}  $line\n")
            } catch (_: Throwable) {}
            Log.i(TAG, line)
        }
    }

    private var overlayView: FlutterView? = null
    private var overlayHost: android.widget.FrameLayout? = null
    private var overlayEngine: FlutterEngine? = null
    private lateinit var wm: WindowManager

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        createChannel()
        startForeground(1, buildNotification("Gate armed"))
        log(this, "service onCreate (foreground started)")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        log(this, "onStartCommand action=${intent?.action}")
        when (intent?.action) {
            ACTION_SHOW -> showOverlay()
            ACTION_HIDE -> hideOverlay()
            else -> {}
        }
        // START_STICKY: Android restarts the service if the process is killed.
        return START_STICKY
    }

    private fun createChannel() {
        val nm = getSystemService(NotificationManager::class.java)
        val ch = NotificationChannel(CHANNEL_ID, "Force gate", NotificationManager.IMPORTANCE_LOW)
        nm.createNotificationChannel(ch)
    }

    private fun buildNotification(text: String): Notification =
        Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("Force")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setOngoing(true)
            .build()

    fun canDrawOverlays(): Boolean = Settings.canDrawOverlays(this)

    private fun showOverlay() {
        if (overlayView != null) return
        if (!Settings.canDrawOverlays(this)) {
            log(this, "showOverlay REFUSED: SYSTEM_ALERT_WINDOW not granted")
            return
        }
        Handler(Looper.getMainLooper()).post {
            val engine = FlutterEngine(this)
            engine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(
                    FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                    "overlayMain"
                )
            )
            engine.lifecycleChannel.appIsResumed()

            val view = FlutterView(this, FlutterTextureView(this))
            view.attachToFlutterEngine(engine)

            // FlutterView reports "Width is zero" and never paints if the window is
            // sized MATCH_PARENT; it needs real pixels and a plain parent to measure
            // against.
            val metrics = wm.currentWindowMetrics.bounds
            val w = metrics.width()
            val h = metrics.height()
            val host = android.widget.FrameLayout(this)
            host.addView(
                view,
                android.widget.FrameLayout.LayoutParams(
                    android.widget.FrameLayout.LayoutParams.MATCH_PARENT,
                    android.widget.FrameLayout.LayoutParams.MATCH_PARENT
                )
            )

            val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE

            val lp = WindowManager.LayoutParams(
                w, h,
                type,
                // focusable (no FLAG_NOT_FOCUSABLE) so the gate can take text input,
                // drawn edge to edge over the status/nav bars.
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                PixelFormat.OPAQUE
            )
            lp.gravity = Gravity.TOP or Gravity.START

            wm.addView(host, lp)
            overlayHost = host
            overlayView = view
            overlayEngine = engine
            log(this, "overlay ADDED type=TYPE_APPLICATION_OVERLAY ${w}x$h flutterEngine=second")
        }
    }

    private fun hideOverlay() {
        Handler(Looper.getMainLooper()).post {
            overlayHost?.let { try { wm.removeView(it) } catch (_: Throwable) {} }
            overlayView?.detachFromFlutterEngine()
            overlayEngine?.destroy()
            overlayHost = null
            overlayView = null
            overlayEngine = null
            log(this, "overlay REMOVED")
        }
    }

    override fun onDestroy() {
        hideOverlay()
        log(this, "service onDestroy")
        super.onDestroy()
    }
}
