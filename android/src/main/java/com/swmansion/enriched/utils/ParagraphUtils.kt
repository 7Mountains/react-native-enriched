package com.swmansion.enriched.utils

import android.text.Layout
import android.text.Spannable
import android.text.Spanned
import com.swmansion.enriched.spans.EnrichedAlignmentSpan

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
}
