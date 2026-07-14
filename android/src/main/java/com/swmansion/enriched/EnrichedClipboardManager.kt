package com.swmansion.enriched

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.text.Spannable
import android.text.SpannableString
import com.swmansion.enriched.parser.EnrichedParser

class EnrichedClipboardManager(
  context: Context,
  private val view: EnrichedTextInputView,
) {
  private val clipboard =
    context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager

  fun copy() {
    val start = minOf(view.selectionStart, view.selectionEnd)
    val end = maxOf(view.selectionStart, view.selectionEnd)
    val clip = createSelectedTextClipData(start, end) ?: return
    clipboard.setPrimaryClip(clip)

    moveCursorTo(end)
  }

  fun cut() {
    val start = minOf(view.selectionStart, view.selectionEnd)
    val end = maxOf(view.selectionStart, view.selectionEnd)

    if (start >= end) return

    val clip = createSelectedTextClipData(start, end) ?: return
    clipboard.setPrimaryClip(clip)

    view.transactionManager.runTransaction {
      view.editableText.replace(start, end, "")
    }

    moveCursorTo(start)
  }

  fun createSelectedTextClipData(
    start: Int = view.selectionStart,
    end: Int = view.selectionEnd,
  ): ClipData? {
    val safeStart = minOf(start, end)
    val safeEnd = maxOf(start, end)

    if (safeStart >= safeEnd) return null

    val selectedText = getSelectedText(safeStart, safeEnd) ?: return null
    val selectedHtml = EnrichedParser.toHtml(selectedText)

    return ClipData.newHtmlText(
      EnrichedTextInputView.CLIPBOARD_TAG,
      selectedText,
      selectedHtml,
    )
  }

  fun paste() {
    if (!clipboard.hasPrimaryClip()) return

    val clip = clipboard.primaryClip ?: return
    insertClipData(clip)
  }

  fun insertClipData(
    clip: ClipData,
    start: Int? = null,
    end: Int? = null,
  ): Boolean {
    if (clip.itemCount == 0) return false

    val item = clip.getItemAt(0)

    // HTML paste (preferred)
    item.htmlText?.let { html ->
      val parsed = parse(html)
      if (parsed is Spannable) {
        insert(parsed, start, end)
        return true
      }
    }

    // fallback: plain text
    val plain = item.text?.toString() ?: return false
    insert(SpannableString(plain), start, end)
    return true
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

  private fun insert(
    spannable: Spannable,
    start: Int? = null,
    end: Int? = null,
  ) = view.insertSpannable(spannable, start, end)

  private fun moveCursorTo(position: Int) {
    val cursor = position.coerceAtLeast(0)
    view.setSelection(cursor)
  }

  private fun getSelectedText(
    start: Int,
    end: Int,
  ): Spannable? {
    val editableText = view.editableText
    val safeStart = start.coerceIn(0, editableText.length)
    val safeEnd = end.coerceIn(safeStart, editableText.length)

    if (safeStart >= safeEnd) return null

    return SpannableString.valueOf(editableText.subSequence(safeStart, safeEnd))
  }
}
