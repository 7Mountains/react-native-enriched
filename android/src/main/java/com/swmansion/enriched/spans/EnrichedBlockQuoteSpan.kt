package com.swmansion.enriched.spans

import android.graphics.Canvas
import android.graphics.Paint
import android.text.Layout
import android.text.Spanned
import android.text.style.LeadingMarginSpan
import com.swmansion.enriched.spans.interfaces.EnrichedBlockSpan
import com.swmansion.enriched.styles.HtmlStyle

// https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/core/java/android/text/style/QuoteSpan.java
class EnrichedBlockQuoteSpan(
  private val htmlStyle: HtmlStyle,
) : LeadingMarginSpan,
  EnrichedBlockSpan {
  override val dependsOnHtmlStyle: Boolean = true

  override fun getLeadingMargin(p0: Boolean): Int = htmlStyle.blockquoteStripeWidth + htmlStyle.blockquoteGapWidth

  override fun drawLeadingMargin(
    c: Canvas,
    p: Paint,
    x: Int,
    dir: Int,
    top: Int,
    baseline: Int,
    bottom: Int,
    text: CharSequence?,
    start: Int,
    end: Int,
    first: Boolean,
    layout: Layout?,
  ) {
    if (text !is Spanned || layout == null) return

    val spanned = text
    val spanStart = spanned.getSpanStart(this)
    val spanEnd = spanned.getSpanEnd(this)

    val line = layout.getLineForOffset(start)
    val lineOfSpanStart = layout.getLineForOffset(spanStart)
    val lineOfSpanEnd = layout.getLineForOffset(spanEnd)

    val y = layout.getLineBaseline(line).toFloat()

    val oldColor = p.color
    p.color = htmlStyle.blockquoteColor ?: oldColor

    if (line == lineOfSpanStart) {
      val qx = x.toFloat()
      c.drawText("“", qx, y, p)
    }

    if (line == lineOfSpanEnd) {
      val textRight = layout.getLineRight(line)
      val qx = dir * (textRight + htmlStyle.blockquoteGapWidth)
      c.drawText("”", qx, y, p)
    }

    p.color = oldColor
  }

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedBlockQuoteSpan = EnrichedBlockQuoteSpan(htmlStyle)

  override fun copy(): EnrichedBlockQuoteSpan = EnrichedBlockQuoteSpan(htmlStyle)
}
