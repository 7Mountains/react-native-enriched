package com.swmansion.enriched.utils

import android.text.Layout
import android.text.Spannable
import android.text.Spanned
import com.swmansion.enriched.spans.EnrichedAlignmentSpan
import com.swmansion.enriched.spans.EnrichedOrderedListSpan
import com.swmansion.enriched.spans.interfaces.EnrichedSpan

object ParagraphUtils {
  fun findPreviousAlignmentSpan(
    spannable: Spannable,
    paragraphBounds: Pair<Int, Int>,
  ): EnrichedAlignmentSpan? {
    val (currentParagraphStart) = paragraphBounds
    val (prevStart, prevEnd) = spannable.getParagraphBounds(currentParagraphStart - 1)

    return spannable
      .getSpans(prevStart, prevEnd, EnrichedAlignmentSpan::class.java)
      .firstOrNull()
  }

  fun getPreviousParagraphSpan(
    spannable: Spannable,
    paragraphStart: Int,
    paragraphEnd: Int,
    clazz: Class<out EnrichedSpan>,
  ): EnrichedSpan? {
    val (prevStart, prevEnd) = spannable.getParagraphBounds(paragraphStart - 1)

    return spannable
      .getSpans(prevStart, prevEnd, clazz)
      .firstOrNull { span ->
        val spanStart = spannable.getSpanStart(span)
        val spanEnd = spannable.getSpanEnd(span)

        if (paragraphStart == paragraphEnd) {
          spanStart < prevEnd && spanEnd >= prevEnd
        } else {
          spanStart < paragraphStart && spanEnd > paragraphStart
        }
      }
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
