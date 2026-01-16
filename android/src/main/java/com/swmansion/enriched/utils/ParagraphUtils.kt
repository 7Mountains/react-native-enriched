package com.swmansion.enriched.utils

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
}
