package com.example.strict_mode

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Q7 — re-arm the gate after a reboot or an app update. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        GateService.log(context, "BootReceiver got ${intent.action}")
        val svc = Intent(context, GateService::class.java).setAction(GateService.ACTION_ARM)
        context.startForegroundService(svc)
    }
}
