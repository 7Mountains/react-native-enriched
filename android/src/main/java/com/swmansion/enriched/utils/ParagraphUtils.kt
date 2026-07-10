package com.swmansion.enriched.utils

import android.text.Layout
import android.text.Spannable
import android.text.Spanned
import com.swmansion.enriched.spans.EnrichedAlignmentSpan
import com.swmansion.enriched.spans.EnrichedOrderedListSpan

object ParagraphUtils {
  fun copyPreviousAlignmentIfSameSpan(
    spannable: Spannable,
    newPStart: Int,
    newPEnd: Int,
  ) {
    val (prevStart, prevEnd) = spannable.getParagraphBounds(newPStart - 1)

    val prevAlignment =
      spannable
        .getSpans(prevStart, prevEnd, EnrichedAlignmentSpan::class.java)
        .firstOrNull() ?: return

    val newAlign = EnrichedAlignmentSpan(prevAlignment.alignment)
    spannable.setSpan(
      newAlign,
      newPStart,
      newPEnd,
      Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
    )
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
