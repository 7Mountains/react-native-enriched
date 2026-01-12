package com.swmansion.enriched

import android.text.Layout
import android.text.Spannable
import com.swmansion.enriched.spans.EnrichedChecklistSpan

class CheckListClickHandler(
  private val view: EnrichedTextInputView,
) {
  fun handleChecklistClick(
    text: Spannable,
    offset: Int,
    clickX: Float,
    clickY: Float,
    layout: Layout,
  ): Boolean {
    val spans = text.getSpans(offset, offset, EnrichedChecklistSpan::class.java)
    if (spans.isEmpty()) return false

    val span = spans.first()
    val line = layout.getLineForOffset(offset)

    if (isInsideCheckbox(span, layout, line, clickX, clickY)) {
      span.toggleChecked()
      view.redrawSpan(span)
      return true
    }

    return false
  }

  fun isInsideCheckbox(
    span: EnrichedChecklistSpan,
    layout: Layout,
    line: Int,
    clickX: Float,
    clickY: Float,
  ): Boolean {
    val style = view.htmlStyle.checkboxStyle
    val drawable = if (span.isChecked) style.checkedImage else style.uncheckedImage
    if (drawable == null) return false

    val dir = layout.getParagraphDirection(line) // 1 или -1

    // leading margin position
    val x = layout.getLineLeft(line)

    val marginLeft = style.marginLeft

    val boxWidth = if (style.imageWidth > 0) style.imageWidth else drawable.intrinsicWidth.toFloat()
    val boxHeight = if (style.imageHeight > 0) style.imageHeight else drawable.intrinsicHeight.toFloat()

    // final drawable position
    val rawLeft = x + dir * marginLeft
    val boxLeft = minOf(rawLeft, rawLeft + boxWidth)
    val boxRight = maxOf(rawLeft, rawLeft + boxWidth)

    val top = layout.getLineTop(line).toFloat()
    val bottom = layout.getLineBottom(line).toFloat()
    val centerY = (top + bottom) / 2f

    val boxTop = centerY - boxHeight / 2
    val boxBottom = centerY + boxHeight / 2

    return (clickX in boxLeft..boxRight && clickY in boxTop..boxBottom)
  }
}
