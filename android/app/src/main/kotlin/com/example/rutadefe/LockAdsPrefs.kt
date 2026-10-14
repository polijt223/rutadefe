package com.example.rutadefe

import android.content.Context

object LockAdsPrefs {
    private const val PREFS = "lock_ads"

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun enabled(context: Context) = prefs(context).getBoolean("enabled", false)

    fun setEnabled(context: Context, enabled: Boolean) {
        prefs(context).edit().putBoolean("enabled", enabled).apply()
    }

    fun catalogPath(context: Context): String? = prefs(context).getString("catalog_path", null)

    fun setCatalogPath(context: Context, path: String?) {
        prefs(context).edit().putString("catalog_path", path).apply()
    }

    fun index(context: Context) = prefs(context).getInt("index", 0)

    fun setIndex(context: Context, index: Int) {
        prefs(context).edit().putInt("index", index).apply()
    }
}
