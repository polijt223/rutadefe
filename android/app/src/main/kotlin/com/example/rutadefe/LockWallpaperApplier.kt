package com.example.rutadefe

import android.app.WallpaperManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Shader
import android.os.Build
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import kotlin.math.max

object LockWallpaperApplier {
    fun apply(context: Context, advance: Boolean) {
        if (!LockAdsPrefs.enabled(context) || Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return
        val items = LockAdsCatalog.load(context)
        if (items.isEmpty()) return
        var index = LockAdsPrefs.index(context).coerceIn(0, items.lastIndex)
        if (advance) {
            index = (index + 1) % items.size
            LockAdsPrefs.setIndex(context, index)
        } else if (index > items.lastIndex) {
            index = 0
            LockAdsPrefs.setIndex(context, 0)
        }
        val item = items[index]
        val bitmap = compose(item.imagePath, item.texto)
        try {
            WallpaperManager.getInstance(context).setBitmap(
                bitmap,
                null,
                true,
                WallpaperManager.FLAG_LOCK,
            )
        } finally {
            bitmap.recycle()
        }
    }

    private fun compose(imagePath: String, text: String): Bitmap {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(imagePath, bounds)
        val sample = max(1, bounds.outWidth / 1080)
        val source = BitmapFactory.decodeFile(
            imagePath,
            BitmapFactory.Options().apply { inSampleSize = sample },
        ) ?: Bitmap.createBitmap(1080, 1920, Bitmap.Config.ARGB_8888)
        val width = 1080
        val height = 1920
        val output = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val scale = max(width / source.width.toFloat(), height / source.height.toFloat())
        val matrix = Matrix().apply {
            setScale(scale, scale)
            postTranslate(
                (width - source.width * scale) / 2f,
                (height - source.height * scale) / 2f,
            )
        }
        canvas.drawBitmap(source, matrix, null)
        if (source != output) source.recycle()

        val gradientPaint = Paint().apply {
            shader = LinearGradient(
                0f,
                height * 0.52f,
                0f,
                height.toFloat(),
                0x00000000,
                0xD9000000.toInt(),
                Shader.TileMode.CLAMP,
            )
        }
        canvas.drawRect(0f, height * 0.52f, width.toFloat(), height.toFloat(), gradientPaint)

        val textPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = 0xFFF6F1E6.toInt()
            textSize = 44f
        }
        val layout = StaticLayout.Builder
            .obtain(text, 0, text.length, textPaint, width - 120)
            .setAlignment(Layout.Alignment.ALIGN_CENTER)
            .setMaxLines(6)
            .build()
        canvas.save()
        canvas.translate(60f, (height - layout.height - 140).toFloat())
        layout.draw(canvas)
        canvas.restore()
        return output
    }
}
