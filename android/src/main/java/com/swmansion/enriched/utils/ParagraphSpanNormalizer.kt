package com.swmansion.enriched.utils

import android.text.Editable
import android.text.Spannable
import android.text.Spanned
import com.swmansion.enriched.spans.EnrichedAlignmentSpan
import com.swmansion.enriched.spans.interfaces.EnrichedParagraphSpan

object ParagraphSpanNormalizer {
  fun normalize(
    editable: Editable,
    cursor: Int,
  ) {
    if (editable.isEmpty()) return
    val (pStart, pEnd) = editable.getParagraphBounds(cursor)

    normalizeParagraphStyle(editable, pStart, pEnd)
    normalizeAlignment(editable, pStart, pEnd)
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
    editable: Editable,
    pStart: Int,
    pEnd: Int,
  ) {
    val spans =
      editable
        .getSpans(pStart, pEnd, EnrichedAlignmentSpan::class.java)
        .sortedBy { editable.getSpanStart(it) }

    if (spans.isEmpty()) return

    val flag = Spanned.SPAN_EXCLUSIVE_EXCLUSIVE

    val winner = spans.first()
    val winnerAlignment = winner.alignment

    for (span in spans) {
      val start = editable.getSpanStart(span)
      val end = editable.getSpanEnd(span)

      editable.removeSpan(span)

      val isWinner = span === winner

      if (start < pStart) {
        val left = span.copy()
        editable.setSpan(left, start, pStart, flag)
      }

      if (end > pEnd) {
        val right = span.copy()
        editable.setSpan(right, pEnd, end, flag)
      }

      if (isWinner) {
        val middle = span.copy()
        editable.setSpan(middle, pStart, pEnd, flag)
      }
    }

    val hasSpanNow =
      editable.getSpans(pStart, pEnd, EnrichedAlignmentSpan::class.java).isNotEmpty()
    if (!hasSpanNow) {
      val middle = EnrichedAlignmentSpan(winnerAlignment)
      editable.setSpan(middle, pStart, pEnd, flag)
    }
  }
}
