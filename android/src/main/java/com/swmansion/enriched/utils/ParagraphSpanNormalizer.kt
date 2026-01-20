package com.swmansion.enriched.utils

import android.text.Spannable
import android.text.Spanned
import com.swmansion.enriched.spans.EnrichedAlignmentSpan
import com.swmansion.enriched.spans.EnrichedOrderedListSpan
import com.swmansion.enriched.spans.interfaces.EnrichedParagraphSpan

object ParagraphSpanNormalizer {
  fun normalize(
    spannable: Spannable,
    cursor: Int,
  ) {
    if (spannable.isEmpty()) return
    val (pStart, pEnd) = spannable.getParagraphBounds(cursor)

    normalizeParagraphStyle(spannable, pStart, pEnd)
    normalizeAlignment(spannable, pStart, pEnd)
  }

  private fun normalizeParagraphStyle(
    spannable: Spannable,
    pStart: Int,
    pEnd: Int,
  ) {
    val spans =
      spannable
        .getSpans(pStart, pEnd, EnrichedParagraphSpan::class.java)
        .filter { it !is EnrichedAlignmentSpan }
        .sortedBy { spannable.getSpanStart(it) }

    if (spans.isEmpty()) return

    if (spans.size == 1) {
      val span = spans[0]
      val spanStart = spannable.getSpanStart(span)
      val spanEnd = spannable.getSpanEnd(span)

      if (spanStart > pStart || spanEnd < pEnd) {
        val nextStart = if (spanStart < pStart) spanStart else pStart
        spannable.removeSpan(span)
        spannable.setSpan(span.copy(), nextStart, pEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        return
      }
      return
    }

    val winner = spans.first().copy()

    spans.forEach { spannable.removeSpan(it) }

    spannable.setSpan(winner, pStart, pEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
    return
  }

  private fun normalizeAlignment(
    spannable: Spannable,
    pStart: Int,
    pEnd: Int,
  ) {
    val spans =
      spannable
        .getSpans(pStart, pEnd, EnrichedAlignmentSpan::class.java)
        .sortedBy { spannable.getSpanStart(it) }

    if (spans.isEmpty()) return

    val flag = Spanned.SPAN_EXCLUSIVE_EXCLUSIVE

    val winner = spans.first()
    val winnerAlignment = winner.alignment

    for (span in spans) {
      val start = spannable.getSpanStart(span)
      val end = spannable.getSpanEnd(span)

      spannable.removeSpan(span)

      val isWinner = (span === winner)

      if (start < pStart) {
        val left = span.copy()
        spannable.setSpan(left, start, pStart, flag)
      }

      if (end > pEnd) {
        val right = span.copy()
        spannable.setSpan(right, pEnd, end, flag)
      }

      if (isWinner) {
        val middle = span.copy()
        spannable.setSpan(middle, pStart, pEnd, flag)
      }
    }

    val hasSpanNow =
      spannable.getSpans(pStart, pEnd, EnrichedAlignmentSpan::class.java).isNotEmpty()
    if (!hasSpanNow) {
      val middle = EnrichedAlignmentSpan(winnerAlignment)
      spannable.setSpan(middle, pStart, pEnd, flag)
    }
  }
}
