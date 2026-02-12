package com.swmansion.enriched

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
      MotionEvent.ACTION_DOWN -> handleDown(text, offset, x)
      MotionEvent.ACTION_UP -> handleUp(text, offset, x)
      else -> false
    }
  }

  private fun handleDown(
    text: Spannable,
    offset: Int,
    clickX: Float,
  ): Boolean {
    val span =
      text.getSpans(offset, offset, EnrichedChecklistSpan::class.java).firstOrNull()
        ?: return false

    return hitTestCheckbox(clickX, span)
  }

  private fun handleUp(
    text: Spannable,
    offset: Int,
    clickX: Float,
  ): Boolean {
    val span =
      text.getSpans(offset, offset, EnrichedChecklistSpan::class.java).firstOrNull()
        ?: return false

    if (!hitTestCheckbox(clickX, span)) return false

    // toggle state
    span.toggleChecked()
    view.redrawSpan(span)

    val (_, paragraphEnd) = text.getParagraphBounds(offset, offset)
    if (!view.isFocused) {
      view.requestFocusProgrammatically()
    }
    view.setSelection(paragraphEnd)

    return true
  }

  private fun hitTestCheckbox(
    clickX: Float,
    span: EnrichedChecklistSpan,
  ): Boolean {
    val leadingMargin = span.getLeadingMargin(true)

    return clickX <= leadingMargin
  }
}
