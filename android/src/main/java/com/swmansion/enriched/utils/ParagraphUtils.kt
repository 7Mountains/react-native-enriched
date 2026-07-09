package com.swmansion.enriched.utils

import android.text.Layout
import android.text.Spannable
import android.text.Spanned
import com.swmansion.enriched.spans.EnrichedAlignmentSpan
import com.swmansion.enriched.spans.EnrichedOrderedListSpan

object ParagraphUtils {
  fun copyPreviousAlignmentIfSameSpan(
    s: Spannable,
    newPStart: Int,
    newPEnd: Int,
  ) {
    val (prevStart, prevEnd) = s.getParagraphBounds(newPStart - 1)

    val prevAlignment =
      s
        .getSpans(prevStart, prevEnd, EnrichedAlignmentSpan::class.java)
        .firstOrNull() ?: return

    val newAlign = EnrichedAlignmentSpan(prevAlignment.alignment)
    s.setSpan(
      newAlign,
      newPStart,
      newPEnd,
      Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
    )
  }

  fun getParagraphAlignment(
    spannable: Spannable,
    position: Int,
  ): Layout.Alignment? {
    val (start, end) = spannable.getParagraphBounds(position)
    val spans = spannable.getSpans(start, end, EnrichedAlignmentSpan::class.java)

    return spans.lastOrNull()?.alignment
  }

  fun findOrderedListSpan(
    text: Spanned,
    paragraphStart: Int,
    paragraphEnd: Int,
  ): EnrichedOrderedListSpan? =
    text
      .getSpans(paragraphStart, paragraphEnd, EnrichedOrderedListSpan::class.java)
      .firstOrNull { span ->
        text.hasSpanIntersection(span, paragraphStart, paragraphEnd)
      }

  fun findParagraphAlignment(
    text: Spanned,
    paragraphStart: Int,
    paragraphEnd: Int,
  ): Layout.Alignment? =
    text
      .getSpans(paragraphStart, paragraphEnd, EnrichedAlignmentSpan::class.java)
      .lastOrNull { span ->
        text.hasSpanIntersection(span, paragraphStart, paragraphEnd)
      }?.alignment

  private fun Spanned.hasSpanIntersection(
    span: Any,
    paragraphStart: Int,
    paragraphEnd: Int,
  ): Boolean {
    val spanStart = getSpanStart(span)
    val spanEnd = getSpanEnd(span)

    return spanStart < paragraphEnd && spanEnd > paragraphStart
  }
}
