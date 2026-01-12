package com.swmansion.enriched

import android.text.Layout
import android.text.Spannable
import android.view.MotionEvent
import com.swmansion.enriched.spans.EnrichedChecklistSpan
import com.swmansion.enriched.utils.getParagraphBounds

class CheckListClickHandler(
  private val view: EnrichedTextInputView,
) {
  fun handleTouch(event: MotionEvent): Boolean {
    val text = view.text as? Spannable ?: return false
    val layout = view.layout ?: return false

    val x = event.x - view.totalPaddingLeft + view.scrollX
    val y = event.y - view.totalPaddingTop + view.scrollY

    if (x < 0) return false

    val line = layout.getLineForVertical(y.toInt())
    val offset = layout.getOffsetForHorizontal(line, x)

    return when (event.action) {
      MotionEvent.ACTION_DOWN -> handleDown(text, layout, offset, x, y)
      MotionEvent.ACTION_UP -> handleUp(text, layout, offset, x, y)
      else -> false
    }
  }

  private fun handleDown(
    text: Spannable,
    layout: Layout,
    offset: Int,
    x: Float,
    y: Float,
  ): Boolean {
    val span =
      text.getSpans(offset, offset, EnrichedChecklistSpan::class.java).firstOrNull()
        ?: return false

    val line = layout.getLineForOffset(offset)
    return isInsideCheckbox(span, layout, line, x, y)
  }

  private fun handleUp(
    text: Spannable,
    layout: Layout,
    offset: Int,
    x: Float,
    y: Float,
  ): Boolean {
    val span =
      text.getSpans(offset, offset, EnrichedChecklistSpan::class.java).firstOrNull()
        ?: return false

    val line = layout.getLineForOffset(offset)

    if (!isInsideCheckbox(span, layout, line, x, y)) return false

    // toggle state
    span.toggleChecked()
    view.redrawSpan(span)

    val (_, paragraphEnd) = text.getParagraphBounds(offset, offset)

    view.setSelection(paragraphEnd)

    return true
  }

  private fun isInsideCheckbox(
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
