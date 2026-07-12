package com.swmansion.enriched.watchers

import android.text.Editable
import com.swmansion.enriched.constants.Strings

data class TextChangedEvent(
  val text: Editable,
  val startCursorPosition: Int,
  val endCursorPosition: Int,
  val previousTextLength: Int,
) {
  val cursorPosition: Int = endCursorPosition.coerceIn(0, text.length)
  val isBackspace: Boolean = previousTextLength > text.length
  val isNewLine: Boolean =
    cursorPosition == 0 || (cursorPosition > 0 && text[cursorPosition - 1] == Strings.NEWLINE)
}
