package com.swmansion.enriched.styles

import android.text.Editable
import android.text.Spannable
import android.text.SpannableStringBuilder
import android.text.Spanned
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.constants.Strings
import com.swmansion.enriched.spans.EnrichedAlignmentSpan
import com.swmansion.enriched.spans.EnrichedBlockQuoteSpan
import com.swmansion.enriched.spans.EnrichedChecklistSpan
import com.swmansion.enriched.spans.EnrichedCodeBlockSpan
import com.swmansion.enriched.spans.EnrichedContentSpan
import com.swmansion.enriched.spans.EnrichedH1Span
import com.swmansion.enriched.spans.EnrichedH2Span
import com.swmansion.enriched.spans.EnrichedH3Span
import com.swmansion.enriched.spans.EnrichedH4Span
import com.swmansion.enriched.spans.EnrichedH5Span
import com.swmansion.enriched.spans.EnrichedH6Span
import com.swmansion.enriched.spans.EnrichedHorizontalRuleSpan
import com.swmansion.enriched.spans.EnrichedOrderedListSpan
import com.swmansion.enriched.spans.EnrichedSpans
import com.swmansion.enriched.spans.EnrichedUnorderedListSpan
import com.swmansion.enriched.spans.TextStyle
import com.swmansion.enriched.spans.interfaces.EnrichedParagraphSpan
import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.utils.EnrichedSelection
import com.swmansion.enriched.utils.ParagraphUtils
import com.swmansion.enriched.utils.asBuilder
import com.swmansion.enriched.utils.getListRange
import com.swmansion.enriched.utils.getParagraphBounds
import com.swmansion.enriched.utils.getParagraphsBounds
import com.swmansion.enriched.utils.isTheSameParagraphInSelection
import com.swmansion.enriched.utils.removeZWS
import kotlin.collections.plusAssign
import kotlin.compareTo

class ParagraphStyles(
  private val view: EnrichedTextInputView,
) {
  private fun removeStyleForSelection(
    spannable: Spannable,
    start: Int,
    end: Int,
    clazz: Class<out EnrichedSpan>,
  ): Boolean {
    val spannableStringBuilder = spannable.asBuilder()
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
    spannable.getSpans(pStart, pEnd, span::class.java).forEach {
      spannable.removeSpan(it)
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
    val ssb = view.text?.asBuilder() ?: return
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
    view.spanState?.setStart(TextStyle.DIVIDER, null)

    insertEscapingParagraph(
      EnrichedHorizontalRuleSpan(view.htmlStyle),
    )
    view.selection?.validateStyles()
  }

  fun addContent(
    text: String,
    type: String,
    src: String,
    attributes: Map<String, String>?,
  ) {
    view.spanState?.setStart(TextStyle.CONTENT, null)
    val span = EnrichedContentSpan.createEnrichedContentSpan(text, type, src, attributes, view.htmlStyle)
    span.attachTo(view)
    insertEscapingParagraph(
      span,
    )

    view.selection?.validateStyles()
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
    val canApply = view.verifyStyle(TextStyle.ALIGNMENT)

    if (!canApply) {
      return
    }

    val selection = view.selection ?: return
    val spanState = view.spanState ?: return
    val spannable = view.text as Spannable
    val (start) = selection.getParagraphSelection()
    val spannableStringBuilder = spannable.asBuilder()
    val (pStart, pEnd) = spannableStringBuilder.getParagraphBounds(start)

    spanState.setAlignmentStart(start, alignment)

    val isSingleParagraphSelection = spannable.isTheSameParagraphInSelection(selection)

    if (isSingleParagraphSelection) {
      applySingleParagraphAlignment(spannable, pStart, pEnd, alignment)
    } else {
      applyMultiParagraphAlignment(spannable, selection, alignment)
    }

    view.selection.validateStyles()
  }

  private fun applySingleParagraphAlignment(
    spannable: Spannable,
    paragraphStart: Int,
    paragraphEnd: Int,
    alignment: String,
  ) {
    if (paragraphStart == paragraphEnd) {
      val spannableStringBuilder = spannable.asBuilder()
      val zwsBuilder =
        SpannableStringBuilder(Strings.ZERO_WIDTH_SPACE_STRING).apply {
          setSpan(
            EnrichedAlignmentSpan(alignment),
            0,
            1,
            Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
          )
        }

      spannableStringBuilder.replace(paragraphStart, paragraphEnd, zwsBuilder)
      return
    }

    val isListItemParagraph = isListParagraph(spannable, paragraphStart, paragraphEnd)

    if (isListItemParagraph) {
      val listSpan =
        spannable
          .getSpans(paragraphStart, paragraphEnd, EnrichedParagraphSpan::class.java)
          .firstOrNull {
            it is EnrichedOrderedListSpan ||
              it is EnrichedUnorderedListSpan ||
              it is EnrichedChecklistSpan
          } ?: return

      val (listStart, listEnd) =
        spannable.getListRange(paragraphStart, paragraphEnd, listSpan)

      spannable
        .getSpans(listStart, listEnd, EnrichedAlignmentSpan::class.java)
        .forEach { spannable.removeSpan(it) }

      spannable.setSpan(
        EnrichedAlignmentSpan(alignment),
        listStart,
        listEnd,
        Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
      )
    } else {
      spannable.getSpans(paragraphStart, paragraphEnd, EnrichedAlignmentSpan::class.java).forEach {
        spannable.removeSpan(it)
      }
      spannable.setSpan(EnrichedAlignmentSpan(alignment), paragraphStart, paragraphEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
    }
  }

  private fun applyMultiParagraphAlignment(
    spannable: Spannable,
    selection: EnrichedSelection,
    alignment: String,
  ) {
    val (selStart, selEnd) = selection.getInlineSelection()

    val paragraphRanges = spannable.getParagraphsBounds(selStart, selEnd)

    for (range in paragraphRanges) {
      val paragraphStart = range.first
      val paragraphEnd = range.last

      applySingleParagraphAlignment(
        spannable,
        paragraphStart,
        paragraphEnd,
        alignment,
      )
    }
  }

  private fun isListParagraph(
    spannable: Spannable,
    paragraphStart: Int,
    paragraphEnd: Int,
  ): Boolean =
    spannable.getSpans(paragraphStart, paragraphEnd, EnrichedParagraphSpan::class.java).any {
      it is EnrichedChecklistSpan || it is EnrichedOrderedListSpan || it is EnrichedUnorderedListSpan
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

  private fun insertEscapingParagraph(span: EnrichedSpan?) {
    val editable = view.editableText as Editable
    val index = view.selection?.end ?: return

    val text = editable.toString()

    val hasNewlineBefore = index > 0 && text[index - 1] == Strings.NEWLINE
    val hasNewlineAfter = index < text.length && text[index] == Strings.NEWLINE

    val isParagraphEmpty =
      (index == 0 || hasNewlineBefore) &&
        (index == text.length || hasNewlineAfter)

    var insertIndex = index

    if (!isParagraphEmpty && !hasNewlineBefore) {
      editable.insert(insertIndex, Strings.NEWLINE_STRING)
      insertIndex += 1
    }

    val builder =
      SpannableStringBuilder().apply {
        append(Strings.MAGIC_CHAR)
        if (span != null) {
          setSpan(span, 0, length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        }
      }

    editable.insert(insertIndex, builder)
    insertIndex += builder.length

    if (!hasNewlineAfter) {
      editable.insert(insertIndex, Strings.NEWLINE_STRING)
      insertIndex += 1
    }

    view.setSelection(insertIndex)
  }
}

private fun Editable.isParagraphZeroOrOneAndEmpty(range: IntRange): Boolean {
  val text = substring(range)

  if (text.length > 1) return false
  if (text.isEmpty()) return true

  val c = text[0]
  return c == Strings.SPACE_CHAR || c == Strings.ZERO_WIDTH_SPACE_CHAR || c == Strings.NEWLINE
}
