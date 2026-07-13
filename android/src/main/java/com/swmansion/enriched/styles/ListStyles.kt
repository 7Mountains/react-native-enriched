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
import com.swmansion.enriched.spans.ListSpanConfig
import com.swmansion.enriched.spans.TextStyle
import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.utils.ParagraphUtils.applyParagraphSpan
import com.swmansion.enriched.utils.ParagraphUtils.findPreviousAlignmentSpan
import com.swmansion.enriched.utils.ParagraphUtils.getPreviousParagraphSpan
import com.swmansion.enriched.utils.getParagraphBounds
import com.swmansion.enriched.utils.getSafeSpanBoundaries
import com.swmansion.enriched.utils.removeSpans
import com.swmansion.enriched.utils.removeZWS
import com.swmansion.enriched.watchers.TextChangedEvent

class ListStyles(
  private val view: EnrichedTextInputView,
) {
  private fun setSpan(
    editable: Editable,
    name: TextStyle,
    start: Int,
    end: Int,
  ) {
    val (safeStart, safeEnd) = editable.getSafeSpanBoundaries(start, end)

    when (name) {
      TextStyle.UNORDERED_LIST -> {
        val span = EnrichedUnorderedListSpan(view.htmlStyle)
        editable.setSpan(span, safeStart, safeEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
      }

      TextStyle.ORDERED_LIST -> {
        val span = EnrichedOrderedListSpan(view.htmlStyle)
        editable.setSpan(span, safeStart, safeEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
      }

      TextStyle.CHECK_LIST -> {
        val span = EnrichedChecklistSpan(view.htmlStyle)
        editable.setSpan(span, safeStart, safeEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
      }

      else -> {}
    }
  }

  private fun removeSpansForRange(
    editable: Editable,
    start: Int,
    end: Int,
    clazz: Class<out EnrichedSpan>,
    removeZWS: Boolean = true,
  ): Boolean {
    val spans = editable.getSpans(start, end, clazz)
    if (spans.isEmpty()) return false

    val flag = Spanned.SPAN_EXCLUSIVE_EXCLUSIVE

    for (span in spans) {
      val spanStart = editable.getSpanStart(span)
      val spanEnd = editable.getSpanEnd(span)

      editable.removeSpan(span)

      if (spanStart < start) {
        editable.setSpan(
          span.copy(),
          spanStart,
          start,
          flag,
        )
      }

      if (spanEnd > end) {
        editable.setSpan(
          span.copy(),
          end,
          spanEnd,
          flag,
        )
      }
    }

    if (removeZWS) {
      editable.removeZWS(start, end)
    }

    return true
  }

  fun toggleStyle(name: TextStyle) {
    val config = EnrichedSpans.listSpans[name] ?: return
    val editable = view.editableText
    val selection = view.selection
    val spanState = view.spanState
    val (start, end) = selection.getParagraphSelection()
    val styleStart = spanState.getStart(name)

    if (styleStart != null) {
      spanState.setStart(name, null)
      removeSpansForRange(editable, start, end, config.clazz)
      selection.validateStyles()

      return
    }

    if (start == end) {
      editable.insert(start, Strings.ZERO_WIDTH_SPACE_STRING)
      spanState.setStartWithStateChangeEmitting(name, start + 1)
      removeSpansForRange(editable, start, end, config.clazz)
      val newEnd = end + 1
      setSpan(editable, name, start, newEnd)
      reapplyAlignment(editable, start, newEnd)
      return
    }

    var currentStart = start
    val paragraphs = editable.substring(start, end).split(Strings.NEWLINE_STRING)
    removeSpansForRange(editable, start, end, config.clazz, false)

    for (paragraph in paragraphs) {
      var currentEnd = currentStart + paragraph.length

      if (!paragraph.contains(Strings.ZERO_WIDTH_SPACE_CHAR)) {
        editable.insert(currentStart, Strings.ZERO_WIDTH_SPACE_STRING)
        currentEnd += 1
      }
      setSpan(editable, name, currentStart, currentEnd)
      reapplyAlignment(editable, currentStart, currentEnd)
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

      val newSpan = prevSpan.copyWithDefaults()

      if (currentParagraphStart == currentParagraphEnd) {
        val zwsSpannable = SpannableStringBuilder(Strings.ZERO_WIDTH_SPACE_STRING)
        zwsSpannable.setSpan(newSpan, 0, 1, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
        val prevAlignmentSpan = findPreviousAlignmentSpan(s, s.getParagraphBounds(cursorPosition))
        if (prevAlignmentSpan != null) {
          zwsSpannable.setSpan(prevAlignmentSpan.copy(), 0, 1, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
        }
        s.insert(cursorPosition, zwsSpannable)
      } else {
        applyParagraphSpan(s, newSpan, currentParagraphStart, currentParagraphEnd)
      }
    }
  }

  fun afterTextChanged(event: TextChangedEvent) {
    for ((style, config) in EnrichedSpans.listSpans) {
      if (view.spanState.getStart(style) == null) continue

      handleAfterTextChanged(event, config)
    }
  }

  private fun reapplyAlignment(
    editable: Editable,
    start: Int,
    end: Int,
  ) {
    val spans = editable.getSpans(start, end, EnrichedAlignmentSpan::class.java)
    if (spans.isEmpty()) return

    editable.removeSpans(spans)

    editable.setSpan(
      spans.first().copy(),
      start,
      end,
      Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
    )
  }

  fun getStyleRange(): Pair<Int, Int> = view.selection.getParagraphSelection()

  fun removeStyle(
    name: TextStyle,
    start: Int,
    end: Int,
  ): Boolean {
    val config = EnrichedSpans.listSpans[name] ?: return false
    return removeSpansForRange(view.editableText, start, end, config.clazz)
  }
}
