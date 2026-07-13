package com.swmansion.enriched.styles

import android.text.Editable
import android.text.Spannable
import android.text.SpannableStringBuilder
import android.text.Spanned
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.constants.Strings
import com.swmansion.enriched.spans.EnrichedImageSpan
import com.swmansion.enriched.spans.EnrichedLinkSpan
import com.swmansion.enriched.spans.EnrichedMentionSpan
import com.swmansion.enriched.spans.EnrichedSpans
import com.swmansion.enriched.spans.TextStyle
import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.utils.getSafeSpanBoundaries
import com.swmansion.enriched.utils.removeSpans
import com.swmansion.enriched.utils.removeZWS
import com.swmansion.enriched.watchers.TextChangedEvent
import kotlin.math.max

class ParametrizedStyles(
  private val view: EnrichedTextInputView,
) {
  private var mentionStart: Int? = null
  private var isSettingLinkSpan = false

  var mentionIndicators: Array<String> = emptyArray<String>()

  fun removeSpansForRange(
    editable: Editable,
    start: Int,
    end: Int,
    clazz: Class<out EnrichedSpan>,
  ): Boolean {
    val spans = editable.getSpans(start, end, clazz)
    if (spans.isEmpty()) return false

    editable.removeZWS(start, end)

    editable.removeSpans(spans)

    return true
  }

  fun setLinkSpan(
    start: Int,
    end: Int,
    text: String,
    url: String,
  ) {
    isSettingLinkSpan = true
    val editable = view.editableText

    removeLinkSpan(start, end)

    val insertedSpannable = SpannableStringBuilder(text)
    val span = EnrichedLinkSpan(url, view.htmlStyle, true)
    insertedSpannable.setSpan(span, 0, text.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)

    if (start == end) {
      editable.insert(start, insertedSpannable)
    } else {
      editable.replace(start, end, insertedSpannable)
    }

    view.selection.validateStyles()
    isSettingLinkSpan = false
  }

  fun removeLinkSpan(
    start: Int,
    end: Int,
  ) = view.editableText.removeSpans(start, end, EnrichedLinkSpan::class.java)

  // Determines word ranges affected by an edit by expanding to surrounding word boundaries.
  private fun getAffectedWords(
    text: CharSequence,
    start: Int,
    end: Int,
  ): List<TextRange> {
    if (text.isEmpty()) {
      return emptyList()
    }

    val safeStart = start.coerceIn(0, text.length)
    val safeEnd = end.coerceIn(0, text.length)

    var actualStart = minOf(safeStart, safeEnd)
    var actualEndExclusive = maxOf(safeStart, safeEnd)

    // Expand backward to find the start of the first affected word
    while (
      actualStart > 0 &&
      !text[actualStart - 1].isWhitespace()
    ) {
      actualStart--
    }

    // Expand forward to find the end of the last affected word
    while (
      actualEndExclusive < text.length &&
      !text[actualEndExclusive].isWhitespace()
    ) {
      actualEndExclusive++
    }

    if (actualStart >= actualEndExclusive) {
      return emptyList()
    }

    val affectedWords = mutableListOf<TextRange>()
    var wordStart: Int? = null

    for (index in actualStart until actualEndExclusive) {
      if (text[index].isWhitespace()) {
        val startIndex = wordStart
        if (startIndex != null) {
          affectedWords.add(
            TextRange(
              text.subSequence(startIndex, index).toString(),
              startIndex,
              index,
            ),
          )
          wordStart = null
        }
      } else if (wordStart == null) {
        wordStart = index
      }
    }

    val startIndex = wordStart
    if (startIndex != null) {
      affectedWords.add(
        TextRange(
          text.subSequence(startIndex, actualEndExclusive).toString(),
          startIndex,
          actualEndExclusive,
        ),
      )
    }

    return affectedWords
  }

  fun detectAllLinks() {
    val editable = view.editableText
    val text = editable.toString()

    // Remove existing link spans
    editable.removeSpans(0, editable.length, EnrichedLinkSpan::class.java)

    // Detect links using our URL_REGEX
    for (match in URL_REGEX.findAll(text)) {
      val start = match.range.first
      val end = match.range.last + 1 // IntRange is inclusive

      val url = match.value
      val span = EnrichedLinkSpan(url, view.htmlStyle)
      val (safeStart, safeEnd) = editable.getSafeSpanBoundaries(start, end)

      editable.setSpan(
        span,
        safeStart,
        safeEnd,
        Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
      )
    }
  }

  private fun getWordAtIndex(
    text: CharSequence,
    index: Int,
    affectedWords: List<TextRange>,
  ): TextRange? {
    if (index < 0) return null

    val safeIndex = index.coerceIn(0, text.length)
    val affectedWord = affectedWords.firstOrNull { safeIndex in it.start..it.end }
    if (affectedWord != null) {
      return affectedWord
    }

    var start = safeIndex
    var end = safeIndex

    while (start > 0 && !Character.isWhitespace(text[start - 1])) {
      start--
    }

    while (end < text.length && !Character.isWhitespace(text[end])) {
      end++
    }

    if (start == end) {
      return TextRange("", safeIndex, safeIndex)
    }

    return TextRange(text.subSequence(start, end).toString(), start, end)
  }

  private fun canLinkBeApplied(): Boolean {
    val mergingConfig = EnrichedSpans.getMergingConfigForStyle(TextStyle.LINK, view.htmlStyle) ?: return true
    val conflictingStyles = mergingConfig.conflictingStyles
    val blockingStyles = mergingConfig.blockingStyles

    for (style in blockingStyles) {
      if (view.spanState.getStart(style) != null) return false
    }

    for (style in conflictingStyles) {
      if (view.spanState.getStart(style) != null) return false
    }

    return true
  }

  private fun afterTextChangedLinks(
    editStart: Int,
    editEnd: Int,
    affectedWords: List<TextRange>,
  ) {
    // Do not detect link if it's applied manually
    if (isSettingLinkSpan || !canLinkBeApplied()) return

    val editable = view.editableText
    // If user inserted a newline right after a link, don't touch spans.
    if (isNewlineInsertedAtEndOfSpan(editable, editStart, editEnd, EnrichedLinkSpan::class.java)) return

    if (affectedWords.isEmpty()) return

    val affectedStart = affectedWords.first().start
    val affectedEnd = affectedWords.last().end

    // Remove existing link spans in affected range
    val spans =
      editable
        .getSpans(
          affectedStart,
          affectedEnd,
          EnrichedLinkSpan::class.java,
        ).filter {
          !it.isManual
        }
    editable.removeSpans(spans)

    for (affectedWord in affectedWords) {
      var word = affectedWord.text
      var wordStart = affectedWord.start

      // Do not include zero-width space in link detection
      if (word.startsWith(Strings.ZERO_WIDTH_SPACE_CHAR)) {
        word = word.substring(1)
        wordStart += 1
      }

      // Detect links inside the word using URL_REGEX
      for (match in URL_REGEX.findAll(word)) {
        val linkStart = match.range.first
        val linkEnd = match.range.last + 1 // IntRange is inclusive; convert to exclusive end index

        val spanStart = wordStart + linkStart
        val spanEnd = wordStart + linkEnd

        val span = EnrichedLinkSpan(match.value, view.htmlStyle)
        val (safeStart, safeEnd) =
          editable.getSafeSpanBoundaries(spanStart, spanEnd)

        editable.setSpan(
          span,
          safeStart,
          safeEnd,
          Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
        )
      }
    }
  }

  private fun afterTextChangedMentions(
    s: CharSequence,
    startCursorPosition: Int,
    endCursorPosition: Int,
    affectedWords: List<TextRange>,
  ) {
    val mentionHandler = view.mentionHandler

    val editable = view.editableText
    if (isNewlineInsertedAtEndOfSpan(editable, startCursorPosition, endCursorPosition, EnrichedMentionSpan::class.java)) return

    val currentWord = getWordAtIndex(s, endCursorPosition, affectedWords) ?: return
    val indicatorsPattern = mentionIndicators.joinToString("|") { Regex.escape(it) }
    val mentionIndicatorRegex = Regex("^($indicatorsPattern)")
    val mentionRegex = Regex("^($indicatorsPattern)\\w*")

    editable.removeSpans(currentWord.start, currentWord.end, EnrichedMentionSpan::class.java)

    var indicator: String
    var finalStart: Int
    val finalEnd = currentWord.end

    // No mention in the current word, check previous one
    if (!mentionRegex.matches(currentWord.text)) {
      val previousWord = getWordAtIndex(editable, currentWord.start - 1, affectedWords)

      // No previous word -> no mention to be detected
      if (previousWord == null) {
        mentionHandler.endMention()
        return
      }

      // Previous word is not a mention -> end mention
      if (!mentionRegex.matches(previousWord.text)) {
        mentionHandler.endMention()
        return
      }

      // Previous word is a mention -> use it
      finalStart = previousWord.start
      indicator = mentionIndicatorRegex.find(previousWord.text)?.value ?: ""
    } else {
      // Current word is a mention -> use it
      finalStart = currentWord.start
      indicator = mentionIndicatorRegex.find(currentWord.text)?.value ?: ""
    }

    // Extract text without indicator
    val text = editable.subSequence(finalStart, finalEnd).toString().replaceFirst(indicator, "")

    // Means we are starting mention
    if (text.isEmpty()) {
      mentionStart = finalStart
    }

    mentionHandler.onMention(indicator, text)
  }

  private fun <T : EnrichedSpan> isNewlineInsertedAtEndOfSpan(
    editable: Editable,
    editStart: Int,
    editEnd: Int,
    clazz: Class<T>,
  ): Boolean {
    // insertion of exactly one char
    if (editEnd != editStart + 1) return false
    if (editStart < 0 || editStart >= editable.length) return false

    val insertedChar = editable[editStart]
    if (insertedChar != Strings.NEWLINE) return false

    // If there is any span span whose END is exactly at editStart, then newline was inserted
    // at the boundary right after the link -> do nothing.
    val lookupStart = max(0, editStart - 1)
    val spans = editable.getSpans(lookupStart, editStart, clazz)

    return spans.any { span -> editable.getSpanEnd(span) == editStart }
  }

  fun afterTextChanged(event: TextChangedEvent) {
    val affectedWords =
      getAffectedWords(
        event.text,
        event.startCursorPosition,
        event.endCursorPosition,
      )

    afterTextChangedLinks(event.startCursorPosition, event.endCursorPosition, affectedWords)
    afterTextChangedMentions(event.text, event.startCursorPosition, event.endCursorPosition, affectedWords)
  }

  fun setImageSpan(
    src: String,
    width: Float,
    height: Float,
  ) {
    val editable = view.editableText
    val (start, originalEnd) = view.selection.getInlineSelection()

    if (start == originalEnd) {
      editable.insert(start, "\uFFFC")
    } else {
      editable.removeSpans(start, originalEnd, EnrichedImageSpan::class.java)

      editable.replace(start, originalEnd, "\uFFFC")
    }

    val (imageStart, imageEnd) = editable.getSafeSpanBoundaries(start, start + 1)
    val span = EnrichedImageSpan.createEnrichedImageSpan(src, width.toInt(), height.toInt())
    span.observeAsyncDrawableLoaded(view.text)

    editable.setSpan(span, imageStart, imageEnd, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
  }

  fun startMention(indicator: String) {
    val selection = view.selection

    val editable = view.editableText
    val (start, end) = selection.getInlineSelection()

    if (start == end) {
      editable.insert(start, indicator)
    } else {
      editable.replace(start, end, indicator)
    }
  }

  private fun removeMentionSpans(
    editable: Editable,
    start: Int,
    end: Int,
  ) = editable.removeSpans(start, end, EnrichedMentionSpan::class.java)

  private fun insertMentionAtSelection(
    editable: Editable,
    span: EnrichedMentionSpan,
    selectionStart: Int,
    selectionEnd: Int,
    text: String,
  ) {
    val insertText = "$text "

    if (selectionStart == selectionEnd) {
      editable.insert(selectionStart, insertText)
    } else {
      editable.replace(selectionStart, selectionEnd, insertText)
    }

    val spanStart = selectionStart
    val spanEnd = selectionStart + text.length
    val (safeStart, safeEnd) =
      editable.getSafeSpanBoundaries(spanStart, spanEnd)

    editable.setSpan(span, safeStart, safeEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)

    view.setSelection(spanEnd + 1)
    view.selection.validateStyles()
    view.mentionHandler.reset()
    mentionStart = null
  }

  private fun replaceMentionFromStart(
    editable: Editable,
    span: EnrichedMentionSpan,
    start: Int,
    selectionEnd: Int,
    text: String,
  ) {
    view.transactionManager.runTransaction {
      val insertedMention = SpannableStringBuilder(text)
      insertedMention.setSpan(span, 0, text.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)

      val spanEnd = start + text.length
      val (safeStart, safeEnd) =
        editable.getSafeSpanBoundaries(start, spanEnd)

      val hasSpace = editable.length > safeEnd && editable[safeEnd].isWhitespace()
      if (!hasSpace) {
        insertedMention.insert(text.length, Strings.SPACE_STRING)
      }

      editable.replace(safeStart, selectionEnd, insertedMention)
    }

    view.mentionHandler.reset()
    view.selection.validateStyles()
    mentionStart = null
  }

  fun setMentionSpan(
    indicator: String,
    text: String,
    type: String,
    attributes: Map<String, String>,
  ) {
    val selection = view.selection
    val editable = view.editableText
    val (selectionStart, selectionEnd) = selection.getInlineSelection()

    removeMentionSpans(editable, selectionStart, selectionEnd)

    val span = EnrichedMentionSpan(text, indicator, type, attributes, view.htmlStyle)
    val start = mentionStart

    if (start == null) {
      insertMentionAtSelection(editable, span, selectionStart, selectionEnd, text)
      return
    }

    replaceMentionFromStart(editable, span, start, selectionEnd, text)
  }

  fun getStyleRange(): Pair<Int, Int> = view.selection.getInlineSelection()

  fun removeStyle(
    name: TextStyle,
    start: Int,
    end: Int,
  ): Boolean {
    val config = EnrichedSpans.parametrizedStyles[name] ?: return false
    return removeSpansForRange(view.editableText, start, end, config.clazz)
  }

  companion object {
    val URL_REGEX =
      Regex(
        """^(https?|ftp)://""" +
          """((([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,})|""" + // domain
          """(\d{1,3}(\.\d{1,3}){3}))""" + // IPv4
          """(:\d{1,5})?""" + // port
          """(/[-a-zA-Z0-9@:%_+.~#?&/=]*)?$""",
        RegexOption.IGNORE_CASE,
      )

    data class TextRange(
      val text: String,
      val start: Int,
      val end: Int,
    )
  }
}
