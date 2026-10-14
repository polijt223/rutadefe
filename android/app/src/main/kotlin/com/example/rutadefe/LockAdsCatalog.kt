package com.example.rutadefe

import android.content.Context
import org.json.JSONObject
import java.io.File

data class LockAdItem(val id: String, val texto: String, val imagePath: String)

object LockAdsCatalog {
    fun load(context: Context): List<LockAdItem> {
        val path = LockAdsPrefs.catalogPath(context) ?: return emptyList()
        val file = File(path)
        if (!file.exists()) return emptyList()
        val root = JSONObject(file.readText())
        val items = root.optJSONArray("items") ?: return emptyList()
        val result = ArrayList<LockAdItem>(items.length())
        for (i in 0 until items.length()) {
            val item = items.getJSONObject(i)
            val imagePath = item.optString("imagePath")
            if (imagePath.isBlank() || !File(imagePath).exists()) continue
            result.add(
                LockAdItem(
                    id = item.optString("id"),
                    texto = item.optString("texto"),
                    imagePath = imagePath,
                ),
            )
        }
        return result
    }
}
