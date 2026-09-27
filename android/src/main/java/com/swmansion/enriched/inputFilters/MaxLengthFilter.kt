package com.swmansion.enriched.inputFilters

import android.icu.text.BreakIterator
import android.text.InputFilter
import android.text.SpannableString
import android.text.Spanned
import android.text.TextUtils
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.constants.Strings

object MaxLength {
  const val UNLIMITED = -1

  fun plainTextLengthOf(
    text: CharSequence,
    start: Int = 0,
    end: Int = text.length,
  ): Int = text.subSequence(start, end).count { it != Strings.ZERO_WIDTH_SPACE_CHAR }

  fun cutIndexToFitWithin(
    text: CharSequence,
    start: Int,
    end: Int,
    capacity: Int,
  ): Int {
    val value = text.subSequence(start, end).toString()
    val iterator =
      BreakIterator.getCharacterInstance().apply {
        setText(value)
      }

    var kept = 0
    var cut = 0
    var clusterStart = iterator.first()
    var clusterEnd = iterator.next()

    while (clusterEnd != BreakIterator.DONE) {
      var clusterLength = 0
      for (index in clusterStart until clusterEnd) {
        if (value[index] != Strings.ZERO_WIDTH_SPACE_CHAR) {
          clusterLength++
        }
      }

      // Capacity is measured in UTF-16 code units, but grapheme clusters are
      // atomic and must either fit completely or be omitted.
      if (kept + clusterLength > capacity) {
        break
      }

      kept += clusterLength
      cut = clusterEnd
      clusterStart = clusterEnd
      clusterEnd = iterator.next()
    }

    return start + cut
  }
}

/**
 * Applies the `maxLength` limit to every change made to the editor's text - typing, dictation, IME
 * composition, pasting and setting the value imperatively all go through the filters of the
 * underlying `Editable`.
 */
class MaxLengthFilter(
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
    val maxLength = view.maxLength
    if (maxLength == MaxLength.UNLIMITED) return null

    val keptLength = MaxLength.plainTextLengthOf(dest) - MaxLength.plainTextLengthOf(dest, dstart, dend)
    val capacity = maxLength - keptLength

    if (MaxLength.plainTextLengthOf(source, start, end) <= capacity) {
      // null keeps the original change
      return null
    }

    val cut = MaxLength.cutIndexToFitWithin(source, start, end, capacity)

    return if (cut <= start) "" else source.copyRangePreservingSpans(start, cut)
  }

  private fun CharSequence.copyRangePreservingSpans(
    start: Int,
    end: Int,
  ): CharSequence {
    if (this !is Spanned) return subSequence(start, end)

    return SpannableString(subSequence(start, end).toString()).also { result ->
      TextUtils.copySpansFrom(this, start, end, Any::class.java, result, 0)
    }
  }
}
