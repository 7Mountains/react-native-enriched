package com.swmansion.enriched.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.MetricAffectingSpan
import com.swmansion.enriched.spans.interfaces.EnrichedParagraphSpan
import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.styles.HtmlStyle

open class EnrichedHeadingSpan(
  private val fontSize: Float,
  private val isBold: Boolean,
) : MetricAffectingSpan(),
  EnrichedParagraphSpan {
  override val dependsOnHtmlStyle: Boolean = true
  private val typeface: Typeface? =
    if (isBold) Typeface.DEFAULT_BOLD else null

  override fun updateMeasureState(tp: TextPaint) = apply(tp)

  override fun updateDrawState(tp: TextPaint) = apply(tp)

  private fun apply(tp: TextPaint) {
    tp.textSize = fontSize
    typeface?.let { tp.typeface = it }
  }

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedSpan = EnrichedHeadingSpan(0.0f, false)

  override fun copy(): EnrichedSpan = EnrichedHeadingSpan(fontSize, isBold)
}
