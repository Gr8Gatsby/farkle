package com.feltandbone.farkle.ui

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import com.feltandbone.farkle.model.Game
import java.io.File
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/** Renders a 1080×1920 portrait "story card" for the winner and shares/saves it. Parity with iOS WinShareCard. */
object WinCard {

    private fun grouped(n: Int) = NumberFormat.getInstance(Locale.US).format(n)

    fun render(game: Game): Bitmap {
        val w = 1080
        val h = 1920
        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        val paper = Color.rgb(243, 237, 224)
        val walnut = Color.rgb(91, 58, 31)
        val ink = Color.rgb(42, 37, 32)
        val gold = Color.rgb(184, 138, 62)
        c.drawColor(paper)

        // frame
        val frame = Paint().apply { color = walnut; style = Paint.Style.STROKE; strokeWidth = 10f; isAntiAlias = true }
        c.drawRoundRect(40f, 40f, w - 40f, h - 40f, 36f, 36f, frame)

        val serif = Typeface.create(Typeface.SERIF, Typeface.ITALIC)
        val sans = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
        val mono = Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)

        val winner = game.winner
        val center = w / 2f

        // trophy halo + glyph
        val halo = Paint().apply { color = gold; alpha = 60; isAntiAlias = true }
        c.drawCircle(center, 430f, 220f, halo)
        val trophy = Paint().apply { textAlign = Paint.Align.CENTER; textSize = 230f; isAntiAlias = true }
        c.drawText("🏆", center, 510f, trophy)

        // eyebrow game name
        val eyebrow = Paint().apply {
            color = walnut; textAlign = Paint.Align.CENTER; textSize = 38f; typeface = mono; isAntiAlias = true
        }
        c.drawText(game.name.uppercase(), center, 720f, eyebrow)

        // winner name + "wins."
        val nameP = Paint().apply {
            color = walnut; textAlign = Paint.Align.CENTER; textSize = 130f; typeface = serif; isAntiAlias = true
        }
        val first = (winner?.name ?: "Winner").trim().split(" ").firstOrNull().orEmpty()
        c.drawText(first, center, 880f, nameP)
        val winsP = Paint().apply {
            color = ink; textAlign = Paint.Align.CENTER; textSize = 80f
            typeface = Typeface.create(Typeface.SERIF, Typeface.NORMAL); isAntiAlias = true
        }
        c.drawText("wins.", center, 980f, winsP)

        // big score
        val scoreP = Paint().apply {
            color = ink; textAlign = Paint.Align.CENTER; textSize = 150f; typeface = mono; isAntiAlias = true
        }
        c.drawText(grouped(winner?.bankedScore ?: 0), center, 1180f, scoreP)

        // standings
        val rowP = Paint().apply { color = ink; textSize = 46f; typeface = sans; isAntiAlias = true }
        val rowR = Paint().apply { color = ink; textSize = 46f; typeface = mono; textAlign = Paint.Align.RIGHT; isAntiAlias = true }
        var y = 1360f
        game.orderedPlayers.sortedByDescending { it.bankedScore }.forEachIndexed { idx, p ->
            c.drawText("${idx + 1}.  ${p.name}", 120f, y, rowP)
            c.drawText(grouped(p.bankedScore), w - 120f, y, rowR)
            y += 80f
        }

        // footer
        val footer = Paint().apply {
            color = walnut; textAlign = Paint.Align.CENTER; textSize = 34f; typeface = mono; isAntiAlias = true
        }
        val date = game.endedAt?.let { SimpleDateFormat("MMM d, yyyy", Locale.US).format(Date(it)) } ?: ""
        c.drawText("FARKLE · $date", center, h - 90f, footer)
        return bmp
    }

    private fun cacheUri(context: Context, bmp: Bitmap): Uri {
        val dir = File(context.cacheDir, "shares").apply { mkdirs() }
        val file = File(dir, "farkle-win.png")
        file.outputStream().use { bmp.compress(Bitmap.CompressFormat.PNG, 100, it) }
        return FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
    }

    fun share(context: Context, game: Game) {
        val uri = cacheUri(context, render(game))
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            putExtra(Intent.EXTRA_STREAM, uri)
            val first = game.winner?.name?.trim()?.split(" ")?.firstOrNull().orEmpty()
            putExtra(Intent.EXTRA_TEXT, "$first wins at Farkle! 🎲")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        context.startActivity(Intent.createChooser(intent, "Share the win").addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }

    /** Saves the card to the device gallery (Pictures/Farkle). Returns true on success. */
    fun save(context: Context, game: Game): Boolean = runCatching {
        val bmp = render(game)
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, "farkle-win-${System.currentTimeMillis()}.png")
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Images.Media.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/Farkle")
            }
        }
        val resolver = context.contentResolver
        val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
            ?: return false
        resolver.openOutputStream(uri)?.use { bmp.compress(Bitmap.CompressFormat.PNG, 100, it) }
        true
    }.getOrDefault(false)
}
