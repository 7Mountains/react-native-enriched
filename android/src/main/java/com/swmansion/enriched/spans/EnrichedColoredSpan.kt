package com.swmansion.enriched.spans

import android.graphics.Color
import android.text.TextPaint
import android.text.style.ForegroundColorSpan
import com.swmansion.enriched.spans.interfaces.EnrichedInlineSpan
import com.swmansion.enriched.styles.HtmlStyle

class EnrichedColoredSpan(
  val color: Int,
) : ForegroundColorSpan(color),
  EnrichedInlineSpan {
  override val dependsOnHtmlStyle: Boolean = false

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedColoredSpan = EnrichedColoredSpan(color)

  override fun updateDrawState(tp: TextPaint) {
    tp.color =
      Color.argb(
        tp.alpha,
        Color.red(foregroundColor),
        Color.green(foregroundColor),
        Color.blue(foregroundColor),
      )
  }

  fun getHexColor(): String {
    val rgb = foregroundColor and 0x00FFFFFF
    return String.format("#%06X", rgb).lowercase()
  }

  override fun copy(): EnrichedColoredSpan = EnrichedColoredSpan(color)
}
