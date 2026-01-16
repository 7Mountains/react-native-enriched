package com.swmansion.enriched.utils

import android.text.Editable
import android.text.Spannable
import android.text.SpannableStringBuilder
import android.util.Log
import com.swmansion.enriched.constants.Strings

object ZWSNormalizer {
  fun normalizeNonEmptyParagraphs(spannable: Spannable): Boolean {
    var changed = false
    var index = 0

    while (index < spannable.length) {
      val pStart = findParagraphStart(spannable, index)
      val pEnd = findParagraphEnd(spannable, index)
      val text = spannable.subSequence(pStart, pEnd).toString()

      val isEmpty =
        text.all {
          (it == Strings.NEWLINE || it == Strings.ZERO_WIDTH_SPACE_CHAR) && it != Strings.MAGIC_CHAR
        }

      if (!isEmpty) {
        if (Strings.ZERO_WIDTH_SPACE_CHAR in text) {
          val cleaned = text.replace(Strings.ZERO_WIDTH_SPACE_STRING, "")
          when (spannable) {
            is Editable -> spannable.replace(pStart, pEnd, cleaned)
            is SpannableStringBuilder -> spannable.replace(pStart, pEnd, cleaned)
            else -> return false
          }

          changed = true
        }
      }

      index = pEnd + 1
    }

    return changed
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
