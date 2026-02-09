package com.swmansion.enriched.utils

import android.text.Spannable
import android.text.SpannableStringBuilder
import com.swmansion.enriched.constants.Strings
import com.swmansion.enriched.spans.interfaces.EnrichedListSpan

object ZWSNormalizer {
  fun normalizeNonEmptyParagraphs(spannable: Spannable) {
    val builder = spannable as? SpannableStringBuilder ?: return
    var len = builder.length

    var pStart = 0
    while (pStart < len) {
      var pEnd = pStart
      var isEmpty = true
      var hasZWS = false

      while (pEnd < len && builder[pEnd] != Strings.NEWLINE) {
        val c = builder[pEnd]
        if (c == Strings.ZERO_WIDTH_SPACE_CHAR) {
          hasZWS = true
        } else {
          isEmpty = false
        }
        pEnd++
      }

      if (hasZWS && !isEmpty) {
        if (!hasListSpan(builder, pStart, pEnd)) {
          builder.removeZWS(pStart, pEnd)

          // update length after ZWS removal
          len = builder.length
        }
      }

      pStart = pEnd + 1
    }
  }

  private fun hasListSpan(
    spannable: Spannable,
    start: Int,
    end: Int,
  ): Boolean = spannable.getSpans(start, end, EnrichedListSpan::class.java).isNotEmpty()
}
