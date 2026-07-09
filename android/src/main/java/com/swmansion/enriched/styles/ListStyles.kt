package com.swmansion.enriched.styles

import android.text.Editable
import android.text.Spannable
import android.text.SpannableStringBuilder
import android.text.Spanned
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.constants.Strings
import com.swmansion.enriched.spans.EnrichedAlignmentSpan
import com.swmansion.enriched.spans.EnrichedChecklistSpan
import com.swmansion.enriched.spans.EnrichedOrderedListSpan
import com.swmansion.enriched.spans.EnrichedSpans
import com.swmansion.enriched.spans.EnrichedUnorderedListSpan
import com.swmansion.enriched.spans.TextStyle
import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.utils.ParagraphUtils
import com.swmansion.enriched.utils.getParagraphBounds
import com.swmansion.enriched.utils.getSafeSpanBoundaries
import com.swmansion.enriched.utils.removeZWS

class ListStyles(
  private val view: EnrichedTextInputView,
) {
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
        val span = EnrichedOrderedListSpan(view.htmlStyle)
        spannable.setSpan(span, safeStart, safeEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
      }

      TextStyle.CHECK_LIST -> {
        val span = EnrichedChecklistSpan(view.htmlStyle)
        spannable.setSpan(span, safeStart, safeEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
      }

      else -> {}
    }
  }

  fun reapplyAlignment(
    spannable: Spannable,
    start: Int,
    end: Int,
  ) {
    val spans = spannable.getSpans(start, end, EnrichedAlignmentSpan::class.java)
    if (spans.isEmpty()) return

    spans.forEach { spannable.removeSpan(it) }

    spannable.setSpan(
      spans.first().copy(),
      start,
      end,
      Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
    )
  }

  private fun removeSpansForRange(
    spannable: Spannable,
    start: Int,
    end: Int,
    clazz: Class<out EnrichedSpan>,
    removeZWS: Boolean = true,
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

    if (removeZWS) {
      ssb.removeZWS(start, end)
    }

    return true
  }

  fun toggleStyle(name: TextStyle) {
    val config = EnrichedSpans.listSpans[name] ?: return
    val spannable = view.text as SpannableStringBuilder
    val selection = view.selection
    val spanState = view.spanState
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
      spanState.setStartWithStateChangeEmitting(name, start + 1)
      removeSpansForRange(spannable, start, end, config.clazz)
      setSpan(spannable, name, start, end + 1)
      reapplyAlignment(spannable, start, end)
      return
    }

    var currentStart = start
    val paragraphs = spannable.substring(start, end).split(Strings.NEWLINE_STRING)
    removeSpansForRange(spannable, start, end, config.clazz, false)

    for (paragraph in paragraphs) {
      var currentEnd = currentStart + paragraph.length

      if (!paragraph.contains(Strings.ZERO_WIDTH_SPACE_CHAR)) {
        spannable.insert(currentStart, Strings.ZERO_WIDTH_SPACE_STRING)
        currentEnd += 1
      }
      setSpan(spannable, name, currentStart, currentEnd)
      reapplyAlignment(spannable, currentStart, currentEnd)

      currentStart = currentEnd + 1
    }

    spanState.setStartWithStateChangeEmitting(name, currentStart)
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

      view.selection.validateStyles()
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

  fun getStyleRange(): Pair<Int, Int> = view.selection.getParagraphSelection()

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
