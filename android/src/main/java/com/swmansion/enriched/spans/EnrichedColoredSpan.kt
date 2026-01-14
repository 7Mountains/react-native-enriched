package com.swmansion.enriched.spans

import android.text.style.ForegroundColorSpan
import com.swmansion.enriched.spans.interfaces.EnrichedInlineSpan
import com.swmansion.enriched.styles.HtmlStyle

class EnrichedColoredSpan(
  val color: Int,
) : ForegroundColorSpan(color),
  EnrichedInlineSpan {
  override val dependsOnHtmlStyle: Boolean = false

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedColoredSpan = EnrichedColoredSpan(color)

  fun getHexColor(): String {
    val rgb = foregroundColor and 0x00FFFFFF
    return String.format("#%06X", rgb)
  }

  override fun copy(): EnrichedColoredSpan = EnrichedColoredSpan(color)
}
