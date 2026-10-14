package com.example.rutadefe

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createPushChannel()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        LockAdsPlugin.register(this, flutterEngine)
    }

    private fun createPushChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            "ruta_de_fe",
            "Ruta de Fe",
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "Reflexiones y avisos del camino"
        }
        manager.createNotificationChannel(channel)
    }
}
