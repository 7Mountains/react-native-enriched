package com.swmansion.enriched.watchers

import android.text.Editable
import android.text.TextWatcher
import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.events.OnChangeTextEvent
import com.swmansion.enriched.spans.interfaces.EnrichedNonEditableParagraphSpan
import com.swmansion.enriched.utils.InlineSpanPreserver
import com.swmansion.enriched.utils.ParagraphSpanNormalizer
import com.swmansion.enriched.utils.ZWSNormalizer

class EnrichedTextWatcher(
  private val view: EnrichedTextInputView,
) : TextWatcher {
  private var endCursorPosition: Int = 0
  private var previousTextLength: Int = 0
  private var startCursorPosition: Int = 0
  private var prevText: String? = view.text?.toString() ?: ""
  private var nonEditableParagraphToRemove: EnrichedNonEditableParagraphSpan? = null
  private var isApplyingInternalTextChange = false

  private val inlineSpanPreserver = InlineSpanPreserver()

  override fun beforeTextChanged(
    s: CharSequence?,
    start: Int,
    count: Int,
    after: Int,
  ) {
    if (isApplyingInternalTextChange) return

    previousTextLength = s?.length ?: 0
    startCursorPosition = start
    nonEditableParagraphToRemove = getNonEditableParagraphBeforeDeletedRange(s, start, count, after)

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
    if (isApplyingInternalTextChange) return

    endCursorPosition = start + count
    view.isRemovingMany = !view.isDuringTransaction && before > count + 1
    inlineSpanPreserver.onTextChanged(
      text = s,
      isDisabled = view.isDuringTransaction,
    )
  }

  override fun afterTextChanged(s: Editable?) {
    view.textVersion += 1

    if (isApplyingInternalTextChange) return

    if (s == null) {
      emitEvents(null)
      return
    }

    view.transactionManager.runWithBlockedTextEvents {
      view.transactionManager.runWithIgnoredSpanWatcher {
        inlineSpanPreserver.afterTextChanged()
        if (!view.isDuringTransaction) {
          runWithInternalTextChange {
            removePendingNonEditableParagraph(s)
            applyStyles(s)
          }
        }
      }
    }

    emitEvents(s)
    view.correctScrollPositionIfNeeded()
  }

  private fun applyStyles(s: Editable) {
    val styleManipulator = view.styleManipulator
    styleManipulator.inlineStyles.afterTextChanged(s, endCursorPosition)
    styleManipulator.parametrizedStyles.afterTextChanged(s, startCursorPosition, endCursorPosition)
    ParagraphSpanNormalizer.normalize(s, endCursorPosition)
    styleManipulator.listStyles.afterTextChanged(s, endCursorPosition, previousTextLength)
    styleManipulator.paragraphStyles.afterTextChanged(s, endCursorPosition, previousTextLength)
    ZWSNormalizer.normalizeNonEmptyParagraphs(s)
  }

  private fun runWithInternalTextChange(block: () -> Unit) {
    isApplyingInternalTextChange = true
    try {
      block()
    } finally {
      isApplyingInternalTextChange = false
    }
  }

  private fun getNonEditableParagraphBeforeDeletedRange(
    text: CharSequence?,
    start: Int,
    count: Int,
    after: Int,
  ): EnrichedNonEditableParagraphSpan? {
    if (text !is Editable || count != 1 || after != 0 || start <= 0) return null

    return text
      .getSpans(
        start - 1,
        start,
        EnrichedNonEditableParagraphSpan::class.java,
      ).firstOrNull {
        text.getSpanStart(it) < start && text.getSpanEnd(it) >= start
      }
  }

  private fun removePendingNonEditableParagraph(text: Editable) {
    val span = nonEditableParagraphToRemove ?: return
    nonEditableParagraphToRemove = null

    val start = text.getSpanStart(span).coerceIn(0, text.length)
    val end = text.getSpanEnd(span).coerceIn(start, text.length)
    if (start < end) {
      text.delete(start, end)
    }
  }

  private fun emitChangeText(text: String?) {
    if (!view.shouldEmitOnChangeText) {
      return
    }
    val context = view.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    view.dispatchTextRelatedEvent(
      OnChangeTextEvent(
        surfaceId,
        view.id,
        text,
        view.experimentalSynchronousEvents,
      ),
    )
  }

  private fun emitEvents(s: Editable?) {
    if (!view.shouldEmitOnChangeText) {
      view.emitOnAnyContentChangeEvent()
      return
    }

    val nextText = s?.toString() ?: ""
    if (prevText != nextText) {
      prevText = nextText
      emitChangeText(nextText)
      view.emitOnAnyContentChangeEvent()
    }
  }
}
