package com.feltandbone.farkle.ui.components

import android.graphics.BitmapFactory
import android.util.Base64
import androidx.compose.foundation.Image
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.background
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.material3.Text
import com.feltandbone.farkle.model.Player
import com.feltandbone.farkle.ui.theme.AvatarPalette
import com.feltandbone.farkle.ui.theme.Gold
import com.feltandbone.farkle.ui.theme.PlexSans

@Composable
fun Avatar(
    player: Player,
    size: Dp = 44.dp,
    highlighted: Boolean = false,
    modifier: Modifier = Modifier,
) {
    val (bg, fg) = AvatarPalette.colors(player.avatarIndex)
    val initial = player.name.trim().firstOrNull()?.uppercaseChar()?.toString() ?: "?"
    val bitmap = remember(player.photoBase64) {
        player.photoBase64?.let { b64 ->
            runCatching {
                val bytes = Base64.decode(b64, Base64.DEFAULT)
                BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            }.getOrNull()
        }
    }
    val ring = if (highlighted) Modifier.border(2.5.dp, Gold, CircleShape) else Modifier
    Box(
        modifier = modifier
            .size(size)
            .then(ring)
            .clip(CircleShape)
            .background(bg),
        contentAlignment = Alignment.Center,
    ) {
        if (bitmap != null) {
            Image(
                bitmap = bitmap.asImageBitmap(),
                contentDescription = player.name,
                contentScale = ContentScale.Crop,
                modifier = Modifier.size(size).clip(CircleShape),
            )
        } else {
            Text(
                text = initial,
                color = fg,
                fontFamily = PlexSans,
                fontWeight = FontWeight.SemiBold,
                textAlign = TextAlign.Center,
                fontSize = (size.value * 0.42f).sp,
            )
        }
    }
}
