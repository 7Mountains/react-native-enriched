package com.swmansion.enriched.parser

import android.graphics.Color
import android.text.Editable
import android.text.Spannable
import android.text.SpannableStringBuilder
import android.text.Spanned
import androidx.core.graphics.toColorInt
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.constants.HtmlTags
import com.swmansion.enriched.constants.Strings
import com.swmansion.enriched.spans.EnrichedAlignmentSpan
import com.swmansion.enriched.spans.EnrichedBlockQuoteSpan
import com.swmansion.enriched.spans.EnrichedBoldSpan
import com.swmansion.enriched.spans.EnrichedChecklistSpan
import com.swmansion.enriched.spans.EnrichedCodeBlockSpan
import com.swmansion.enriched.spans.EnrichedColoredSpan
import com.swmansion.enriched.spans.EnrichedContentSpan
import com.swmansion.enriched.spans.EnrichedH1Span
import com.swmansion.enriched.spans.EnrichedH2Span
import com.swmansion.enriched.spans.EnrichedH3Span
import com.swmansion.enriched.spans.EnrichedH4Span
import com.swmansion.enriched.spans.EnrichedH5Span
import com.swmansion.enriched.spans.EnrichedH6Span
import com.swmansion.enriched.spans.EnrichedHorizontalRuleSpan
import com.swmansion.enriched.spans.EnrichedImageSpan.Companion.createEnrichedImageSpan
import com.swmansion.enriched.spans.EnrichedInlineCodeSpan
import com.swmansion.enriched.spans.EnrichedItalicSpan
import com.swmansion.enriched.spans.EnrichedLinkSpan
import com.swmansion.enriched.spans.EnrichedMentionSpan
import com.swmansion.enriched.spans.EnrichedOrderedListSpan
import com.swmansion.enriched.spans.EnrichedStrikeThroughSpan
import com.swmansion.enriched.spans.EnrichedUnderlineSpan
import com.swmansion.enriched.spans.EnrichedUnorderedListSpan
import com.swmansion.enriched.spans.interfaces.EnrichedInlineSpan
import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.styles.HtmlStyle
import org.xml.sax.Attributes
import org.xml.sax.ContentHandler
import org.xml.sax.InputSource
import org.xml.sax.Locator
import org.xml.sax.SAXException
import org.xml.sax.XMLReader
import java.io.IOException
import java.io.StringReader

class HtmlToSpannedConverter(
  private val mSource: String?,
  private val mStyle: HtmlStyle,
  private val mImageGetter: EnrichedParser.ImageGetter?,
  private val parser: XMLReader,
  private val textInputView: EnrichedTextInputView,
) : ContentHandler {
  private val mSpannableStringBuilder: SpannableStringBuilder = SpannableStringBuilder()
  private var currentListItemIndex = 0
  private var isInOrderedList = false
  private var isEmptyTag = false
  private val tagsStack = ArrayDeque<TagContext>()

  fun convert(): Spanned {
    parser.contentHandler = this
    try {
      parser.parse(InputSource(StringReader(mSource)))
    } catch (e: IOException) {
      // We are reading from a string. There should not be IO problems.
      throw RuntimeException(e)
    } catch (e: SAXException) {
      // TagSoup doesn't throw parse exceptions.
      throw RuntimeException(e)
    }
    return mSpannableStringBuilder
  }

  private fun pushTag(
    tag: String,
    attributes: Attributes?,
  ) {
    tagsStack.addLast(
      TagContext(
        tag = tag,
        start = mSpannableStringBuilder.length,
        attributes = attributes,
      ),
    )
  }

  private fun popTag(tag: String): TagContext? {
    val last = tagsStack.lastOrNull()
    if (last != null && last.tag == tag) {
      return tagsStack.removeLast()
    }

    // fallback if we get some trash
    for (i in tagsStack.lastIndex downTo 0) {
      val ctx = tagsStack[i]
      if (ctx.tag == tag) {
        tagsStack.removeAt(i)
        return ctx
      }
    }
    return null
  }

  private fun applyInline(
    ctx: TagContext,
    createSpan: (Attributes?) -> EnrichedInlineSpan,
  ) {
    val end = mSpannableStringBuilder.length
    if (ctx.start != end) {
      mSpannableStringBuilder.setSpan(
        createSpan(ctx.attributes),
        ctx.start,
        end,
        Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
      )
    }
  }

  private fun handleStartTag(
    tag: String?,
    attributes: Attributes?,
    htmlStyle: HtmlStyle,
  ) {
    when (tag) {
      HtmlTags.BREAK_LINE -> {
        // no-op, handled on close
        return
      }

      HtmlTags.BOLD,
      HtmlTags.ITALIC,
      HtmlTags.UNDERLINE,
      HtmlTags.STRIKE,
      HtmlTags.STRIKE_THROUGH,
      HtmlTags.CODE_INLINE,
      -> {
        pushTag(tag, attributes)
        return
      }

      HtmlTags.H1,
      HtmlTags.H2,
      HtmlTags.H3,
      HtmlTags.H4,
      HtmlTags.H5,
      HtmlTags.H6,
      HtmlTags.PARAGRAPH,
      HtmlTags.UNORDERED_LIST,
      HtmlTags.BLOCK_QUOTE,
      HtmlTags.CODE_BLOCK,
      HtmlTags.ORDERED_LIST,
      HtmlTags.CHECKLIST,
      -> {
        isInOrderedList = tag == HtmlTags.ORDERED_LIST
        currentListItemIndex = 0
        isEmptyTag = true
        startParagraph(mSpannableStringBuilder, tag, attributes)
        return
      }

      HtmlTags.LIST_ITEM -> {
        isEmptyTag = true
        startListItem(mSpannableStringBuilder, tag, attributes)
        return
      }

      HtmlTags.LINK -> {
        pushTag(HtmlTags.LINK, attributes)
        return
      }

      HtmlTags.IMAGE -> {
        startImg(mSpannableStringBuilder, attributes, mImageGetter)
        return
      }

      HtmlTags.MENTION -> {
        pushTag(HtmlTags.MENTION, attributes)
        return
      }

      HtmlTags.HORIZONTAL_RULE -> {
        addHr(mSpannableStringBuilder, htmlStyle, isEmptyTag)
        return
      }

      HtmlTags.CONTENT -> {
        addContent(mSpannableStringBuilder, attributes, htmlStyle, isEmptyTag)
        return
      }

      HtmlTags.FONT -> {
        pushTag(HtmlTags.FONT, attributes)
        return
      }

      else -> {
        // unknown tag → ignore
        return
      }
    }
  }

  private fun handleEndTag(tag: String?) {
    when (tag) {
      HtmlTags.BREAK_LINE -> {
        handleBr(mSpannableStringBuilder)
        return
      }

      HtmlTags.PARAGRAPH -> {
        endParagraphTag(mSpannableStringBuilder, tag, isEmptyTag)
        return
      }

      HtmlTags.UNORDERED_LIST, HtmlTags.ORDERED_LIST -> {
        val ctx = popTag(tag) ?: return

        var end = mSpannableStringBuilder.length

        if (end > ctx.start && mSpannableStringBuilder[end - 1] == Strings.NEWLINE) {
          end--
        }
        addAlignmentSpanIfNeeded(mSpannableStringBuilder, ctx.start, end, ctx.attributes)
        return
      }

      HtmlTags.LIST_ITEM -> {
        endListItem(mSpannableStringBuilder)
        return
      }

      HtmlTags.BOLD -> {
        val ctx = popTag(tag) ?: return
        applyInline(ctx) { EnrichedBoldSpan() }
        return
      }

      HtmlTags.ITALIC -> {
        val ctx = popTag(tag) ?: return
        applyInline(ctx) { EnrichedItalicSpan() }
        return
      }

      HtmlTags.UNDERLINE -> {
        val ctx = popTag(tag) ?: return
        applyInline(ctx) { EnrichedUnderlineSpan() }
        return
      }

      HtmlTags.STRIKE, HtmlTags.STRIKE_THROUGH -> {
        val ctx = popTag(tag) ?: return
        applyInline(ctx) { EnrichedStrikeThroughSpan() }
        return
      }

      HtmlTags.CODE_INLINE -> {
        val ctx = popTag(tag) ?: return
        applyInline(ctx) { EnrichedInlineCodeSpan(mStyle) }
        return
      }

      HtmlTags.BLOCK_QUOTE -> {
        endParagraphTag(
          mSpannableStringBuilder,
          tag,
          EnrichedBlockQuoteSpan(mStyle),
          isEmptyTag,
        )
        return
      }

      HtmlTags.CODE_BLOCK -> {
        endParagraphTag(
          mSpannableStringBuilder,
          tag,
          EnrichedCodeBlockSpan(mStyle),
          isEmptyTag,
        )
        return
      }

      HtmlTags.LINK -> {
        val ctx = popTag(tag) ?: return
        val href = ctx.attributes?.getValue("", "href") ?: return

        applyInline(ctx) {
          EnrichedLinkSpan(href, mStyle)
        }
        return
      }

      HtmlTags.H1 -> {
        endParagraphTag(
          mSpannableStringBuilder,
          tag,
          EnrichedH1Span(mStyle),
          isEmptyTag,
        )
      }

      HtmlTags.H2 -> {
        endParagraphTag(
          mSpannableStringBuilder,
          tag,
          EnrichedH2Span(mStyle),
          isEmptyTag,
        )
      }

      HtmlTags.H3 -> {
        endParagraphTag(
          mSpannableStringBuilder,
          tag,
          EnrichedH3Span(mStyle),
          isEmptyTag,
        )
      }

      HtmlTags.H4 -> {
        endParagraphTag(
          mSpannableStringBuilder,
          tag,
          EnrichedH4Span(mStyle),
          isEmptyTag,
        )
      }

      HtmlTags.H5 -> {
        endParagraphTag(
          mSpannableStringBuilder,
          tag,
          EnrichedH5Span(mStyle),
          isEmptyTag,
        )
      }

      HtmlTags.H6 -> {
        endParagraphTag(
          mSpannableStringBuilder,
          tag,
          EnrichedH6Span(mStyle),
          isEmptyTag,
        )
      }

      HtmlTags.MENTION -> {
        val ctx = popTag(tag) ?: return
        val text = ctx.attributes?.getValue("", "text") ?: return
        val indicator = ctx.attributes.getValue("", "indicator") ?: ""

        val attrs = mutableMapOf<String, String>()
        ctx.attributes.let { a ->
          for (i in 0 until a.length) {
            val name = a.getLocalName(i)
            if (name != "text" && name != "indicator") {
              attrs[name] = a.getValue(i)
            }
          }
        }

        applyInline(ctx) {
          EnrichedMentionSpan(text, indicator, attrs, mStyle)
        }
        return
      }

      HtmlTags.CHECKLIST -> {
        val isChecked = popTag(tag)?.attributes?.getValue("", "checked") == "true"
        endParagraphTag(
          mSpannableStringBuilder,
          tag,
          EnrichedChecklistSpan(mStyle, isChecked),
          isEmptyTag,
        )
        return
      }

      HtmlTags.FONT -> {
        val ctx = popTag(tag) ?: return
        val colorValue = ctx.attributes?.getValue("", "color") ?: return
        val color = parseCssColor(colorValue)

        applyInline(ctx) {
          EnrichedColoredSpan(color)
        }
        return
      }

      else -> {
        // Unknown tag, ignore
        return
      }
    }
  }

  private fun startListItem(
    text: Editable,
    tag: String,
    attributes: Attributes?,
  ) {
    if (currentListItemIndex != 0) {
      appendNewlines(text, 1)
    }

    currentListItemIndex++

    pushTag(tag, attributes)
  }

  private fun endListItem(text: Editable) {
    val ctx = popTag(HtmlTags.LIST_ITEM) ?: return

    var end = text.length
    if (isEmptyTag) {
      text.append(Strings.ZERO_WIDTH_SPACE_CHAR)
      end++
    }

    if (end > ctx.start && text[end - 1] == Strings.NEWLINE) {
      end--
    }

    val span = if (isInOrderedList) EnrichedOrderedListSpan(currentListItemIndex, mStyle) else EnrichedUnorderedListSpan(mStyle)

    text.setSpan(span, ctx.start, end, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
    appendNewlines(text, 1)
  }

  private fun startParagraph(
    text: Editable,
    tag: String,
    attributes: Attributes?,
  ) {
    appendNewlines(text, 1)
    pushTag(tag, attributes)
  }

  private fun endParagraphTag(
    text: Editable,
    tag: String,
    isEmptyTag: Boolean,
  ) {
    val ctx = popTag(tag) ?: return

    var end = text.length
    if (isEmptyTag) {
      text.append(Strings.ZERO_WIDTH_SPACE_CHAR)
      end++
    }

    if (end > ctx.start && text[end - 1] == Strings.NEWLINE) {
      end--
    }
    addAlignmentSpanIfNeeded(text, ctx.start, end, ctx.attributes)
    appendNewlines(text, 1)
  }

  private fun endParagraphTag(
    text: Editable,
    tag: String,
    span: EnrichedSpan,
    isEmptyTag: Boolean,
  ) {
    val ctx = popTag(tag) ?: return

    var end = text.length
    if (isEmptyTag) {
      text.append(Strings.ZERO_WIDTH_SPACE_CHAR)
      end++
    }

    if (end > ctx.start && text[end - 1] == Strings.NEWLINE) {
      end--
    }

    val isSimpleParagraph = ctx.tag == HtmlTags.PARAGRAPH

    if (isSimpleParagraph) {
      addAlignmentSpanIfNeeded(text, ctx.start, end, ctx.attributes)
    } else {
      addAlignmentSpanIfNeeded(text, ctx.start, end, ctx.attributes)
      text.setSpan(span, ctx.start, end, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
    }

    appendNewlines(text, 1)
  }

  private fun addAlignmentSpanIfNeeded(
    text: Editable,
    start: Int,
    end: Int,
    attributes: Attributes?,
  ) {
    if (attributes == null) return

    val alignmentString = attributes.getValue("", "alignment")
    if (alignmentString == null) return

    text.setSpan(
      EnrichedAlignmentSpan(alignmentString),
      start,
      end,
      Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
    )
  }

  private fun addContent(
    editable: Editable,
    attributes: Attributes?,
    htmlStyle: HtmlStyle,
    isEmptyTag: Boolean,
  ) {
    if (attributes == null) {
      return
    }

    val text = attributes.getValue("", "text")
    val type = attributes.getValue("", "type")
    val src = attributes.getValue("", "src")

    val attributesMap: MutableMap<String, String> = HashMap()
    for (i in 0..<attributes.length) {
      val localName = attributes.getLocalName(i)

      if (("text" != localName) && ("type" != localName) && ("src" != localName)) {
        attributesMap.put(localName, attributes.getValue(i))
      }
    }
    if (isEmptyTag) {
      editable.append(Strings.NEWLINE)
    }
    val builder = SpannableStringBuilder()
    builder.append(Strings.MAGIC_CHAR)
    val span =
      EnrichedContentSpan.Companion.createEnrichedContentSpan(
        text,
        type,
        src,
        attributesMap,
        htmlStyle,
      )
    span.attachTo(textInputView)
    builder.setSpan(span, 0, 1, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
    editable.append(builder)
    editable.append(Strings.NEWLINE)
  }

  override fun setDocumentLocator(locator: Locator?) {}

  override fun startDocument() {}

  override fun endDocument() {}

  override fun startPrefixMapping(
    prefix: String?,
    uri: String?,
  ) {
  }

  override fun endPrefixMapping(prefix: String?) {}

  override fun startElement(
    uri: String?,
    localName: String?,
    qName: String?,
    attributes: Attributes?,
  ) {
    handleStartTag(localName, attributes, mStyle)
  }

  override fun endElement(
    uri: String?,
    localName: String?,
    qName: String?,
  ) {
    handleEndTag(localName)
  }

  override fun characters(
    ch: CharArray,
    start: Int,
    length: Int,
  ) {
    val sb = StringBuilder()
    if (length > 0) isEmptyTag = false

    /*
     * Ignore whitespace that immediately follows other whitespace;
     * newlines count as spaces.
     */
    for (i in 0..<length) {
      val c = ch[i + start]
      if (c == Strings.SPACE_CHAR || c == Strings.NEWLINE) {
        val prev: Char
        var len = sb.length
        if (len == 0) {
          len = mSpannableStringBuilder.length
          prev =
            if (len == 0) {
              Strings.NEWLINE
            } else {
              mSpannableStringBuilder[len - 1]
            }
        } else {
          prev = sb[len - 1]
        }
        if (prev != Strings.SPACE_CHAR && prev != Strings.NEWLINE) {
          sb.append(Strings.SPACE_CHAR)
        }
      } else {
        sb.append(c)
      }
    }
    mSpannableStringBuilder.append(sb)
  }

  override fun ignorableWhitespace(
    ch: CharArray?,
    start: Int,
    length: Int,
  ) {
  }

  override fun processingInstruction(
    target: String?,
    data: String?,
  ) {
  }

  private data class TagContext(
    val tag: String,
    val start: Int,
    val attributes: Attributes?,
  )

  override fun skippedEntity(name: String?) {}

  companion object {
    private fun appendNewlines(
      text: Editable,
      minNewline: Int,
    ) {
      val len = text.length
      if (len == 0) {
        return
      }
      var existingNewlines = 0
      var i = len - 1
      while (i >= 0 && text[i] == Strings.NEWLINE) {
        existingNewlines++
        i--
      }
      for (j in existingNewlines..<minNewline) {
        text.append(Strings.NEWLINE)
      }
    }

    private fun handleBr(text: Editable) {
      text.append(Strings.NEWLINE)
    }

    private fun addHr(
      text: Editable,
      htmlStyle: HtmlStyle,
      isEmptyTag: Boolean,
    ) {
      if (isEmptyTag) {
        text.append(Strings.NEWLINE)
      }
      val builder = SpannableStringBuilder(Strings.MAGIC_STRING)
      builder.setSpan(
        EnrichedHorizontalRuleSpan(htmlStyle),
        0,
        1,
        Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
      )
      text.append(builder)
      text.append(Strings.NEWLINE)
    }

    private fun startImg(
      text: Editable,
      attributes: Attributes?,
      img: EnrichedParser.ImageGetter?,
    ) {
      if (attributes == null) {
        return
      }
      val src = attributes.getValue("", "src")
      val width = attributes.getValue("", "width")
      val height = attributes.getValue("", "height")

      val len = text.length
      val span =
        createEnrichedImageSpan(
          src,
          width.toInt(),
          height.toInt(),
        )
      text.append(Strings.MAGIC_CHAR)
      text.setSpan(span, len, text.length, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
    }

    private fun parseCssColor(css: String?): Int {
      var css = css
      if (css == null) return Color.BLACK

      css = css.trim { it <= Strings.SPACE_CHAR }

      try {
        return css.toColorInt()
      } catch (ignore: Exception) {
      }

      if (css.startsWith("rgb(")) {
        val parts: Array<String?> =
          css
            .substring(4, css.length - 1)
            .split(",".toRegex())
            .dropLastWhile { it.isEmpty() }
            .toTypedArray()
        val r = parts[0]!!.trim { it <= Strings.SPACE_CHAR }.toInt()
        val g = parts[1]!!.trim { it <= Strings.SPACE_CHAR }.toInt()
        val b = parts[2]!!.trim { it <= Strings.SPACE_CHAR }.toInt()
        return Color.rgb(r, g, b)
      }

      if (css.startsWith("rgba(")) {
        val parts: Array<String?> =
          css
            .substring(5, css.length - 1)
            .split(",".toRegex())
            .dropLastWhile { it.isEmpty() }
            .toTypedArray()
        val r = parts[0]!!.trim { it <= Strings.SPACE_CHAR }.toInt()
        val g = parts[1]!!.trim { it <= Strings.SPACE_CHAR }.toInt()
        val b = parts[2]!!.trim { it <= Strings.SPACE_CHAR }.toInt()
        val a = parts[3]!!.trim { it <= Strings.SPACE_CHAR }.toFloat()
        return Color.argb((a * 255).toInt(), r, g, b)
      }

      return Color.BLACK
    }
  }
}
