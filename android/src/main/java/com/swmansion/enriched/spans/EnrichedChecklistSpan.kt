package com.swmansion.enriched.spans

import android.graphics.Canvas
import android.graphics.Paint
import android.text.Layout
import android.text.Spanned
import android.text.TextPaint
import android.text.style.LeadingMarginSpan
import android.text.style.MetricAffectingSpan
import com.swmansion.enriched.spans.interfaces.EnrichedParagraphSpan
import com.swmansion.enriched.styles.HtmlStyle

class EnrichedChecklistSpan(
  private val htmlStyle: HtmlStyle,
) : MetricAffectingSpan(),
  LeadingMarginSpan,
  EnrichedParagraphSpan {
  var isChecked = false
  override val dependsOnHtmlStyle: Boolean = true

  constructor(htmlStyle: HtmlStyle, isChecked: Boolean) : this(htmlStyle = htmlStyle) {
    this.isChecked = isChecked
  }

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedChecklistSpan = EnrichedChecklistSpan(htmlStyle, isChecked)

  override fun updateMeasureState(tp: TextPaint) {}

  override fun updateDrawState(tp: TextPaint) {}

  override fun getLeadingMargin(first: Boolean): Int {
    val s = htmlStyle.checkboxStyle
    val width = if (s.imageWidth > 0) s.imageWidth else s.uncheckedImage?.intrinsicWidth?.toFloat() ?: 0f
    return (s.marginLeft + width + s.gapWidth).toInt()
  }

  override fun drawLeadingMargin(
    canvas: Canvas,
    paint: Paint,
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
    val spannedText = text as Spanned

    if (spannedText.getSpanStart(this) == start) {
      val style = htmlStyle.checkboxStyle
      val drawable =
        if (isChecked) {
          style.checkedImage
        } else {
          style.uncheckedImage
            ?: return
        }

      val boxWidth =
        if (style.imageWidth > 0) style.imageWidth else drawable?.intrinsicWidth?.toFloat() ?: 24.0f
      val boxHeight =
        if (style.imageHeight > 0) {
          style.imageHeight
        } else {
          drawable?.intrinsicHeight?.toFloat()
            ?: 24.0f
        }

      val lineHeight = bottom - top
      val centerY = top + lineHeight / 2f

      val left = x + dir * style.marginLeft
      val right = left + dir * boxWidth
      val boxLeft = minOf(left, right)
      val boxTop = centerY - boxHeight / 2f

      drawable?.setBounds(
        boxLeft.toInt(),
        boxTop.toInt(),
        (boxLeft + boxWidth).toInt(),
        (boxTop + boxHeight).toInt(),
      )

      drawable?.draw(canvas)
    }
  }

  fun toggleChecked() {
    isChecked = !isChecked
  }

  fun getAttributes(): Map<String, String> = mapOf("checked" to if (isChecked) "true" else "false")
}
