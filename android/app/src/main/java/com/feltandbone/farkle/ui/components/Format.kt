package com.feltandbone.farkle.ui.components

import java.text.NumberFormat
import java.util.Locale
import java.util.concurrent.TimeUnit

private val grouping = NumberFormat.getInstance(Locale.US)

/** 4700 -> "4,700" — parity with iOS tabular score formatting. */
fun Int.grouped(): String = grouping.format(this)

fun firstName(name: String): String = name.trim().split(" ").firstOrNull().orEmpty()

/** Compact "time ago" used by the Recent Actions log. */
fun timeAgo(epochMillis: Long, now: Long = System.currentTimeMillis()): String {
    val diff = (now - epochMillis).coerceAtLeast(0)
    val sec = TimeUnit.MILLISECONDS.toSeconds(diff)
    val min = TimeUnit.MILLISECONDS.toMinutes(diff)
    val hr = TimeUnit.MILLISECONDS.toHours(diff)
    return when {
        sec < 10 -> "just now"
        sec < 60 -> "${sec}s ago"
        min < 60 -> "${min}m ago"
        hr < 24 -> "${hr}h ago"
        else -> "${TimeUnit.MILLISECONDS.toDays(diff)}d ago"
    }
}

/** Duration between two timestamps, e.g. "37m" or "1h 12m". */
fun durationLabel(startMillis: Long, endMillis: Long): String {
    val diff = (endMillis - startMillis).coerceAtLeast(0)
    val totalMin = TimeUnit.MILLISECONDS.toMinutes(diff)
    val h = totalMin / 60
    val m = totalMin % 60
    return if (h > 0) "${h}h ${m}m" else "${m}m"
}
