package com.swmansion.enriched.styles

import android.text.Editable
import android.text.Spannable
import android.text.SpannableStringBuilder
import android.text.Spanned
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.constants.Strings
import com.swmansion.enriched.spans.EnrichedChecklistSpan
import com.swmansion.enriched.spans.EnrichedOrderedListSpan
import com.swmansion.enriched.spans.EnrichedSpans
import com.swmansion.enriched.spans.EnrichedUnorderedListSpan
import com.swmansion.enriched.spans.TextStyle
import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.utils.ParagraphUtils
import com.swmansion.enriched.utils.getParagraphBounds
import com.swmansion.enriched.utils.getPreviousParagraphSpan
import com.swmansion.enriched.utils.getSafeSpanBoundaries
import com.swmansion.enriched.utils.removeZWS

class ListStyles(
  private val view: EnrichedTextInputView,
) {
  private fun findOrderedListBounds(
    text: Spannable,
    position: Int,
  ): Pair<Int, Int>? {
    val spans = text.getSpans(position, position, EnrichedOrderedListSpan::class.java)
    if (spans.isEmpty()) return null

    val currentSpan = spans.first()
    var start = text.getSpanStart(currentSpan)
    var end = text.getSpanEnd(currentSpan)

    var cursor = start - 1
    while (cursor >= 0) {
      val (pStart, pEnd) = text.getParagraphBounds(cursor)
      val prev = text.getSpans(pStart, pEnd, EnrichedOrderedListSpan::class.java)
      if (prev.isEmpty()) break
      start = pStart
      cursor = pStart - 1
    }

    cursor = end + 1
    while (cursor < text.length) {
      val (pStart, pEnd) = text.getParagraphBounds(cursor)
      val next = text.getSpans(pStart, pEnd, EnrichedOrderedListSpan::class.java)
      if (next.isEmpty()) break
      end = pEnd
      cursor = pEnd + 1
    }

    return start to end
  }

  fun updateOrderedListIndexes(
    text: Spannable,
    position: Int,
  ) {
    val bounds = findOrderedListBounds(text, position) ?: return
    val (start, end) = bounds

    val spans =
      text
        .getSpans(start, end, EnrichedOrderedListSpan::class.java)
        .sortedBy { text.getSpanStart(it) }

    spans.forEachIndexed { index, span ->
      span.setIndex(index + 1)
    }
  }

  private fun getOrderedListIndex(
    spannable: Spannable,
    s: Int,
  ): Int {
    val span = spannable.getPreviousParagraphSpan(s, EnrichedOrderedListSpan::class.java)
    val index = span?.getIndex() ?: 0
    return index + 1
  }

  private fun setSpan(
    spannable: Spannable,
    name: TextStyle,
    start: Int,
    end: Int,
  ) {
    val (safeStart, safeEnd) = spannable.getSafeSpanBoundaries(start, end)

    when (name) {
      TextStyle.UNORDERED_LIST -> {
        val span = EnrichedUnorderedListSpan(view.htmlStyle)
        spannable.setSpan(span, safeStart, safeEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
      }

      TextStyle.ORDERED_LIST -> {
        val index = getOrderedListIndex(spannable, safeStart)
        val span = EnrichedOrderedListSpan(index, view.htmlStyle)
        spannable.setSpan(span, safeStart, safeEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
      }

      TextStyle.CHECK_LIST -> {
        val span = EnrichedChecklistSpan(view.htmlStyle)
        spannable.setSpan(span, safeStart, safeEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
      }

      else -> {}
    }
  }

  private fun removeSpansForRange(
    spannable: Spannable,
    start: Int,
    end: Int,
    clazz: Class<out EnrichedSpan>,
  ): Boolean {
    val ssb = spannable as SpannableStringBuilder
    val spans = ssb.getSpans(start, end, clazz)
    if (spans.isEmpty()) return false

    val flag = Spanned.SPAN_EXCLUSIVE_EXCLUSIVE

    for (span in spans) {
      val spanStart = ssb.getSpanStart(span)
      val spanEnd = ssb.getSpanEnd(span)

      ssb.removeSpan(span)

      if (spanStart < start) {
        ssb.setSpan(
          span.copy(),
          spanStart,
          start,
          flag,
        )
      }

      if (spanEnd > end) {
        ssb.setSpan(
          span.copy(),
          end,
          spanEnd,
          flag,
        )
      }
    }

    ssb.removeZWS(start, end)

    return true
  }

  fun toggleStyle(name: TextStyle) {
    val config = EnrichedSpans.listSpans[name] ?: return
    val spannable = view.text as SpannableStringBuilder
    val selection = view.selection ?: return
    val spanState = view.spanState ?: return
    val (start, end) = selection.getParagraphSelection()
    val styleStart = spanState.getStart(name)

    if (styleStart != null) {
      spanState.setStart(name, null)
      removeSpansForRange(spannable, start, end, config.clazz)
      selection.validateStyles()

      return
    }

    if (start == end) {
      spannable.insert(start, Strings.ZERO_WIDTH_SPACE_STRING)
      spanState.setStart(name, start + 1)
      removeSpansForRange(spannable, start, end, config.clazz)
      setSpan(spannable, name, start, end + 1)
      return
    }

    var currentStart = start
    val paragraphs = spannable.substring(start, end).split(Strings.NEWLINE_STRING)
    removeSpansForRange(spannable, start, end, config.clazz)

    for (paragraph in paragraphs) {
      spannable.insert(currentStart, Strings.ZERO_WIDTH_SPACE_STRING)
      val currentEnd = currentStart + paragraph.length + 1
      setSpan(spannable, name, currentStart, currentEnd)

      currentStart = currentEnd + 1
    }

    updateOrderedListIndexes(spannable, start)

    spanState.setStart(name, currentStart)
    spanState.emitStateChangeEvent()
  }

  private fun handleAfterTextChanged(
    s: Editable,
    name: TextStyle,
    endCursorPosition: Int,
    previousTextLength: Int,
  ) {
    val config = EnrichedSpans.listSpans[name] ?: return
    val cursorPosition = endCursorPosition.coerceAtMost(s.length)
    val (start, end) = s.getParagraphBounds(cursorPosition)

    val isBackspace = previousTextLength > s.length
    val isNewLine = cursorPosition > 0 && s[cursorPosition - 1] == Strings.NEWLINE

    if (name == TextStyle.ORDERED_LIST) {
      updateOrderedListIndexes(s, start)
    }

    if (!isBackspace && isNewLine) {
      val (currentStart, currentEnd) = s.getParagraphBounds(cursorPosition)

      val prevParagraphEnd = currentStart - 1
      if (prevParagraphEnd < 0) return

      val (prevStart, prevEnd) = s.getParagraphBounds(prevParagraphEnd)

      val prevSpans = s.getSpans(prevStart, prevEnd, config.clazz)
      if (prevSpans.isEmpty()) return

      val prevSpan = prevSpans.first()

      s.removeSpan(prevSpan)

      s.setSpan(
        prevSpan.copy(),
        prevStart,
        prevEnd,
        Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
      )

      if (currentEnd == currentStart) {
        s.insert(cursorPosition, Strings.ZERO_WIDTH_SPACE_STRING)
        setSpan(s, name, start, end + 1)
        ParagraphUtils.copyPreviousAlignmentIfSameSpan(s, start, end + 1)
      } else {
        s.setSpan(
          prevSpan.copyWithDefaults(),
          currentStart,
          currentEnd,
          Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
        )

        ParagraphUtils.copyPreviousAlignmentIfSameSpan(
          s,
          currentStart,
          currentEnd,
        )
      }

      view.selection?.validateStyles()
      return
    }
  }

  fun afterTextChanged(
    s: Editable,
    endCursorPosition: Int,
    previousTextLength: Int,
  ) {
    for ((style) in EnrichedSpans.listSpans) {
      handleAfterTextChanged(s, style, endCursorPosition, previousTextLength)
    }
  }

  fun getStyleRange(): Pair<Int, Int> = view.selection?.getParagraphSelection() ?: Pair(0, 0)

  fun removeStyle(
    name: TextStyle,
    start: Int,
    end: Int,
  ): Boolean {
    val config = EnrichedSpans.listSpans[name] ?: return false
    val spannable = view.text as Spannable
    return removeSpansForRange(spannable, start, end, config.clazz)
  }
}
