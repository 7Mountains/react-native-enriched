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
import com.swmansion.enriched.spans.EnrichedHorizontalRuleSpan
import com.swmansion.enriched.spans.EnrichedSpans
import com.swmansion.enriched.spans.TextStyle
import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.utils.getParagraphBounds
import com.swmansion.enriched.utils.getParagraphsBounds
import com.swmansion.enriched.utils.getSafeSpanBoundaries
import com.swmansion.enriched.utils.removeZWS

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

    // A paragraph implies a single cohesive style. having multiple spans of the
    // same type (e.g., two codeblock spans) in one paragraph is an invalid state in current library logic
    if (spans.size > 1) {
      Log.w("ParagraphStyles", "getPreviousParagraphSpan(): Found more than one span in the paragraph!")
    }

    if (spans.isNotEmpty()) {
      return spans.first()
    }

    return null
  }

  private fun <T> getNextParagraphSpan(
    spannable: Spannable,
    paragraphEnd: Int,
    type: Class<T>,
  ): T? {
    if (paragraphEnd >= spannable.length - 1) return null

    val (nextParagraphStart, nextParagraphEnd) = spannable.getParagraphBounds(paragraphEnd + 1)

    val spans = spannable.getSpans(nextParagraphStart, nextParagraphEnd, type)

    // A paragraph implies a single cohesive style. having multiple spans of the
    // same type (e.g., two codeblock spans) in one paragraph is an invalid state in current library logic
    if (spans.size > 1) {
      Log.w("ParagraphStyles", "getNextParagraphSpan(): Found more than one span in the paragraph!")
    }

    if (spans.isNotEmpty()) {
      return spans.first()
    }

    return null
  }

  /**
   * Applies a continuous span to the specified range.
   * If the new range touches existing continuous spans, they are coalesced into a single span
   */
  private fun <T> setContinuousSpan(
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

    if (previousSpan != null) {
      newStart = spannable.getSpanStart(previousSpan)
      spannable.removeSpan(previousSpan)
    }

    if (nextSpan != null && start != end) {
      newEnd = spannable.getSpanEnd(nextSpan)
      spannable.removeSpan(nextSpan)
    }

    val (safeStart, safeEnd) = spannable.getSafeSpanBoundaries(newStart, newEnd)
    spannable.setSpan(span, safeStart, safeEnd, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
  }

  private fun <T> setSpan(
    spannable: Spannable,
    type: Class<T>,
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
    spannable.setSpan(span, safeStart, safeEnd, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
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
      spannableStringBuilder.removeZWS(paragraphStart, paragraphEnd)
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

  private fun <T> setAndMergeSpans(
    spannable: Spannable,
    type: Class<T>,
    start: Int,
    end: Int,
    styleName: TextStyle,
  ) {
    val spans = spannable.getSpans(start, end, type)

    // No spans setup for current selection, means we just need to assign new span
    if (spans.isEmpty()) {
      setSpan(spannable, type, start, end, styleName)
      return
    }

    var setSpanOnFinish = false

    // Some spans are present, we have to remove spans and (optionally) apply new spans
    for (span in spans) {
      val spanStart = spannable.getSpanStart(span)
      val spanEnd = spannable.getSpanEnd(span)
      var finalStart: Int? = null
      var finalEnd: Int? = null

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

  private fun <T> isSpanEnabledInNextLine(
    spannable: Spannable,
    index: Int,
    type: Class<T>,
  ): Boolean {
    val selection = view.selection ?: return false
    if (index + 1 >= spannable.length) return false
    val (start, end) = selection.getParagraphSelection()

    val spans = spannable.getSpans(start, end, type)
    return spans.isNotEmpty()
  }

  private fun <T> mergeAdjacentStyleSpans(
    s: Editable,
    endCursorPosition: Int,
    type: Class<T>,
  ) {
    val (start, end) = s.getParagraphBounds(endCursorPosition)
    val currParagraphSpans = s.getSpans(start, end, type)

    if (currParagraphSpans.isEmpty()) {
      return
    }

    val currSpan = currParagraphSpans[0]
    val nextSpan = getNextParagraphSpan(s, end, type)

    if (nextSpan == null) {
      return
    }

    val newStart = s.getSpanStart(currSpan)
    val newEnd = s.getSpanEnd(nextSpan)

    s.removeSpan(nextSpan)
    s.removeSpan(currSpan)

    val (safeStart, safeEnd) = s.getSafeSpanBoundaries(newStart, newEnd)
    val span = type.getDeclaredConstructor(HtmlStyle::class.java).newInstance(view.htmlStyle)

    s.setSpan(span, safeStart, safeEnd, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
  }

  private fun handleConflictsDuringNewlineDeletion(
    s: Editable,
    style: TextStyle,
    paragraphStart: Int,
    paragraphEnd: Int,
    styleName: TextStyle,
  ): Boolean {
    val spanState = view.spanState ?: return false
    val mergingConfig = EnrichedSpans.getMergingConfigForStyle(style, view.htmlStyle) ?: return false
    var isConflicting = false
    val stylesToCheck = mergingConfig.blockingStyles + mergingConfig.conflictingStyles

    for (styleToCheck in stylesToCheck) {
      val conflictingType = EnrichedSpans.allSpans[styleToCheck]?.clazz ?: continue

      val spans = s.getSpans(paragraphStart, paragraphEnd, conflictingType)
      if (spans.isEmpty()) {
        continue
      }
      isConflicting = true

      val isParagraphStyle = EnrichedSpans.paragraphSpans[styleToCheck] != null
      if (!isParagraphStyle) {
        continue
      }

      for (span in spans) {
        extendStyleOnWholeParagraph(s, span as EnrichedSpan, conflictingType, paragraphEnd, styleName)
      }
    }

    if (isConflicting) {
      val styleStart = spanState.getStart(style) ?: return false
      spanState.setStart(style, null)
      removeStyle(style, styleStart, paragraphEnd)
      return true
    }

    return false
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

  fun afterTextChanged(
    s: Editable,
    endPosition: Int,
    previousTextLength: Int,
  ) {
    var endCursorPosition = endPosition
    val isBackspace = s.length < previousTextLength
    val isNewLine = endCursorPosition == 0 || (endCursorPosition > 0 && s[endCursorPosition - 1] == '\n')
    val spanState = view.spanState ?: return

    for ((style, config) in EnrichedSpans.paragraphSpans) {
      if (style == TextStyle.DIVIDER || style == TextStyle.CONTENT) {
        return // simply skip non text paragraphs
      }

      val styleStart = spanState.getStart(style)

      if (styleStart == null) {
        if (isBackspace) {
          val (start, end) = s.getParagraphBounds(endCursorPosition)
          val spans = s.getSpans(start, end, config.clazz)

          for (span in spans) {
            // handle conflicts when entering paragraph with some paragraph style applied
            deleteConflictingAndBlockingStyles(s, style, start, end)
            extendStyleOnWholeParagraph(s, span as EnrichedSpan, config.clazz, end, style)
          }
        }

        if (config.isContinuous) {
          mergeAdjacentStyleSpans(s, endCursorPosition, config.clazz)
        }
        continue
      }

      if (isNewLine) {
        if (!config.isContinuous) {
          spanState.setStart(style, null)
          continue
        }

        if (isBackspace) {
          endCursorPosition -= 1
          spanState.setStart(style, null)
        } else {
          s.insert(endCursorPosition, Strings.ZERO_WIDTH_SPACE_STRING)
          endCursorPosition += 1
        }
      }

      var (start, end) = s.getParagraphBounds(styleStart, endCursorPosition)

      // handle conflicts when deleting newline from paragraph style (going back to previous line)
      if (isBackspace && styleStart != start) {
        val isConflicting = handleConflictsDuringNewlineDeletion(s, style, start, end, style)
        if (isConflicting) {
          continue
        }
      }

      val isNotEndLineSpan = isSpanEnabledInNextLine(s, end, config.clazz)
      val spans = s.getSpans(start, end, config.clazz)

      for (span in spans) {
        if (isNotEndLineSpan) {
          start = s.getSpanStart(span).coerceAtMost(start)
          end = s.getSpanEnd(span).coerceAtLeast(end)
        }

        s.removeSpan(span)
      }

      setSpan(s, config.clazz, start, end, style)
    }
  }

  fun toggleStyle(name: TextStyle) {
    if (view.selection == null) return
    val spannable = view.text as SpannableStringBuilder
    val (start, end) = view.selection.getParagraphSelection()
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
          EnrichedHorizontalRuleSpan(htmlStyle = view.htmlStyle),
          0,
          1,
          Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
        )
      }

    editable.insert(dividerIndex, builder)

    editable.append('\n')
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
  val start = lastIndexOf('\n', index - 1).let { if (it == -1) 0 else it + 1 }
  val end = indexOf('\n', index).let { if (it == -1) length else it + 1 }
  return start until end
}

private fun Editable.isParagraphZeroOrOneAndEmpty(range: IntRange): Boolean {
  val text = substring(range)

  if (text.length > 1) return false
  if (text.isEmpty()) return true

  val c = text[0]
  return c == Strings.SPACE_CHAR || c == Strings.ZERO_WIDTH_SPACE_CHAR || c == Strings.NEWLINE
}

private fun SpannableStringBuilder.cleanParagraphZWS(
  pStart: Int,
  pEnd: Int,
) {
  var hasRealText = false

  for (i in pStart until pEnd) {
    val c = this[i]
    if (c != Strings.ZERO_WIDTH_SPACE_CHAR && c != Strings.NEWLINE) {
      hasRealText = true
      break
    }
  }

  if (!hasRealText) return

  for (i in pStart until pEnd) {
    if (this[i] == Strings.ZERO_WIDTH_SPACE_CHAR) {
      delete(i, i + 1)
      return cleanParagraphZWS(pStart, pEnd - 1)
    }
  }
}
