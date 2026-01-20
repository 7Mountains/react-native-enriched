package com.swmansion.enriched.styles

import android.text.Editable
import android.text.Spannable
import android.text.SpannableStringBuilder
import android.text.Spanned
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.constants.Strings
import com.swmansion.enriched.spans.EnrichedAlignmentSpan
import com.swmansion.enriched.spans.EnrichedBlockQuoteSpan
import com.swmansion.enriched.spans.EnrichedCodeBlockSpan
import com.swmansion.enriched.spans.EnrichedH1Span
import com.swmansion.enriched.spans.EnrichedH2Span
import com.swmansion.enriched.spans.EnrichedH3Span
import com.swmansion.enriched.spans.EnrichedH4Span
import com.swmansion.enriched.spans.EnrichedH5Span
import com.swmansion.enriched.spans.EnrichedH6Span
import com.swmansion.enriched.spans.EnrichedHorizontalRuleSpan
import com.swmansion.enriched.spans.EnrichedSpans
import com.swmansion.enriched.spans.TextStyle
import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.utils.ParagraphUtils
import com.swmansion.enriched.utils.expandDown
import com.swmansion.enriched.utils.expandListBlockAtCursor
import com.swmansion.enriched.utils.expandUp
import com.swmansion.enriched.utils.getParagraphBounds
import com.swmansion.enriched.utils.getParagraphsBounds
import com.swmansion.enriched.utils.removeZWS

class ParagraphStyles(
  private val view: EnrichedTextInputView,
) {
  private fun removeStyleForSelection(
    spannable: Spannable,
    start: Int,
    end: Int,
    clazz: Class<out EnrichedSpan>,
  ): Boolean {
    val spannableStringBuilder = spannable as SpannableStringBuilder
    val paragraphRanges = spannable.getParagraphsBounds(start, end)
    var removedAny = false

    for (range in paragraphRanges) {
      val paragraphStart = range.first
      val paragraphEnd = range.last
      spannableStringBuilder.removeZWS(paragraphStart, paragraphEnd + 1)
      val spans = spannableStringBuilder.getSpans(paragraphStart, paragraphEnd, clazz)
      if (spans.isEmpty()) continue

      for (span in spans) {
        val spanStart = spannableStringBuilder.getSpanStart(span)
        val spanEnd = spannableStringBuilder.getSpanEnd(span)
        val intersects = spanStart <= paragraphEnd && spanEnd >= paragraphStart
        if (!intersects) continue

        spannableStringBuilder.removeSpan(span)

        if (spanStart < paragraphStart) {
          val leftSpan = span.copy()
          spannableStringBuilder.setSpan(leftSpan, spanStart, paragraphStart, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        }
        if (spanEnd > paragraphEnd) {
          val rightSpan = span.copy()
          spannableStringBuilder.setSpan(rightSpan, paragraphEnd + 1, spanEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        }

        removedAny = true
      }
    }

    return removedAny
  }

  private fun applyParagraphSpan(
    spannable: Spannable,
    span: EnrichedSpan,
    pStart: Int,
    pEnd: Int,
  ) {
    val spans = spannable.getSpans(pStart, pEnd, span::class.java)
    for (existing in spans) {
      spannable.removeSpan(existing)
    }

    spannable.setSpan(span, pStart, pEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
  }

  fun afterTextChanged(
    s: Editable,
    endPosition: Int,
    previousTextLength: Int,
  ) {
    var endCursorPosition = endPosition
    val isBackspace = s.length < previousTextLength
    val isNewLine = endCursorPosition == 0 || (endCursorPosition > 0 && s[endCursorPosition - 1] == '\n')
    val spanState = view.spanState ?: return
    var hasAppliedZWS = false
    for ((style, config) in EnrichedSpans.paragraphSpans) {
      if (style == TextStyle.DIVIDER || style == TextStyle.CONTENT) continue

      val styleStart = spanState.getStart(style)
      if (styleStart == null) continue

      if (isNewLine) {
        if (!config.isContinuous) {
          trimNonContinuousSpanAtNewLine(s, endCursorPosition, config.clazz)
          continue
        }

        if (isBackspace) {
          endCursorPosition -= 1
          spanState.setStart(style, null)
          continue
        }
        if (hasAppliedZWS) continue
        val (prevPStart, prevPEnd) = s.getParagraphBounds(endCursorPosition - 1)

        val prevSpan =
          s
            .getSpans(prevPStart, prevPEnd, config.clazz)
            .firstOrNull() ?: continue

        s.insert(endCursorPosition, Strings.ZERO_WIDTH_SPACE_STRING)
        endCursorPosition += 1

        val (pStart, pEnd) = s.getParagraphBounds(endCursorPosition)

        applyParagraphSpan(s, prevSpan.copy(), pStart, pEnd)

        ParagraphUtils.copyPreviousAlignmentIfSameSpan(s, pStart, pEnd)

        spanState.setStart(style, null)
        hasAppliedZWS = true
      }
    }
  }

  private fun trimNonContinuousSpanAtNewLine(
    s: Editable,
    cursor: Int,
    type: Class<out EnrichedSpan>,
  ) {
    val safeIndex = (cursor - 1).coerceAtLeast(0)
    val (pStart, pEnd) = s.getParagraphBounds(safeIndex)

    val spans = s.getSpans(pStart, pEnd, type)
    if (spans.isEmpty()) return

    val span = spans.first()
    val spanStart = s.getSpanStart(span)

    s.removeSpan(span)

    if (spanStart < pEnd) {
      val newSpan = span.copy()
      s.setSpan(
        newSpan,
        spanStart,
        pEnd,
        Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
      )
    }
  }

  fun toggleStyle(name: TextStyle) {
    val selection = view.selection ?: return
    val ssb = view.text as SpannableStringBuilder
    val (start, end) = selection.getParagraphSelection()

    val config = EnrichedSpans.paragraphSpans[name] ?: return
    val type = config.clazz

    val activeStart = view.spanState?.getStart(name)

    if (activeStart != null) {
      view.spanState.setStart(name, null)
      removeStyleForSelection(ssb, start, end, type)
      view.selection.validateStyles()
      return
    }

    val (pStart, pEnd) = ssb.getParagraphBounds(start)

    val hasRealText = ssb.substring(pStart, pEnd).any { it != '\u200B' && it != '\n' }

    val span = createSpan(name) ?: return

    if (!hasRealText) {
      // Insert ZWS with paragraph style
      val zwsBuilder =
        SpannableStringBuilder(Strings.ZERO_WIDTH_SPACE_STRING).apply {
          setSpan(
            span,
            0,
            length,
            Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
          )
        }

      ssb.replace(pStart, pEnd, zwsBuilder)

      view.setSelection(pStart + 1)
      view.selection.validateStyles()
      return
    }

    applyParagraphSpan(ssb, span, pStart, pEnd)

    view.selection.validateStyles()
  }

  fun getStyleRange(): Pair<Int, Int> = view.selection?.getParagraphSelection() ?: Pair(0, 0)

  fun insertDivider() {
    val editable = view.editableText as Editable
    val index = view.selection?.end ?: return

    val safeIndex = index.coerceIn(0, editable.length)
    val paragraphRange = editable.paragraphRangeAt(safeIndex)

    if (!editable.isParagraphZeroOrOneAndEmpty(paragraphRange)) {
      return
    }

    if (paragraphRange.count() == 1) {
      editable.delete(paragraphRange.first, paragraphRange.last)
    }

    view.spanState?.setStart(TextStyle.DIVIDER, null)

    val dividerIndex = paragraphRange.first

    val builder =
      SpannableStringBuilder().apply {
        append(Strings.MAGIC_STRING)
        setSpan(
          EnrichedHorizontalRuleSpan(view.htmlStyle),
          0,
          1,
          Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
        )
      }

    editable.insert(dividerIndex, builder)

    editable.append(Strings.NEWLINE)
  }

  fun removeStyle(
    name: TextStyle,
    start: Int,
    end: Int,
  ): Boolean {
    val config = EnrichedSpans.paragraphSpans[name] ?: return false
    val spannable = view.text as Spannable
    return removeStyleForSelection(spannable, start, end, config.clazz)
  }

  fun setParagraphAlignmentSpan(alignment: String) {
    val selection = view.selection ?: return
    val spanState = view.spanState ?: return
    val spannable = view.text as Spannable
    val (start) = selection.getParagraphSelection()
    val spannableStringBuilder = spannable as SpannableStringBuilder
    val (pStart, pEnd) = spannableStringBuilder.getParagraphBounds(start)

    val originalCursor = start

    spanState.setAlignmentStart(start, alignment)

    if (pStart == pEnd) {
      val zwsBuilder =
        SpannableStringBuilder(Strings.ZERO_WIDTH_SPACE_STRING).apply {
          setSpan(
            EnrichedAlignmentSpan(alignment),
            0,
            1,
            Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
          )
        }

      spannableStringBuilder.replace(pStart, pEnd, zwsBuilder)
      view.selection.validateStyles()
      return
    }

    val (expandedStart, expandedEnd) =
      expandListRange(spannable, originalCursor, originalCursor)

    spannable
      .getSpans(expandedStart, expandedEnd, EnrichedAlignmentSpan::class.java)
      .forEach { spannable.removeSpan(it) }

    val alignmentSpan = EnrichedAlignmentSpan(alignment)
    spannable.setSpan(
      alignmentSpan,
      expandedStart,
      expandedEnd,
      Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
    )

    view.selection.validateStyles()
  }

  private fun expandListRange(
    spannable: Spannable,
    start: Int,
    end: Int,
  ): Pair<Int, Int> {
    val safeStart = start.coerceIn(0, spannable.length)
    val safeEnd = end.coerceIn(0, spannable.length)

    val isCollapsed = safeStart == safeEnd

    return if (isCollapsed) {
      spannable
        .expandListBlockAtCursor(safeStart)
        ?.let { it.first to (it.last + 1) }
        ?: (safeStart to safeEnd)
    } else {
      val newStart =
        spannable.expandUp(safeStart) { pS, pE ->
          paragraphIntersectsSelection(pS, pE, safeStart, safeEnd)
        }

      val newEnd =
        spannable.expandDown(safeEnd) { pS, pE ->
          paragraphIntersectsSelection(pS, pE, safeStart, safeEnd)
        }

      newStart to newEnd
    }
  }

  private fun paragraphIntersectsSelection(
    pStart: Int,
    pEnd: Int,
    selStart: Int,
    selEnd: Int,
  ): Boolean = pStart < selEnd && pEnd > selStart

  private fun createSpan(name: TextStyle): EnrichedSpan? =
    when (name) {
      TextStyle.H1 -> EnrichedH1Span(view.htmlStyle)
      TextStyle.H2 -> EnrichedH2Span(view.htmlStyle)
      TextStyle.H3 -> EnrichedH3Span(view.htmlStyle)
      TextStyle.H4 -> EnrichedH4Span(view.htmlStyle)
      TextStyle.H5 -> EnrichedH5Span(view.htmlStyle)
      TextStyle.H6 -> EnrichedH6Span(view.htmlStyle)
      TextStyle.BLOCK_QUOTE -> EnrichedBlockQuoteSpan(view.htmlStyle)
      TextStyle.CODE_BLOCK -> EnrichedCodeBlockSpan(view.htmlStyle)
      else -> null
    }
}

private fun Editable.paragraphRangeAt(index: Int): IntRange {
  val start = lastIndexOf(Strings.NEWLINE, index - 1).let { if (it == -1) 0 else it + 1 }
  val end = indexOf(Strings.NEWLINE, index).let { if (it == -1) length else it + 1 }
  return start until end
}

private fun Editable.isParagraphZeroOrOneAndEmpty(range: IntRange): Boolean {
  val text = substring(range)

  if (text.length > 1) return false
  if (text.isEmpty()) return true

  val c = text[0]
  return c == Strings.SPACE_CHAR || c == Strings.ZERO_WIDTH_SPACE_CHAR || c == Strings.NEWLINE
}
