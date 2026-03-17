package com.swmansion.enriched.inputFilters

import android.text.InputFilter
import android.text.Spanned
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.constants.Strings

class ParagraphLimitFilter(
  private val view: EnrichedTextInputView,
) : InputFilter {
  override fun filter(
    source: CharSequence,
    start: Int,
    end: Int,
    dest: Spanned,
    dstart: Int,
    dend: Int,
  ): CharSequence? {
    val limit = view.paragraphsLimit
    if (limit <= 0) return null

    val currentParagraphs =
      dest.toString().count { it == Strings.NEWLINE } + 1

    val incomingParagraphs =
      source.subSequence(start, end).count { it == Strings.NEWLINE }

    val replacingParagraphs =
      dest.subSequence(dstart, dend).count { it == Strings.NEWLINE }

    val resultParagraphs =
      currentParagraphs - replacingParagraphs + incomingParagraphs

    if (resultParagraphs > limit) {
      return ""
    }

    return null
  }
}
