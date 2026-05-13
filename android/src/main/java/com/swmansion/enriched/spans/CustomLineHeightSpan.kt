package com.swmansion.enriched.spans

import android.graphics.Paint
import android.text.style.LineHeightSpan
import kotlin.math.ceil
import kotlin.math.floor

internal class CustomLineHeightSpan(
  height: Int,
) : LineHeightSpan {
  private val minimumLineHeight: Int = ceil(height.toDouble()).toInt()

  override fun chooseHeight(
    text: CharSequence,
    start: Int,
    end: Int,
    spanstartv: Int,
    v: Int,
    fm: Paint.FontMetricsInt,
  ) {
    val naturalHeight = -fm.ascent + fm.descent
    val targetHeight = maxOf(minimumLineHeight, naturalHeight)

    val leading = targetHeight - naturalHeight

    fm.ascent -= ceil(leading / 2.0f).toInt()
    fm.descent += floor(leading / 2.0f).toInt()

    if (start == 0) {
      fm.top = fm.ascent
    }

    if (end == text.length) {
      fm.bottom = fm.descent
    }
  }
}
