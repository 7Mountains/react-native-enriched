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
import com.swmansion.enriched.utils.getParagraphRanges
import com.swmansion.enriched.utils.getSafeSpanBoundaries
import com.swmansion.enriched.utils.removeSpans
import com.swmansion.enriched.utils.removeZWS
import com.swmansion.enriched.watchers.TextChangedEvent

class ListStyles(
  private val view: EnrichedTextInputView,
) {
  private data class StyledListReplacement(
    val text: SpannableStringBuilder,
    val insertedCharacters: Int,
    val styleStart: Int,
  )

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
        applyParagraphSpan(editable, span, safeStart, safeEnd)
      }

      TextStyle.ORDERED_LIST -> {
        val span = EnrichedOrderedListSpan(view.htmlStyle)
        applyParagraphSpan(editable, span, safeStart, safeEnd)
      }

      TextStyle.CHECK_LIST -> {
        val span = EnrichedChecklistSpan(view.htmlStyle)
        applyParagraphSpan(editable, span, safeStart, safeEnd)
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
    val safeStart = start.coerceAtMost(end).coerceAtLeast(0).coerceAtMost(editable.length)
    val safeEnd = end.coerceAtLeast(start).coerceAtLeast(safeStart).coerceAtMost(editable.length)
    val spans = editable.getSpans(safeStart, safeEnd, clazz)
    if (spans.isEmpty()) return false

    val flag = Spanned.SPAN_EXCLUSIVE_EXCLUSIVE

    for (span in spans) {
      val spanStart = editable.getSpanStart(span)
      val spanEnd = editable.getSpanEnd(span)

      editable.removeSpan(span)

      if (spanStart < safeStart) {
        editable.setSpan(
          span.copy(),
          spanStart,
          safeStart,
          flag,
        )
      }

      if (spanEnd > safeEnd) {
        editable.setSpan(
          span.copy(),
          safeEnd,
          spanEnd,
          flag,
        )
      }
    }

    if (removeZWS) {
      if (view.selection.isSingleParagraphInSelection()) {
        val safeStart = start.coerceIn(0, editable.length)
        val safeEnd = end.coerceIn(safeStart, editable.length)

        for (index in safeEnd - 1 downTo safeStart) {
          if (editable[index] == Strings.ZERO_WIDTH_SPACE_CHAR) {
            editable.delete(index, index + 1)
          }
        }
      } else {
        val replacement = SpannableStringBuilder(editable.subSequence(safeStart, safeEnd))
        replacement.removeZWS(0, replacement.length)
        val removedCharacters = safeEnd - safeStart - replacement.length

        if (removedCharacters > 0) {
          editable.replace(safeStart, safeEnd, replacement)
        }
      }
    }

    return true
  }

  private fun buildStyledListReplacement(
    editable: Editable,
    start: Int,
    end: Int,
    name: TextStyle,
  ): StyledListReplacement {
    val replacement = SpannableStringBuilder(editable.subSequence(start, end))
    var insertedCharacters = 0
    var styleStart = 0
    val paragraphs = replacement.getParagraphRanges()

    for (paragraph in paragraphs) {
      val currentStart = paragraph.first + insertedCharacters
      var currentEnd = paragraph.last + insertedCharacters

      if (!replacement.containsZWS(currentStart, currentEnd)) {
        replacement.insert(currentStart, Strings.ZERO_WIDTH_SPACE_STRING)
        currentEnd += 1
        insertedCharacters += 1
      }

      setSpan(replacement, name, currentStart, currentEnd)
      reapplyAlignment(replacement, currentStart, currentEnd)
      styleStart = currentEnd + 1
    }

    return StyledListReplacement(replacement, insertedCharacters, styleStart)
  }

  private fun CharSequence.containsZWS(
    start: Int,
    end: Int,
  ): Boolean {
    val safeStart = start.coerceIn(0, length)
    val safeEnd = end.coerceIn(safeStart, length)

    for (index in safeStart until safeEnd) {
      if (this[index] == Strings.ZERO_WIDTH_SPACE_CHAR) return true
    }

    return false
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

    if (start == end || selection.isSingleParagraphInSelection()) {
      editable.insert(start, Strings.ZERO_WIDTH_SPACE_STRING)
      spanState.setStartWithStateChangeEmitting(name, start + 1)
      val newEnd = end + 1
      setSpan(editable, name, start, newEnd)
      reapplyAlignment(editable, start, newEnd)
      return
    }

    val replacement = buildStyledListReplacement(editable, start, end, name)
    editable.replace(start, end, replacement.text)
    spanState.setStartWithStateChangeEmitting(name, start + replacement.styleStart)
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
