package com.swmansion.enriched.spans

import android.text.TextPaint
import android.text.style.MetricAffectingSpan
import com.swmansion.enriched.spans.interfaces.EnrichedInlineSpan
import com.swmansion.enriched.styles.HtmlStyle

class EnrichedBoldSpan :
  MetricAffectingSpan(),
  EnrichedInlineSpan {
  override val dependsOnHtmlStyle: Boolean = false

  override fun updateDrawState(textPaint: TextPaint) {
    textPaint.isFakeBoldText = true
  }

  override fun updateMeasureState(textPaint: TextPaint) {
    textPaint.isFakeBoldText = true
  }

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedBoldSpan = EnrichedBoldSpan()

  override fun copy(): EnrichedBoldSpan = EnrichedBoldSpan()
}
