package com.swmansion.enriched.watchers

import android.text.Editable
import android.text.TextWatcher
import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.events.OnChangeTextEvent
import com.swmansion.enriched.utils.InlineSpanPreserver
import com.swmansion.enriched.utils.ParagraphSpanNormalizer
import com.swmansion.enriched.utils.ZWSNormalizer

class EnrichedTextWatcher(
  private val view: EnrichedTextInputView,
) : TextWatcher {
  private var endCursorPosition: Int = 0
  private var previousTextLength: Int = 0
  private var startCursorPosition: Int = 0

  private val inlineSpanPreserver = InlineSpanPreserver()

  override fun beforeTextChanged(
    s: CharSequence?,
    start: Int,
    count: Int,
    after: Int,
  ) {
    previousTextLength = s?.length ?: 0
    startCursorPosition = start

    inlineSpanPreserver.beforeTextChanged(
      text = s,
      start = start,
      count = count,
      after = after,
      selectionStart = view.selectionStart,
      selectionEnd = view.selectionEnd,
      isDisabled = view.isDuringTransaction,
    )
  }

  override fun onTextChanged(
    s: CharSequence?,
    start: Int,
    before: Int,
    count: Int,
  ) {
    endCursorPosition = start + count
    view.isRemovingMany = !view.isDuringTransaction && before > count + 1
    view.ignoreSpanWatcher = true
    inlineSpanPreserver.onTextChanged(
      text = s,
      isDisabled = view.isDuringTransaction,
    )
    view.ignoreSpanWatcher = false
  }

  override fun afterTextChanged(s: Editable?) {
    if (s == null) return

    inlineSpanPreserver.afterTextChanged()

    emitEvents(s)

    if (view.isDuringTransaction) return
    applyStyles(s)
  }

  private fun applyStyles(s: Editable) {
    view.blockTextEventEmitting = true

    try {
      val styleManipulator = view.styleManipulator
      styleManipulator?.inlineStyles?.afterTextChanged(s, endCursorPosition)
      styleManipulator?.parametrizedStyles?.afterTextChanged(s, startCursorPosition, endCursorPosition)
      ParagraphSpanNormalizer.normalize(s, endCursorPosition)
      styleManipulator?.listStyles?.afterTextChanged(s, endCursorPosition, previousTextLength)
      styleManipulator?.paragraphStyles?.afterTextChanged(s, endCursorPosition, previousTextLength)
      ZWSNormalizer.normalizeNonEmptyParagraphs(s)
    } finally {
      view.blockTextEventEmitting = false
    }
  }

  private fun emitChangeText(editable: Editable) {
    if (!view.shouldEmitOnChangeText) {
      return
    }
    val context = view.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    view.dispatchTextRelatedEvent(
      OnChangeTextEvent(
        surfaceId,
        view.id,
        editable,
        view.experimentalSynchronousEvents,
      ),
    )
  }

  private fun emitEvents(s: Editable) {
    emitChangeText(s)
    view.spanWatcher?.emitEvents(s, null)
  }
}
