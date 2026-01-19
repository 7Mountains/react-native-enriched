package com.swmansion.enriched.utils

import android.text.Spannable
import android.text.SpannableStringBuilder
import com.swmansion.enriched.constants.Strings

object ZWSNormalizer {
  fun normalizeNonEmptyParagraphs(spannable: Spannable) {
    var index = 0

    while (index < spannable.length) {
      val pStart = findParagraphStart(spannable, index)
      val pEnd = findParagraphEnd(spannable, index)
      val text = spannable.subSequence(pStart, pEnd).toString()

      val isEmptyParagraphWithZWS =
        text.all {
          (it == Strings.NEWLINE || it == Strings.ZERO_WIDTH_SPACE_CHAR)
        }

      if (!isEmptyParagraphWithZWS) {
        (spannable as SpannableStringBuilder).removeZWS(pStart, pEnd)
      }

      index = pEnd + 1
    }
  }

  private fun findParagraphStart(
    text: CharSequence,
    index: Int,
  ): Int {
    var i = index
    while (i > 0 && text[i - 1] != Strings.NEWLINE) i--
    return i
  }

  private fun findParagraphEnd(
    text: CharSequence,
    index: Int,
  ): Int {
    var i = index
    while (i < text.length && text[i] != Strings.NEWLINE) i++
    return i
  }
}
