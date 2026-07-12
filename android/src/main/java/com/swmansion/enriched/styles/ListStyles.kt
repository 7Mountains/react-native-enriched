package com.swmansion.enriched.styles

import android.text.Spannable
import android.text.SpannableStringBuilder
import android.text.Spanned
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.constants.Strings
import com.swmansion.enriched.spans.EnrichedChecklistSpan
import com.swmansion.enriched.spans.EnrichedOrderedListSpan
import com.swmansion.enriched.spans.EnrichedSpans
import com.swmansion.enriched.spans.EnrichedUnorderedListSpan
import com.swmansion.enriched.spans.ListSpanConfig
import com.swmansion.enriched.spans.TextStyle
import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.utils.ParagraphUtils.findPreviousAlignmentSpan
import com.swmansion.enriched.utils.ParagraphUtils.getPreviousParagraphSpan
import com.swmansion.enriched.utils.getParagraphBounds
import com.swmansion.enriched.utils.getSafeSpanBoundaries
import com.swmansion.enriched.utils.removeZWS
import com.swmansion.enriched.watchers.TextChangedEvent

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

      currentStart = currentEnd + 1
    }

    spanState.setStartWithStateChangeEmitting(name, currentStart)
  }

  private fun handleAfterTextChanged(
    event: TextChangedEvent,
    config: ListSpanConfig,
  ) {
    val s = event.text
    val cursorPosition = event.cursorPosition
    val (currentParagraphStart, currentParagraphEnd) = s.getParagraphBounds(cursorPosition)

    if (!event.isBackspace && event.isNewLine) {
      val prevParagraphEnd = currentParagraphStart - 1
      if (prevParagraphEnd < 0) return

      val (prevStart, prevEnd) = s.getParagraphBounds(prevParagraphEnd)

      val prevSpan = getPreviousParagraphSpan(s, currentParagraphStart, currentParagraphEnd, config.clazz) ?: return

      s.removeSpan(prevSpan)

      s.setSpan(
        prevSpan.copy(),
        prevStart,
        prevEnd,
        Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
      )

      if (currentParagraphStart == currentParagraphEnd) {
        val zwsSpannable = SpannableStringBuilder(Strings.ZERO_WIDTH_SPACE_STRING)
        zwsSpannable.setSpan(prevSpan.copy(), 0, 1, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
        val prevAlignmentSpan = findPreviousAlignmentSpan(s, s.getParagraphBounds(cursorPosition))
        if (prevAlignmentSpan != null) {
          zwsSpannable.setSpan(prevAlignmentSpan.copy(), 0, 1, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
        }
        s.insert(cursorPosition, zwsSpannable)
      } else {
        s.setSpan(
          prevSpan.copyWithDefaults(),
          currentParagraphStart,
          currentParagraphEnd,
          Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
        )
      }

      return
    }
  }

  fun afterTextChanged(event: TextChangedEvent) {
    for ((style, config) in EnrichedSpans.listSpans) {
      if (view.spanState.getStart(style) == null) continue

      handleAfterTextChanged(event, config)
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
