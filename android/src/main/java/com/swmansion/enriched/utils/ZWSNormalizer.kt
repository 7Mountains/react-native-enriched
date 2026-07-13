package com.swmansion.enriched.utils

import android.text.Editable
import android.text.Spannable
import android.text.SpannableStringBuilder
import com.swmansion.enriched.constants.Strings
import com.swmansion.enriched.spans.interfaces.EnrichedListSpan

object ZWSNormalizer {
  fun normalizeNonEmptyParagraphs(editable: Editable) {
    var len = editable.length

    var pStart = 0
    while (pStart < len) {
      var pEnd = pStart
      var isEmpty = true
      var hasZWS = false

      while (pEnd < len && editable[pEnd] != Strings.NEWLINE) {
        val c = editable[pEnd]
        if (c == Strings.ZERO_WIDTH_SPACE_CHAR) {
          hasZWS = true
        } else {
          isEmpty = false
        }
        pEnd++
      }

      if (hasZWS && !isEmpty) {
        if (!hasListSpan(editable, pStart, pEnd)) {
          editable.removeZWS(pStart, pEnd)

          // update length after ZWS removal
          len = editable.length
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
