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
import com.swmansion.enriched.spans.interfaces.EnrichedListSpan
import com.swmansion.enriched.spans.interfaces.EnrichedParagraphSpan
import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.utils.EnrichedSelection
import com.swmansion.enriched.utils.ParagraphUtils.applyParagraphSpan
import com.swmansion.enriched.utils.ParagraphUtils.getPreviousParagraphSpan
import com.swmansion.enriched.utils.getListRange
import com.swmansion.enriched.utils.getParagraphBounds
import com.swmansion.enriched.utils.getParagraphsBounds
import com.swmansion.enriched.utils.isTheSameParagraphInSelection
import com.swmansion.enriched.utils.removeSpans
import com.swmansion.enriched.utils.removeZWS
import com.swmansion.enriched.watchers.TextChangedEvent

class ParagraphStyles(
  private val view: EnrichedTextInputView,
) {
  private fun removeStyleForSelection(
    editable: Editable,
    start: Int,
    end: Int,
    clazz: Class<out EnrichedSpan>,
    removeZWS: Boolean = true,
  ): Boolean {
    val paragraphRanges = editable.getParagraphsBounds(start, end)
    var removedAny = false

    for (range in paragraphRanges) {
      val paragraphStart = range.first
      val paragraphEnd = range.last
      if (removeZWS) {
        editable.removeZWS(paragraphStart, paragraphEnd)
      }
      val spans = editable.getSpans(paragraphStart, paragraphEnd, clazz)
      if (spans.isEmpty()) continue

      for (span in spans) {
        val spanStart = editable.getSpanStart(span)
        val spanEnd = editable.getSpanEnd(span)
        val intersects = spanStart <= paragraphEnd && spanEnd >= paragraphStart
        if (!intersects) continue

        editable.removeSpan(span)

        if (spanStart < paragraphStart) {
          val leftSpan = span.copy()
          editable.setSpan(leftSpan, spanStart, paragraphStart, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        }
        if (spanEnd > paragraphEnd) {
          val rightSpan = span.copy()
          editable.setSpan(rightSpan, paragraphEnd + 1, spanEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        }

        removedAny = true
      }
    }

    return removedAny
  }

  private fun buildZWSWithSpan(span: EnrichedSpan) =
    SpannableStringBuilder(Strings.ZERO_WIDTH_SPACE_STRING).apply {
      setSpan(span, 0, 1, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
    }

  fun afterTextChanged(event: TextChangedEvent) {
    val s = event.text
    var endCursorPosition = event.endCursorPosition
    val spanState = view.spanState
    var hasAppliedZWS = false
    for ((style, config) in EnrichedSpans.paragraphSpans) {
      if (style == TextStyle.DIVIDER || style == TextStyle.CONTENT) continue

      val styleStart = spanState.getStart(style)
      if (styleStart == null) continue

      if (event.isBackspace) {
        endCursorPosition -= 1
        spanState.setStart(style, null)
        continue
      }

      if (event.isNewLine) {
        if (!config.isContinuous) {
          trimNonContinuousSpanAtNewLine(s, endCursorPosition, config.clazz)
          continue
        }

        val (currentParagraphStart, currentParagraphEnd) = s.getParagraphBounds(endCursorPosition)
        val (previousParagraphStart, previousParagraphEnd) = s.getParagraphBounds(endCursorPosition - 1)

        val prevSpan = getPreviousParagraphSpan(s, currentParagraphStart, currentParagraphEnd, config.clazz) ?: continue

        s.removeSpan(prevSpan)

        s.setSpan(
          prevSpan.copy(),
          previousParagraphStart,
          previousParagraphEnd,
          Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
        )

        if (currentParagraphStart == currentParagraphEnd) {
          if (hasAppliedZWS) continue
          val zeroWidthSpace = buildZWSWithSpan(prevSpan.copy())

          s.insert(endCursorPosition, zeroWidthSpace)
          endCursorPosition += 1

          hasAppliedZWS = true
        } else {
          applyParagraphSpan(s, prevSpan.copy(), currentParagraphStart, currentParagraphEnd)
        }
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
    val selection = view.selection
    val ssb = view.editableText
    val (start, end) = selection.getParagraphSelection()

    val config = EnrichedSpans.paragraphSpans[name] ?: return
    val type = config.clazz

    val activeStart = view.spanState.getStart(name)

    if (activeStart != null) {
      view.spanState.setStart(name, null)
      removeStyleForSelection(ssb, start, end, type)
      selection.validateStyles()
      return
    }

    var currentStart = start
    val paragraphs = ssb.substring(start, end).split(Strings.NEWLINE_STRING)
    removeStyleForSelection(ssb, start, end, config.clazz, false)

    for (paragraph in paragraphs) {
      val span = createSpan(name) ?: return
      var currentEnd = currentStart + paragraph.length

      if (paragraph.isEmpty()) {
        ssb.insert(currentStart, Strings.ZERO_WIDTH_SPACE_STRING)
        currentEnd += 1
      }
      applyParagraphSpan(ssb, span, currentStart, currentEnd)
      currentStart = currentEnd + 1
    }

    selection.validateStyles()
  }

  fun getStyleRange(): Pair<Int, Int> = view.selection.getParagraphSelection()

  fun insertDivider() {
    view.spanState.setStart(TextStyle.DIVIDER, null)

    insertEscapingParagraph(
      EnrichedHorizontalRuleSpan(view.htmlStyle),
    )
    view.selection.validateStyles()
  }

  fun addContent(
    text: String,
    type: String,
    src: String,
    attributes: Map<String, String>?,
  ) {
    view.spanState.setStart(TextStyle.CONTENT, null)
    val span = EnrichedContentSpan.createEnrichedContentSpan(text, null, null, null, type, src, attributes, view.htmlStyle)
    span.attachTo(view)
    insertEscapingParagraph(
      span,
    )

    view.selection.validateStyles()
  }

  fun removeStyle(
    name: TextStyle,
    start: Int,
    end: Int,
  ): Boolean {
    val config = EnrichedSpans.paragraphSpans[name] ?: return false
    return removeStyleForSelection(view.editableText, start, end, config.clazz)
  }

  fun setParagraphAlignmentSpan(alignment: String) {
    val selection = view.selection
    val spanState = view.spanState
    val editable = view.editableText
    val (start) = selection.getParagraphSelection()
    val (pStart, pEnd) = editable.getParagraphBounds(start)

    spanState.setAlignmentStart(start, alignment)

    val isSingleParagraphSelection = editable.isTheSameParagraphInSelection(selection)

    if (isSingleParagraphSelection) {
      applySingleParagraphAlignment(editable, pStart, pEnd, alignment)
    } else {
      applyMultiParagraphAlignment(editable, selection, alignment)
    }

    view.selection.validateStyles()
  }

  private fun applySingleParagraphAlignment(
    editable: Editable,
    paragraphStart: Int,
    paragraphEnd: Int,
    alignment: String,
  ) {
    if (paragraphStart == paragraphEnd) {
      val zwsBuilder =
        SpannableStringBuilder(Strings.ZERO_WIDTH_SPACE_STRING).apply {
          setSpan(
            EnrichedAlignmentSpan(alignment),
            0,
            1,
            Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
          )
        }

      editable.replace(paragraphStart, paragraphEnd, zwsBuilder)
      return
    }

    val isOrderedOrUnorderedList = isOrderedOrUnorderedListParagraph(editable, paragraphStart, paragraphEnd)

    if (isOrderedOrUnorderedList) {
      val listSpan =
        editable
          .getSpans(paragraphStart, paragraphEnd, EnrichedParagraphSpan::class.java)
          .firstOrNull {
            it is EnrichedOrderedListSpan ||
              it is EnrichedUnorderedListSpan ||
              it is EnrichedChecklistSpan
          } ?: return

      val (listStart, listEnd) =
        editable.getListRange(paragraphStart, paragraphEnd, listSpan)

      editable.removeSpans(listStart, listEnd, EnrichedAlignmentSpan::class.java)

      editable.setSpan(
        EnrichedAlignmentSpan(alignment),
        listStart,
        listEnd,
        Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
      )
    } else {
      editable.removeSpans(paragraphStart, paragraphEnd, EnrichedAlignmentSpan::class.java)
      editable.setSpan(EnrichedAlignmentSpan(alignment), paragraphStart, paragraphEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
    }
  }

  private fun applyMultiParagraphAlignment(
    editable: Editable,
    selection: EnrichedSelection,
    alignment: String,
  ) {
    val (selStart, selEnd) = selection.getInlineSelection()

    val paragraphRanges = editable.getParagraphsBounds(selStart, selEnd)

    for (range in paragraphRanges) {
      val paragraphStart = range.first
      val paragraphEnd = range.last

      applySingleParagraphAlignment(
        editable,
        paragraphStart,
        paragraphEnd,
        alignment,
      )
    }
  }

  private fun isOrderedOrUnorderedListParagraph(
    editable: Editable,
    paragraphStart: Int,
    paragraphEnd: Int,
  ): Boolean =
    editable.getSpans(paragraphStart, paragraphEnd, EnrichedListSpan::class.java).any {
      it is EnrichedOrderedListSpan || it is EnrichedUnorderedListSpan
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
    val editable = view.editableText
    val index = view.selection.end
    val text = editable.toString()

    val hasNewlineBefore = index > 0 && text[index - 1] == Strings.NEWLINE
    val hasNewlineAfter = index < text.length && text[index] == Strings.NEWLINE

    val isParagraphEmpty =
      (index == 0 || hasNewlineBefore) &&
        (index == text.length || hasNewlineAfter)

    val prefix = if (!isParagraphEmpty && !hasNewlineBefore) Strings.NEWLINE_STRING else ""
    val suffix = if (!hasNewlineAfter) Strings.NEWLINE_STRING else ""

    val builder = SpannableStringBuilder()
    builder.append(prefix)

    val objectStartInBuilder = builder.length
    builder.append(Strings.OBJECT_REPLACEMENT_STRING)

    if (span != null) {
      builder.setSpan(
        span,
        objectStartInBuilder,
        objectStartInBuilder + Strings.OBJECT_REPLACEMENT_STRING.length,
        Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
      )
    }

    builder.append(suffix)

    editable.insert(index, builder)

    val objectStart = index + objectStartInBuilder
    isolateNonEditableParagraph(editable, objectStart, span)

    view.setSelection(index + builder.length)
  }

  private fun isolateNonEditableParagraph(
    editable: Editable,
    objectStart: Int,
    objectSpan: EnrichedSpan?,
  ) {
    val objectEnd = objectStart + Strings.OBJECT_REPLACEMENT_STRING.length
    val leftParagraphEnd =
      if (objectStart > 0 && editable[objectStart - 1] == Strings.NEWLINE) {
        objectStart - 1
      } else {
        objectStart
      }
    val rightParagraphStart =
      if (objectEnd < editable.length && editable[objectEnd] == Strings.NEWLINE) {
        objectEnd + 1
      } else {
        objectEnd
      }

    editable
      .getSpans(objectStart, objectEnd, EnrichedParagraphSpan::class.java)
      .filter {
        it !== objectSpan &&
          editable.getSpanStart(it) < objectEnd &&
          editable.getSpanEnd(it) > objectStart
      }.forEach { paragraphSpan ->
        val spanStart = editable.getSpanStart(paragraphSpan)
        val spanEnd = editable.getSpanEnd(paragraphSpan)

        editable.removeSpan(paragraphSpan)

        if (spanStart < leftParagraphEnd) {
          editable.setSpan(
            paragraphSpan.copy(),
            spanStart,
            leftParagraphEnd.coerceAtMost(spanEnd),
            Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
          )
        }

        if (spanEnd > rightParagraphStart) {
          editable.setSpan(
            paragraphSpan.copy(),
            rightParagraphStart.coerceAtLeast(spanStart),
            spanEnd,
            Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
          )
        }
      }
  }
}
