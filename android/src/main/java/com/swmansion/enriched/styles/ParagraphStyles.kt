package com.swmansion.enriched.styles

import android.text.Editable
import android.text.Spannable
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.util.Log
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.constants.Strings
import com.swmansion.enriched.spans.EnrichedBlockQuoteSpan
import com.swmansion.enriched.spans.EnrichedCodeBlockSpan
import com.swmansion.enriched.spans.EnrichedH1Span
import com.swmansion.enriched.spans.EnrichedH2Span
import com.swmansion.enriched.spans.EnrichedH3Span
import com.swmansion.enriched.spans.EnrichedH4Span
import com.swmansion.enriched.spans.EnrichedH5Span
import com.swmansion.enriched.spans.EnrichedH6Span
import com.swmansion.enriched.spans.EnrichedAlignmentSpan
import com.swmansion.enriched.spans.EnrichedHorizontalRuleSpan
import com.swmansion.enriched.spans.EnrichedSpans
import com.swmansion.enriched.spans.TextStyle
import com.swmansion.enriched.spans.EnrichedSpans.ALIGNMENT
import com.swmansion.enriched.spans.EnrichedSpans.CONTENT
import com.swmansion.enriched.spans.EnrichedSpans.DIVIDER
import com.swmansion.enriched.spans.ParagraphSpanConfig
import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.utils.expandDown
import com.swmansion.enriched.utils.expandUp
import com.swmansion.enriched.utils.getParagraphBounds
import com.swmansion.enriched.utils.getParagraphsBounds
import com.swmansion.enriched.utils.getSafeSpanBoundaries
import com.swmansion.enriched.utils.removeZWS
import com.swmansion.enriched.utils.isListParagraph
import com.swmansion.enriched.utils.isParagraphZeroOrOneAndEmpty
import com.swmansion.enriched.utils.paragraphRangeAt

class ParagraphStyles(
  private val view: EnrichedTextInputView,
) {
  private fun <T> getPreviousParagraphSpan(
    spannable: Spannable,
    paragraphStart: Int,
    type: Class<T>,
  ): T? {
    if (paragraphStart <= 0) return null

    val (previousParagraphStart, previousParagraphEnd) = spannable.getParagraphBounds(paragraphStart - 1)
    val spans = spannable.getSpans(previousParagraphStart, previousParagraphEnd, type)

    if (spans.size > 1) {
      Log.w("ParagraphStyles", "getPreviousParagraphSpan(): Found more than one span in the paragraph!")
    }

    return spans.firstOrNull()
  }

  private fun <T> getNextParagraphSpan(
    spannable: Spannable,
    paragraphEnd: Int,
    type: Class<T>,
  ): T? {
    if (paragraphEnd >= spannable.length - 1) return null

    val (nextParagraphStart, nextParagraphEnd) = spannable.getParagraphBounds(paragraphEnd + 1)
    val spans = spannable.getSpans(nextParagraphStart, nextParagraphEnd, type)

    if (spans.size > 1) {
      Log.w("ParagraphStyles", "getNextParagraphSpan(): Found more than one span in the paragraph!")
    }

    return spans.firstOrNull()
  }

  /**
   * Applies a continuous span to the specified range.
   * If the new range touches existing continuous spans, they are coalesced into a single span
   */
  private fun setContinuousSpan(
    spannable: Spannable,
    start: Int,
    end: Int,
    type: Class<T>,
    styleName: TextStyle,
  ) {
    val span = createSpan(styleName)
    val previousSpan = getPreviousParagraphSpan(spannable, start, type)
    val nextSpan = getNextParagraphSpan(spannable, end, type)
    var newStart = start
    var newEnd = end

    val template = previousSpan ?: nextSpan

    val newSpan: EnrichedSpan =
      when {
        template != null -> template.copy()
        else -> type.getDeclaredConstructor(HtmlStyle::class.java).newInstance(view.htmlStyle)
      }

    if (previousSpan != null) {
      newStart = spannable.getSpanStart(previousSpan)
      spannable.removeSpan(previousSpan)
    }

    if (nextSpan != null && start != end) {
      newEnd = spannable.getSpanEnd(nextSpan)
      spannable.removeSpan(nextSpan)
    }

    val (safeStart, safeEnd) = spannable.getSafeSpanBoundaries(newStart, newEnd)
    spannable.setSpan(newSpan, safeStart, safeEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
  }

  private fun setSpan(
    spannable: Spannable,
    type: Class<out EnrichedSpan>,
    start: Int,
    end: Int,
    styleName: TextStyle,
  ) {
    if (EnrichedSpans.isTypeContinuous(type)) {
      setContinuousSpan(spannable, start, end, type, styleName)
      return
    }

    val span = createSpan(styleName)
    val (safeStart, safeEnd) = spannable.getSafeSpanBoundaries(start, end)
    spannable.setSpan(span, safeStart, safeEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
  }

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

  private fun setAndMergeSpans(
    spannable: Spannable,
    type: Class<out EnrichedSpan>,
    start: Int,
    end: Int,
    styleName: TextStyle,
  ) {
    val spans = spannable.getSpans(start, end, type)

    if (spans.isEmpty()) {
      setSpan(spannable, type, start, end, styleName)
      return
    }

    var firstSpan: EnrichedSpan? = null

    for (span in spans) {
      if (firstSpan == null && span is EnrichedSpan) {
        firstSpan = span
      }
      spannable.removeSpan(span)

      if (start == spanStart && end == spanEnd) {
        setSpanOnFinish = false
      } else if (start > spanStart && end < spanEnd) {
        setSpan(spannable, type, spanStart, start, styleName)
        setSpan(spannable, type, end, spanEnd, styleName)
      } else if (start == spanStart && end < spanEnd) {
        finalStart = end
        finalEnd = spanEnd
      } else if (start > spanStart && end == spanEnd) {
        finalStart = spanStart
        finalEnd = start
      } else if (start > spanStart) {
        finalStart = spanStart
        finalEnd = end
      } else if (start < spanStart && end < spanEnd) {
        finalStart = start
        finalEnd = spanEnd
      } else {
        setSpanOnFinish = true
      }

      if (!setSpanOnFinish && finalStart != null && finalEnd != null) {
        setSpan(spannable, type, finalStart, finalEnd, styleName)
      }
    }

    if (setSpanOnFinish) {
      setSpan(spannable, type, start, end, styleName)
    }
  }

  private fun isSpanEnabledInNextLine(
    spannable: Spannable,
    index: Int,
    type: Class<out EnrichedSpan>,
  ): Boolean {
    val selection = view.selection ?: return false
    if (index + 1 >= spannable.length) return false
    val (start, end) = selection.getParagraphSelection()

    val spans = spannable.getSpans(start, end, type)
    return spans.isNotEmpty()
  }

  private fun mergeAdjacentStyleSpans(
    editable: Editable,
    endCursorPosition: Int,
    type: Class<out EnrichedSpan>,
  ) {
    val (start, end) = editable.getParagraphBounds(endCursorPosition)
    val spans = editable.getSpans(start, end, type)
    if (spans.isEmpty()) return

    val curr = spans.first()
    val next = getNextParagraphSpan(editable, end, type) ?: return

    val newStart = editable.getSpanStart(curr)
    val newEnd = editable.getSpanEnd(next)

    editable.removeSpan(curr)
    editable.removeSpan(next)

    val merged = (curr as EnrichedSpan).copy()
    editable.setSpan(merged, newStart, newEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
  }

  private fun extendStyleOnWholeParagraph(
    editable: Editable,
    span: EnrichedSpan,
    paragraphEnd: Int,
  ) {
    val currStyleStart = editable.getSpanStart(span)
    editable.removeSpan(span)
    val (safeStart, safeEnd) = editable.getSafeSpanBoundaries(currStyleStart, paragraphEnd)
    val newSpan = span.copy()
    editable.setSpan(newSpan, safeStart, safeEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
  }

  private fun deleteConflictingAndBlockingStyles(
    s: Editable,
    style: TextStyle,
    paragraphStart: Int,
    paragraphEnd: Int,
  ) {
    val mergingConfig = EnrichedSpans.getMergingConfigForStyle(style, view.htmlStyle) ?: return
    val stylesToCheck = mergingConfig.blockingStyles + mergingConfig.conflictingStyles

    for (styleToCheck in stylesToCheck) {
      val conflictingType = EnrichedSpans.allSpans[styleToCheck]?.clazz ?: continue

      val spans = s.getSpans(paragraphStart, paragraphEnd, conflictingType)
      for (span in spans) {
        s.removeSpan(span)
      }
    }
  }

  private fun <T> extendStyleOnWholeParagraph(
    s: Editable,
    span: EnrichedSpan,
    type: Class<T>,
    paragraphEnd: Int,
    styleName: TextStyle,
  ) {
    val currStyleStart = s.getSpanStart(span)
    s.removeSpan(span)
    val (safeStart, safeEnd) = s.getSafeSpanBoundaries(currStyleStart, paragraphEnd)
    setSpan(s, type, safeStart, safeEnd, styleName)
  }

  private fun handleMergedParagraph(
    s: Editable,
    cursor: Int,
  ) {
    val ssb = s as SpannableStringBuilder
    val (pStart, pEnd) = ssb.getParagraphBounds(cursor)

    val paraSpans = mutableListOf<Pair<TextStyle, EnrichedSpan>>()
    for ((style, cfg) in EnrichedSpans.paragraphSpans) {
      val spans = ssb.getSpans(pStart, pEnd, cfg.clazz)
      if (spans.isNotEmpty()) {
        paraSpans += style to spans.first()
      }
    }
    if (paraSpans.size <= 1) return

    var winner: Pair<TextStyle, EnrichedSpan>? = null
    var winnerStart = Int.MAX_VALUE
    val losers = ArrayList<Pair<TextStyle, EnrichedSpan>>()

    for ((style, span) in paraSpans) {
      val start = ssb.getSpanStart(span)
      if (start < winnerStart) {
        winner?.let { losers.add(it) }
        winner = style to span
        winnerStart = start
      } else {
        losers.add(style to span)
      }
    }

    if (winner == null) return
    val (winnerStyle, winnerSpan) = winner

    val mergeCfg = EnrichedSpans.getMergingConfigForStyle(winnerStyle, view.htmlStyle) ?: return
    val blocking = mergeCfg.blockingStyles.toSet()
    val conflicting = mergeCfg.conflictingStyles.toSet()

    ssb.removeSpan(winnerSpan)

    for ((loserStyle, loserSpan) in losers) {
      val loserStart = ssb.getSpanStart(loserSpan)
      val loserEnd = ssb.getSpanEnd(loserSpan)

      ssb.removeSpan(loserSpan)

      if (loserStyle !in blocking && loserStyle !in conflicting) {
        ssb.setSpan(loserSpan, loserStart, loserEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        continue
      }

      if (loserStart < pStart) {
        val leftPart = loserSpan.copy()
        ssb.setSpan(leftPart, loserStart, pStart, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
      }

      if (loserEnd > pEnd) {
        val rightPart = loserSpan.copy()
        ssb.setSpan(rightPart, pEnd, loserEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
      }

      view.spanState?.setStart(loserStyle, null)
    }

    ssb.setSpan(
      winnerSpan.copy(),
      winnerStart,
      pEnd,
      Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
    )

    view.spanState?.setStart(winnerStyle, winnerStart)
  }

  fun afterTextChanged(
    s: Editable,
    endPosition: Int,
    previousTextLength: Int,
  ) {
    var endCursorPosition = endPosition
    val isBackspace = s.length < previousTextLength
    val isNewLine = endCursorPosition == 0 || (endCursorPosition > 0 && s[endCursorPosition - 1] == Strings.NEWLINE)
    val spanState = view.spanState ?: return

    if (isBackspace) {
      handleMergedParagraph(s, endCursorPosition)
    }

    for ((style, config) in EnrichedSpans.paragraphSpans) {
      if (style == TextStyle.DIVIDER || style == TextStyle.CONTENT) {
        continue // simply skip non text paragraphs
      }

      val styleStart = spanState.getStart(style)

      if (style == ALIGNMENT) {
        handleAlignmentSpan(s, styleStart, endCursorPosition)
        continue
      }

      endCursorPosition =
        processParagraphStyle(
          s = s,
          style = style,
          config = config,
          styleStart = styleStart,
          isBackspace = isBackspace,
          isNewLine = isNewLine,
          cursor = endCursorPosition,
        )
    }
  }

  private fun processParagraphStyle(
    s: Editable,
    style: String,
    config: ParagraphSpanConfig,
    styleStart: Int?,
    isBackspace: Boolean,
    isNewLine: Boolean,
    cursor: Int,
  ): Int {
    var endCursorPosition = cursor
    val type = config.clazz
    if (styleStart == null) {
      if (isBackspace) {
        val (start, end) = s.getParagraphBounds(endCursorPosition)
        val spans = s.getSpans(start, end, type)

        for (span in spans) {
          deleteConflictingAndBlockingStyles(s, style, start, end)
          extendStyleOnWholeParagraph(s, span as EnrichedSpan, end)
        }
      }

      if (config.isContinuous) {
        mergeAdjacentStyleSpans(s, endCursorPosition, type)
      }

      return endCursorPosition
    }

    if (isNewLine) {
      if (!config.isContinuous) {
        view.spanState?.setStart(style, null)
        return endCursorPosition
      }

      if (isBackspace) {
        endCursorPosition -= 1
        view.spanState?.setStart(style, null)
      } else {
        s.insert(endCursorPosition, Strings.ZERO_WIDTH_SPACE_STRING)
        endCursorPosition += 1
      }
    }

    var (start, end) = s.getParagraphBounds(styleStart, endCursorPosition)

    if (isBackspace && styleStart != start) {
      val isConflicting = handleConflictsDuringNewlineDeletion(s, style, start, end)
      if (isConflicting) {
        return endCursorPosition
      }
    }

    val isNotEndLineSpan = isSpanEnabledInNextLine(s as Spannable, end, type)
    val spans = s.getSpans(start, end, type)

    for (span in spans) {
      if (isNotEndLineSpan) {
        start = s.getSpanStart(span).coerceAtMost(start)
        end = s.getSpanEnd(span).coerceAtLeast(end)
      }

      s.removeSpan(span)
    }

    setSpan(s, type, start, end)
    return endCursorPosition
  }

  fun toggleStyle(name: String) {
    val selection = view.selection ?: return
    val spannable = view.text as SpannableStringBuilder
    val (start, end) = selection.getParagraphSelection()
    val config = EnrichedSpans.paragraphSpans[name] ?: return
    val type = config.clazz

    val styleStart = view.spanState?.getStart(name)

    if (styleStart != null) {
      view.spanState.setStart(name, null)
      removeStyleForSelection(spannable, start, end, type)
      view.selection.validateStyles()

      return
    }

    if (start == end) {
      spannable.insert(start, Strings.ZERO_WIDTH_SPACE_STRING)
      setAndMergeSpans(spannable, type, start, end + 1, name)
      view.selection.validateStyles()

      return
    }

    var currentStart = start
    var currentEnd = currentStart
    val paragraphs = spannable.substring(start, end).split(Strings.NEWLINE)

    for (paragraph in paragraphs) {
      spannable.insert(currentStart, Strings.ZERO_WIDTH_SPACE_STRING)
      currentEnd = currentStart + paragraph.length + 1
      currentStart = currentEnd + 1
    }

    setAndMergeSpans(spannable, type, start, currentEnd, name)
    view.selection.validateStyles()
  }

  fun getStyleRange(): Pair<Int, Int> = view.selection?.getParagraphSelection() ?: (0 to 0)

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

  fun setParagraphAlignmentSpan(alignment: String) {
    val selection = view.selection ?: return
    val spannable = view.text as Spannable
    val (start, end) = selection.getParagraphSelection()

    val (expandedStart, expandedEnd) = expandListRange(spannable, start, end)

    spannable
      .getSpans(expandedStart, expandedEnd, EnrichedAlignmentSpan::class.java)
      .forEach { spannable.removeSpan(it) }

    val span = EnrichedAlignmentSpan(alignment)
    spannable.setSpan(span, expandedStart, expandedEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
  }

  fun removeStyle(
    name: TextStyle,
    start: Int,
    end: Int,
  ): Boolean {
    val config = EnrichedSpans.paragraphSpans[name] ?: return false
    val spannable = view.text as Spannable
    val type = config.clazz
    return removeSpansForRange(spannable, start, end, type)
  }

  private fun expandListRange(
    spannable: Spannable,
    start: Int,
    end: Int,
  ): Pair<Int, Int> {
    val safeStart = start.coerceIn(0, spannable.length)
    val safeEnd = end.coerceIn(0, spannable.length)

    if (!spannable.isListParagraph(safeStart, safeEnd)) {
      return safeStart to safeEnd
    }

    val newStart =
      spannable.expandUp(safeStart) { pS, pE ->
        spannable.isListParagraph(pS, pE)
      }

    val newEnd =
      spannable.expandDown(safeEnd) { pS, pE ->
        spannable.isListParagraph(pS, pE)
      }

    return newStart to newEnd
  }

  private fun handleAlignmentSpan(
    s: Editable,
    styleStart: Int?,
    cursor: Int,
  ) {
    if (styleStart == null) return

    val isBackspace =
      cursor > 0 &&
        cursor < s.length &&
        s.isNotEmpty() &&
        s[cursor] == Strings.NEWLINE

    val isNewLine = cursor > 0 && s[cursor - 1] == Strings.NEWLINE

    val (pStart, pEnd) = s.getParagraphBounds(styleStart, cursor)
    val spans = s.getSpans(pStart, pEnd, EnrichedAlignmentSpan::class.java)
    val current = spans.firstOrNull() ?: return

    if (isNewLine) {
      val (nextStart, nextEnd) = s.getParagraphBounds(cursor)
      val newSpan = current.copy()
      s.setSpan(newSpan, nextStart, nextEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
      return
    }

    if (isBackspace) {
      val prevParagraphEnd = cursor
      val (prevStart, prevEnd) = s.getParagraphBounds(prevParagraphEnd - 1)

      val prev = s.getSpans(prevStart, prevEnd, EnrichedAlignmentSpan::class.java).firstOrNull()
      if (prev != null) {
        val toRemove = s.getSpans(pStart, pEnd, EnrichedAlignmentSpan::class.java)
        toRemove.forEach(s::removeSpan)

        val merged = prev.copy()
        s.setSpan(
          merged,
          prevStart,
          pEnd,
          Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
        )
      }
      return
    }

    val spanStart = s.getSpanStart(current)
    val spanEnd = s.getSpanEnd(current)

    if (spanEnd != pEnd) {
      s.removeSpan(current)
      val expanded = current.copy()
      s.setSpan(expanded, spanStart, pEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
    }
  }

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
