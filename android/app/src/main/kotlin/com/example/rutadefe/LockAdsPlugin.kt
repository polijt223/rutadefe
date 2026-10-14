package com.example.rutadefe

import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

class LockAdsPlugin(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "com.rutadefe/lock_ads"

        fun register(context: Context, engine: FlutterEngine) {
            MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
                .setMethodCallHandler(LockAdsPlugin(context.applicationContext))
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSupported" -> result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.N)
            "setEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") == true
                LockAdsPrefs.setEnabled(context, enabled)
                if (enabled) {
                    LockAdsUnlockService.start(context)
                } else {
                    LockAdsUnlockService.stop(context)
                }
                result.success(null)
            }
            "updateCatalog" -> {
                LockAdsPrefs.setCatalogPath(context, call.argument<String>("path"))
                if (LockAdsPrefs.enabled(context)) {
                    LockAdsUnlockService.start(context)
                }
                result.success(null)
            }
            "applyCurrent" -> apply(result, advance = false)
            "applyNext" -> apply(result, advance = true)
            else -> result.notImplemented()
        }
    }

    private fun apply(result: MethodChannel.Result, advance: Boolean) {
        thread {
            try {
                LockWallpaperApplier.apply(context, advance)
                Handler(Looper.getMainLooper()).post { result.success(null) }
            } catch (error: Exception) {
                Handler(Looper.getMainLooper()).post {
                    result.error("apply_failed", error.message, null)
                }
            }
        }
    }
}
