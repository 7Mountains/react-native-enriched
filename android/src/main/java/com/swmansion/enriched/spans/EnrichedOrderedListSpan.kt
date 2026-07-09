package com.swmansion.enriched.spans

import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import android.text.Layout
import android.text.Spanned
import android.text.style.LeadingMarginSpan
import com.swmansion.enriched.spans.interfaces.EnrichedListSpan
import com.swmansion.enriched.styles.HtmlStyle
import com.swmansion.enriched.utils.ParagraphUtils
import com.swmansion.enriched.utils.getParagraphBounds

class EnrichedOrderedListSpan(
  private val htmlStyle: HtmlStyle,
) : LeadingMarginSpan,
  EnrichedListSpan {
  override val dependsOnHtmlStyle: Boolean = true

  override fun getLeadingMargin(first: Boolean): Int = htmlStyle.olMarginLeft + htmlStyle.olGapWidth

  override fun drawLeadingMargin(
    canvas: Canvas,
    paint: Paint,
    x: Int,
    dir: Int,
    top: Int,
    baseline: Int,
    bottom: Int,
    chars: CharSequence?,
    start: Int,
    end: Int,
    first: Boolean,
    layout: Layout?,
  ) {
    if (first) {
      val text = "${resolveIndex(chars, start)}."
      val width = paint.measureText(text)

      val yPosition = baseline.toFloat()
      val xPosition = (htmlStyle.olMarginLeft + x - width / 2) * dir

      val originalColor = paint.color
      val originalTypeface = paint.typeface

      paint.color = htmlStyle.olMarkerColor ?: originalColor
      paint.typeface = getTypeface(htmlStyle.olMarkerFontWeight, originalTypeface)
      canvas.drawText(text, xPosition, yPosition, paint)

      paint.color = originalColor
      paint.typeface = originalTypeface
    }
  }

  private fun resolveIndex(
    text: CharSequence?,
    lineStart: Int,
  ): Int {
    val spanned = text as? Spanned ?: return 1
    val (paragraphStart, paragraphEnd) = spanned.getParagraphBounds(lineStart)
    val alignment = ParagraphUtils.findParagraphAlignment(spanned, paragraphStart, paragraphEnd)

    if (ParagraphUtils.findOrderedListSpan(spanned, paragraphStart, paragraphEnd) == null) {
      return 1
    }

    var resolvedIndex = 1
    var previousParagraphCursor = paragraphStart - 1

    while (previousParagraphCursor >= 0) {
      val (previousParagraphStart, previousParagraphEnd) =
        spanned.getParagraphBounds(previousParagraphCursor)

      val previousOrderedListSpan =
        ParagraphUtils.findOrderedListSpan(
          spanned,
          previousParagraphStart,
          previousParagraphEnd,
        )

      if (previousOrderedListSpan == null) {
        break
      }

      val previousAlignment =
        ParagraphUtils.findParagraphAlignment(
          spanned,
          previousParagraphStart,
          previousParagraphEnd,
        )

      if (previousAlignment != alignment) {
        break
      }

      resolvedIndex++
      previousParagraphCursor = previousParagraphStart - 1
    }

    return resolvedIndex
  }

  private fun getTypeface(
    fontWeight: Int?,
    originalTypeface: Typeface,
  ): Typeface =
    if (fontWeight == null) {
      originalTypeface
    } else if (android.os.Build.VERSION.SDK_INT >= 28) {
      Typeface.create(originalTypeface, fontWeight, false)
    } else {
      // Fallback for API < 28: only bold/normal supported
      if (fontWeight == Typeface.BOLD) {
        Typeface.create(originalTypeface, Typeface.BOLD)
      } else {
        Typeface.create(originalTypeface, Typeface.NORMAL)
      }
    }

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedOrderedListSpan = EnrichedOrderedListSpan(htmlStyle)

  override fun copy(): EnrichedOrderedListSpan = EnrichedOrderedListSpan(htmlStyle = htmlStyle)
}
