package com.swmansion.enriched.inputFilters

import android.text.InputFilter
import android.text.Spanned
import com.swmansion.enriched.spans.interfaces.EnrichedNonEditableParagraphSpan

class NonEditableParagraphFilter : InputFilter {
  override fun filter(
    source: CharSequence?,
    start: Int,
    end: Int,
    dest: Spanned,
    dstart: Int,
    dend: Int,
  ): CharSequence? {
    if (source.isNullOrEmpty()) return null

    // Allow newline always
    if (source.length == 1 && source[0] == '\n') {
      return null
    }

    // Block replace ranges touching divider
    val replacingSpans =
      dest.getSpans(
        dstart,
        dend,
        EnrichedNonEditableParagraphSpan::class.java,
      )
    if (replacingSpans.isNotEmpty()) {
      return ""
    }

    // Block insert BEFORE divider
    if (dstart > 0) {
      val before =
        dest.getSpans(
          dstart - 1,
          dstart,
          EnrichedNonEditableParagraphSpan::class.java,
        )
      if (before.isNotEmpty()) {
        return ""
      }
    }

    // Block insert AFTER divider
    if (dstart < dest.length) {
      val after =
        dest.getSpans(
          dstart,
          dstart + 1,
          EnrichedNonEditableParagraphSpan::class.java,
        )
      if (after.isNotEmpty()) {
        return ""
      }
    }

    return null
  }
}
