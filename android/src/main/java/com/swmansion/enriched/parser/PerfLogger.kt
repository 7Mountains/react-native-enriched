package com.swmansion.enriched.parser

import android.os.SystemClock
import android.util.Log

class PerfLogger(
  private val tag: String,
) {
  private val start = SystemClock.elapsedRealtime()

  fun lap(label: String) {
    val now = SystemClock.elapsedRealtime()
    Log.d(tag, "⏱ $label: ${now - start} ms")
  }

  fun end(label: String = "total") {
    val now = SystemClock.elapsedRealtime()
    Log.d(tag, "⏱ $label: ${now - start} ms")
  }
}
