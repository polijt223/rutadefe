package com.example.rutadefe

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.IBinder

class LockAdsUnlockService : Service() {
    private val receiver = UnlockReceiver()
    private var registered = false

    override fun onCreate() {
        super.onCreate()
        createChannel()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                startForeground(NOTIFICATION_ID, buildNotification())
            } catch (_: Exception) {
                // Notifications may be blocked; keep the receiver anyway.
            }
        }
        registerReceiver(receiver, IntentFilter(Intent.ACTION_USER_PRESENT))
        registered = true
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!LockAdsPrefs.enabled(this)) {
            stopSelf()
            return START_NOT_STICKY
        }
        return START_STICKY
    }

    override fun onDestroy() {
        if (registered) {
            unregisterReceiver(receiver)
            registered = false
        }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Pantalla de bloqueo",
            NotificationManager.IMPORTANCE_MIN,
        ).apply {
            description = "Mantiene las reflexiones de bloqueo listas al desbloquear"
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        return builder
            .setContentTitle("Ruta de Fe")
            .setContentText("Reflexiones de pantalla de bloqueo activas")
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setOngoing(true)
            .build()
    }

    companion object {
        private const val CHANNEL_ID = "lock_ads"
        private const val NOTIFICATION_ID = 42

        fun start(context: android.content.Context) {
            val intent = Intent(context, LockAdsUnlockService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: android.content.Context) {
            context.stopService(Intent(context, LockAdsUnlockService::class.java))
        }
    }
}
