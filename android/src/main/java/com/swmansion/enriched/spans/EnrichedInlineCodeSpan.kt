package com.swmansion.enriched.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.MetricAffectingSpan
import com.swmansion.enriched.spans.interfaces.EnrichedInlineSpan
import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.styles.HtmlStyle

class EnrichedInlineCodeSpan(
  private val htmlStyle: HtmlStyle,
) : MetricAffectingSpan(),
  EnrichedInlineSpan {
  override val dependsOnHtmlStyle: Boolean = true

  override fun updateDrawState(textPaint: TextPaint) {
    textPaint.typeface = Typeface.MONOSPACE
    textPaint.color = htmlStyle.inlineCodeColor
    textPaint.bgColor = htmlStyle.inlineCodeBackgroundColor
  }

  override fun updateMeasureState(textPaint: TextPaint) {
    textPaint.typeface = Typeface.MONOSPACE
  }

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedInlineCodeSpan = EnrichedInlineCodeSpan(htmlStyle)

  override fun copy(): EnrichedInlineCodeSpan = EnrichedInlineCodeSpan(htmlStyle)
}
