package com.swmansion.enriched.utils

import android.text.Spannable
import android.text.Spanned
import com.swmansion.enriched.constants.Strings
import com.swmansion.enriched.spans.interfaces.EnrichedInlineSpan

/**
 * Preserves custom inline spans across Android IME suggestion/autocorrect mutations.
 *
 * Some keyboards, especially Gboard, do not always insert a single typed character.
 * While a word is being composed, the IME may replace the entire composing range by
 * calling `InputConnection.setComposingText(...)`. During that replacement Android's
 * `Editable` can drop custom inline spans that were inside the replaced range.
 *
 * Example:
 * - text: "boldtt text"
 * - composing range: [0, 6]
 * - custom bold span: [0, 4]
 * - IME replaces composing text with "boldttt"
 * - Android may keep composing spans but remove the custom bold span
 *
 * This helper snapshots affected [EnrichedInlineSpan]s in `beforeTextChanged`,
 * then reapplies them in `onTextChanged` after the framework/IME mutation has
 * already modified the text.
 *
 * It is intentionally limited to inline spans. Paragraph/list/block spans have
 * different boundary rules and are normalized elsewhere.
 */
class InlineSpanPreserver {
  private data class CarryOverSpan(
    val span: EnrichedInlineSpan,
    val start: Int,
    val end: Int,
    val flags: Int,
  )

  private val carryOverSpans = ArrayList<CarryOverSpan>()

  private var frameworkEvent = false
  private var previousInputWasSuggestion = false
  private var previousInputEventWasRegular = false
  private var isRestoringSuggestedText = false

  private var previousStart = -1
  private var previousCount = -1

  fun beforeTextChanged(
    text: CharSequence?,
    start: Int,
    count: Int,
    after: Int,
    selectionStart: Int,
    selectionEnd: Int,
    isDisabled: Boolean,
  ) {
    if (isDisabled || text !is Spannable) {
      clear()
      return
    }

    val isMultiSelection = selectionStart != selectionEnd

    frameworkEvent =
      selectionStart != start + 1 &&
      after == 0 &&
      !isMultiSelection &&
      count > 1

    isRestoringSuggestedText =
      previousStart == start &&
      previousCount == after &&
      previousInputWasSuggestion

    if (!frameworkEvent && !isRestoringSuggestedText && !isMultiSelection) {
      clear()
      carryOverInlineSpans(text, start, count, after)
      previousInputEventWasRegular = true
    } else if (frameworkEvent && previousInputEventWasRegular) {
      carryOverInlineSpans(text, start, count, after)
      previousInputEventWasRegular = false
    } else if (isRestoringSuggestedText) {
      previousInputEventWasRegular = false
    }

    previousStart = start
    previousCount = count
  }

  fun onTextChanged(
    text: CharSequence?,
    isDisabled: Boolean,
  ) {
    if (isDisabled || text !is Spannable) {
      return
    }

    if (!frameworkEvent && carryOverSpans.isNotEmpty()) {
      reapplyCarriedOverInlineSpans(text)
    }

    if (isRestoringSuggestedText) {
      clear()
    }
  }

  fun afterTextChanged() {
    if (isRestoringSuggestedText) {
      isRestoringSuggestedText = false
    }

    previousInputWasSuggestion = frameworkEvent
  }

  fun clear() {
    carryOverSpans.clear()
  }

  private fun carryOverInlineSpans(
    editableText: Spannable,
    start: Int,
    count: Int,
    after: Int,
  ) {
    val charsAdded = after - count
    val isAddingCharacters = charsAdded >= 0 && count > 0

    if (isAddingCharacters) {
      editableText
        .getSpans(
          start,
          (start + count).coerceIn(0, editableText.length),
          EnrichedInlineSpan::class.java,
        ).forEach { span ->
          addCarryOverSpan(editableText, span)
        }
      return
    }

    if (charsAdded >= 0 || count <= 0) {
      return
    }

    if (count - after <= 1) {
      editableText
        .getSpans(
          start,
          (start + after).coerceIn(0, editableText.length),
          EnrichedInlineSpan::class.java,
        ).forEach { span ->
          val spanStart = editableText.getSpanStart(span)
          var spanEnd = editableText.getSpanEnd(span)

          if (spanStart < 0 || spanEnd < 0) return@forEach

          if (
            start < editableText.length &&
            ((start == spanEnd && editableText[start] == Strings.SPACE_CHAR) || start + after >= spanEnd)
          ) {
            // Keep original boundaries.
          } else if (start < spanEnd && count - after == 1) {
            spanEnd--
          }

          addCarryOverSpan(editableText, span, spanStart, spanEnd)
        }

      return
    }

    editableText
      .getSpans(
        start,
        (start + count).coerceIn(0, editableText.length),
        EnrichedInlineSpan::class.java,
      ).forEach { span ->
        val spanStart = editableText.getSpanStart(span)
        val originalSpanEnd = editableText.getSpanEnd(span)

        if (spanStart < 0 || originalSpanEnd < 0) return@forEach

        val replacingDoubleSpaceDot =
          count == 2 &&
            start + 1 < editableText.length &&
            editableText[start] == Strings.SPACE_CHAR &&
            editableText[start + 1] == Strings.SPACE_CHAR

        val spanEnd =
          if (originalSpanEnd >= start + count && !replacingDoubleSpaceDot) {
            originalSpanEnd - (count - after)
          } else {
            originalSpanEnd
          }

        addCarryOverSpan(editableText, span, spanStart, spanEnd)
      }
  }

  private fun addCarryOverSpan(
    editableText: Spannable,
    span: EnrichedInlineSpan,
  ) {
    addCarryOverSpan(
      editableText,
      span,
      editableText.getSpanStart(span),
      editableText.getSpanEnd(span),
    )
  }

  private fun addCarryOverSpan(
    editableText: Spannable,
    span: EnrichedInlineSpan,
    start: Int,
    end: Int,
  ) {
    if (start < 0 || end < 0 || start >= end) return

    carryOverSpans.add(
      CarryOverSpan(
        span = span,
        start = start,
        end = end,
        flags = editableText.getSpanFlags(span),
      ),
    )
  }

  private fun reapplyCarriedOverInlineSpans(editableText: Spannable) {
    carryOverSpans.forEach { carried ->
      val len = editableText.length
      if (len <= 0) return@forEach

      val start = carried.start.coerceIn(0, len)
      val end = carried.end.coerceIn(0, len)

      if (start >= end) return@forEach

      try {
        editableText.setSpan(
          carried.span,
          start,
          end,
          carried.flags and Spanned.SPAN_COMPOSING.inv(),
        )
      } catch (_: IndexOutOfBoundsException) {
        // Defensive: framework/IME can mutate text ranges unexpectedly.
      } catch (_: IllegalArgumentException) {
        // Defensive: invalid span ranges on some framework builds.
      } catch (_: RuntimeException) {
        // Defensive: SpannableStringBuilder.setSpan can throw for edge cases.
      }
    }
  }
}
