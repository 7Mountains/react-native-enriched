package com.swmansion.enriched.text

import android.text.Spannable
import android.text.method.ArrowKeyMovementMethod
import android.view.MotionEvent
import android.widget.TextView

/**
 * The movement method of a selectable `EnrichedTextView`: the text can be
 * selected, and its links and mentions can still be pressed.
 */
internal object EnrichedTextMovementMethod : ArrowKeyMovementMethod() {
  override fun onTouchEvent(
    widget: TextView,
    buffer: Spannable,
    event: MotionEvent,
  ): Boolean {
    if ((widget as? EnrichedTextView)?.handleSpanPress(event) == true) return true

    return super.onTouchEvent(widget, buffer, event)
  }
}
