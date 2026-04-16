package com.swmansion.enriched

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.text.Spannable
import android.text.SpannableString
import android.text.SpannableStringBuilder
import com.swmansion.enriched.constants.Strings
import com.swmansion.enriched.parser.EnrichedParser
import com.swmansion.enriched.utils.trimTrailingNewlines

class EnrichedClipboardManager(
  context: Context,
  private val view: EnrichedTextInputView,
) {
  private val clipboard =
    context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager

  fun copy() {
    val start = view.selectionStart
    val end = view.selectionEnd
    val text = view.text as? Spannable ?: return

    if (start >= end) return

    val selectedText = text.subSequence(start, end) as Spannable
    val selectedHtml = EnrichedParser.toHtml(selectedText)

    val clip =
      ClipData.newHtmlText(
        EnrichedTextInputView.CLIPBOARD_TAG,
        selectedText,
        selectedHtml,
      )

    clipboard.setPrimaryClip(clip)

    moveCursorTo(end)
  }

  fun cut() {
    val start = view.selectionStart
    val end = view.selectionEnd
    val editable = view.text as? SpannableStringBuilder ?: return

    if (start >= end) return

    val selectedText = editable.subSequence(start, end) as Spannable
    val selectedHtml = EnrichedParser.toHtml(selectedText)

    val clip =
      ClipData.newHtmlText(
        EnrichedTextInputView.CLIPBOARD_TAG,
        selectedText,
        selectedHtml,
      )

    clipboard.setPrimaryClip(clip)

    view.runAsATransaction {
      editable.replace(start, end, "")
    }

    moveCursorTo(start)
  }

  fun paste() {
    if (!clipboard.hasPrimaryClip()) return

    val clip = clipboard.primaryClip ?: return
    val item = clip.getItemAt(0)

    // HTML paste (preferred)
    item.htmlText?.let { html ->
      val parsed = parse(html)
      if (parsed is Spannable) {
        insert(parsed)
        return
      }
    }

    // fallback: plain text
    val plain = item.text?.toString() ?: return
    insert(SpannableString(plain))
  }

  private fun parse(text: CharSequence): CharSequence {
    val string = text.toString()
    if (!EnrichedParser.isHtml(string)) return text

    return try {
      return EnrichedParser.fromHtml(string, view.htmlStyle, null, view)
    } catch (_: Exception) {
      text
    }
  }

  private fun insert(spannable: Spannable) {
    view.insertSpannable(spannable)
  }

  private fun moveCursorTo(position: Int) {
    val cursor = position.coerceAtLeast(0)
    view.setSelection(cursor)
  }
}
