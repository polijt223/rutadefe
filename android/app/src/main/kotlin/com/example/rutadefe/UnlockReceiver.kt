package com.example.rutadefe

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import kotlin.concurrent.thread

class UnlockReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (!LockAdsPrefs.enabled(context)) return
        val action = intent.action ?: return
        if (action == Intent.ACTION_BOOT_COMPLETED) {
            LockAdsUnlockService.start(context)
        }
        val advance = action == Intent.ACTION_USER_PRESENT
        if (action != Intent.ACTION_USER_PRESENT && action != Intent.ACTION_BOOT_COMPLETED) return
        val pending = goAsync()
        thread {
            try {
                LockWallpaperApplier.apply(context, advance)
            } finally {
                pending.finish()
            }
        }
    }
}
