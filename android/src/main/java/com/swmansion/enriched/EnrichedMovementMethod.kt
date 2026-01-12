package com.swmansion.enriched

import android.text.Spannable
import android.text.method.ArrowKeyMovementMethod
import android.view.MotionEvent
import android.widget.TextView

class EnrichedMovementMethod(
  view: EnrichedTextInputView,
) : ArrowKeyMovementMethod() {
  val checklistClickHandler: CheckListClickHandler = CheckListClickHandler(view)

  override fun onTouchEvent(
    widget: TextView,
    text: Spannable,
    event: MotionEvent,
  ): Boolean {
    val action = event.action
    when (action) {
      MotionEvent.ACTION_UP -> {
        val x = event.x.toInt() - widget.totalPaddingLeft + widget.scrollX
        val y = event.y.toInt() - widget.totalPaddingTop + widget.scrollY

        if (x < 0) return true

        val layout = widget.layout
        val line = layout.getLineForVertical(y)
        val off = layout.getOffsetForHorizontal(line, x.toFloat())
        if (checklistClickHandler.handleChecklistClick(
            text = text,
            offset = off,
            clickX = x.toFloat(),
            clickY = y.toFloat(),
            layout = layout,
          )
        ) {
          return true
        }
      }
    }

    return super.onTouchEvent(widget, text, event)
  }
}
