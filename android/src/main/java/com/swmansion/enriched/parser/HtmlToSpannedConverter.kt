package com.swmansion.enriched.parser

import android.graphics.Color
import android.text.Editable
import android.text.Layout
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
import com.swmansion.enriched.styles.HtmlStyle
import com.swmansion.enriched.utils.toStringName
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

    // We don't use ZeroWidthSpaceSpan in the final output, so we can remove them here.
    // Fix flags and range for paragraph-type markup.
//    Object[] obj =
//        mSpannableStringBuilder.getSpans(0, mSpannableStringBuilder.length(), ParagraphStyle.class);
//    for (int i = 0; i < obj.length; i++) {
//      int start = mSpannableStringBuilder.getSpanStart(obj[i]);
//      int end = mSpannableStringBuilder.getSpanEnd(obj[i]);
//      // If the last line of the range is blank, back off by one.
//      if (end - 2 >= 0) {
//        if (mSpannableStringBuilder.charAt(end - 1) == Strings.NEWLINE
//            && mSpannableStringBuilder.charAt(end - 2) == Strings.NEWLINE) {
//          end--;
//        }
//      }
//      if (end == start) {
//        mSpannableStringBuilder.removeSpan(obj[i]);
//      } else {
//        // TODO: verify if Spannable.SPAN_EXCLUSIVE_EXCLUSIVE does not break anything.
//        // Previously it was SPAN_PARAGRAPH. I've changed that in order to fix ranges for list
//        // items.
//        mSpannableStringBuilder.setSpan(obj[i], start, end, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
//      }
//    }
    return mSpannableStringBuilder
  }

  private fun handleStartTag(
    tag: String?,
    attributes: Attributes?,
    htmlStyle: HtmlStyle,
  ) {
    if (tag == null) return
    when (tag.lowercase()) {
      HtmlTags.BREAK_LINE -> {
        // no-op, handled on close
        return
      }

      HtmlTags.PARAGRAPH -> {
        isEmptyTag = true
        startBlockElement(mSpannableStringBuilder, attributes)
        return
      }

      HtmlTags.UNORDERED_LIST -> {
        isInOrderedList = false
        startBlockElement(mSpannableStringBuilder, attributes)
        return
      }

      HtmlTags.ORDERED_LIST -> {
        isInOrderedList = true
        currentOrderedListItemIndex = 0
        startBlockElement(mSpannableStringBuilder, attributes)
        return
      }

      HtmlTags.LIST_ITEM -> {
        isEmptyTag = true
        startLi(mSpannableStringBuilder)
        return
      }

      HtmlTags.BOLD -> {
        start(mSpannableStringBuilder, Bold())
        return
      }

      HtmlTags.ITALIC -> {
        start(mSpannableStringBuilder, Italic())
        return
      }

      HtmlTags.UNDERLINE -> {
        start(mSpannableStringBuilder, Underline())
        return
      }

      HtmlTags.STRIKE_THROUGH, HtmlTags.STRIKE -> {
        start(mSpannableStringBuilder, Strikethrough())
        return
      }

      HtmlTags.BLOCK_QUOTE -> {
        isEmptyTag = true
        startBlockquote(mSpannableStringBuilder, attributes)
        return
      }

      HtmlTags.CODE_BLOCK -> {
        isEmptyTag = true
        startCodeBlock(mSpannableStringBuilder, attributes)
        return
      }

      HtmlTags.CODE_INLINE -> {
        start(mSpannableStringBuilder, Code())
        return
      }

      HtmlTags.LINK -> {
        startA(mSpannableStringBuilder, attributes)
        return
      }

      HtmlTags.H1 -> {
        startHeading(mSpannableStringBuilder, 1, attributes)
        return
      }

      HtmlTags.H2 -> {
        startHeading(mSpannableStringBuilder, 2, attributes)
        return
      }

      HtmlTags.H3 -> {
        startHeading(mSpannableStringBuilder, 3, attributes)
        return
      }

      HtmlTags.H4 -> {
        startHeading(mSpannableStringBuilder, 4, attributes)
        return
      }

      HtmlTags.H5 -> {
        startHeading(mSpannableStringBuilder, 5, attributes)
        return
      }

      HtmlTags.H6 -> {
        startHeading(mSpannableStringBuilder, 6, attributes)
        return
      }

      HtmlTags.IMAGE -> {
        startImg(mSpannableStringBuilder, attributes, mImageGetter)
        return
      }

      HtmlTags.MENTION -> {
        startMention(mSpannableStringBuilder, attributes)
        return
      }

      HtmlTags.HORIZONTAL_RULE -> {
        addHr(mSpannableStringBuilder, htmlStyle)
        return
      }

      HtmlTags.CONTENT -> {
        addContent(mSpannableStringBuilder, attributes, htmlStyle)
        return
      }

      HtmlTags.CHECKLIST -> {
        isEmptyTag = true
        startChecklist(mSpannableStringBuilder, attributes)
        return
      }

      HtmlTags.FONT -> {
        startFont(mSpannableStringBuilder, attributes)
        return
      }

      else -> {
        // unknown tag → ignore
        return
      }
    }
  }

  private fun handleEndTag(tag: String?) {
    if (tag == null) return

    when (tag.lowercase()) {
      HtmlTags.BREAK_LINE -> {
        handleBr(mSpannableStringBuilder)
        return
      }

      HtmlTags.PARAGRAPH, HtmlTags.UNORDERED_LIST -> {
        endBlockElement(mSpannableStringBuilder)
        return
      }

      HtmlTags.LIST_ITEM -> {
        endLi(mSpannableStringBuilder, mStyle)
        return
      }

      HtmlTags.BOLD -> {
        end(mSpannableStringBuilder, Bold::class.java, EnrichedBoldSpan())
        return
      }

      HtmlTags.ITALIC -> {
        end(mSpannableStringBuilder, Italic::class.java, EnrichedItalicSpan())
        return
      }

      HtmlTags.UNDERLINE -> {
        end(mSpannableStringBuilder, Underline::class.java, EnrichedUnderlineSpan())
        return
      }

      HtmlTags.STRIKE_THROUGH, HtmlTags.STRIKE -> {
        end(mSpannableStringBuilder, Strikethrough::class.java, EnrichedStrikeThroughSpan())
        return
      }

      HtmlTags.BLOCK_QUOTE -> {
        endBlockquote(mSpannableStringBuilder, mStyle)
        return
      }

      HtmlTags.CODE_BLOCK -> {
        endCodeBlock(mSpannableStringBuilder, mStyle)
        return
      }

      HtmlTags.LINK -> {
        endA(mSpannableStringBuilder, mStyle)
        return
      }

      HtmlTags.H1 -> {
        endHeading(mSpannableStringBuilder, mStyle, 1)
        return
      }

      HtmlTags.H2 -> {
        endHeading(mSpannableStringBuilder, mStyle, 2)
        return
      }

      HtmlTags.H3 -> {
        endHeading(mSpannableStringBuilder, mStyle, 3)
        return
      }

      HtmlTags.H4 -> {
        endHeading(mSpannableStringBuilder, mStyle, 4)
        return
      }

      HtmlTags.H5 -> {
        endHeading(mSpannableStringBuilder, mStyle, 5)
        return
      }

      HtmlTags.H6 -> {
        endHeading(mSpannableStringBuilder, mStyle, 6)
        return
      }

      HtmlTags.CODE_INLINE -> {
        end(mSpannableStringBuilder, Code::class.java, EnrichedInlineCodeSpan(mStyle))
        return
      }

      HtmlTags.MENTION -> {
        endMention(mSpannableStringBuilder, mStyle)
        return
      }

      HtmlTags.CHECKLIST -> {
        endCheckList(mSpannableStringBuilder, mStyle)
        return
      }

      HtmlTags.FONT -> {
        endFont(mSpannableStringBuilder)
        return
      }

      else -> {
        // Unknown tag, ignore
        return
      }
    }
  }

  private fun startLi(text: Editable) {
    startBlockElement(text, null)

    if (isInOrderedList) {
      currentOrderedListItemIndex++
      start(text, List(HtmlTags.ORDERED_LIST, currentOrderedListItemIndex))
    } else {
      start(text, List(HtmlTags.UNORDERED_LIST, 0))
    }
  }

  private fun startChecklist(
    text: Editable,
    attributes: Attributes?,
  ) {
    if (attributes == null) {
      return
    }
    val checked = attributes.getValue("checked") == "true"

    startBlockElement(text, attributes)
    start(text, Checklist(checked))
  }

  private fun startBlockquote(
    text: Editable,
    attributes: Attributes?,
  ) {
    startBlockElement(text, attributes)
    start(text, Blockquote())
  }

  private fun startCodeBlock(
    text: Editable,
    attributes: Attributes?,
  ) {
    startBlockElement(text, attributes)
    start(text, CodeBlock())
  }

  private fun addContent(
    editable: Editable,
    attributes: Attributes?,
    htmlStyle: HtmlStyle,
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
    editable.append(Strings.NEWLINE)
    editable.append(builder)
    editable.append(Strings.NEWLINE)
  }

  private fun endA(
    text: Editable,
    style: HtmlStyle,
  ) {
    val h: Href? = getLast(text, Href::class.java)
    if (h != null) {
      if (h.mHref != null) {
        setSpanFromMark(text, h, EnrichedLinkSpan(h.mHref!!, style))
      }
    }
  }

  private fun endMention(
    text: Editable,
    style: HtmlStyle,
  ) {
    val m: Mention? = getLast(text, Mention::class.java)

    if (m == null) return
    if (m.mText == null) return

    setSpanFromMark(text, m, EnrichedMentionSpan(m.mText!!, m.mIndicator, m.mAttributes, style))
  }

  override fun setDocumentLocator(locator: Locator?) {}

  override fun startDocument() {}

  override fun endDocument() {}

  override fun startPrefixMapping(
    prefix: String?,
    uri: String?,
  ) {}

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
        val pred: Char
        var len = sb.length
        if (len == 0) {
          len = mSpannableStringBuilder.length
          if (len == 0) {
            pred = Strings.NEWLINE
          } else {
            pred = mSpannableStringBuilder.get(len - 1)
          }
        } else {
          pred = sb.get(len - 1)
        }
        if (pred != Strings.SPACE_CHAR && pred != Strings.NEWLINE) {
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
  ) {}

  override fun processingInstruction(
    target: String?,
    data: String?,
  ) {}

  override fun skippedEntity(name: String?) {}

  private class H1

  private class H2

  private class H3

  private class H4

  private class H5

  private class H6

  private class Bold

  private class Italic

  private class Underline

  private class Code

  private class CodeBlock

  private class Strikethrough

  private class Blockquote

  private class List(
    var mType: String,
    var mIndex: Int,
  )

  private class Checklist(
    var mChecked: Boolean,
  )

  private class Font(
    var color: Int,
  )

  private class Mention(
    var mIndicator: String,
    var mText: String?,
    var mAttributes: MutableMap<String, String>,
  )

  private class Href(
    var mHref: String?,
  )

  private class Newline(
    val numNewLines: Int,
  )

  private class Alignment(
    val mAlignment: Layout.Alignment,
  )

  companion object {
    private var currentOrderedListItemIndex = 0
    private var isInOrderedList = false
    private var isEmptyTag = false

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

    private fun startBlockElement(
      text: Editable,
      attributes: Attributes?,
    ) {
      appendNewlines(text, 1)
      start(text, Newline(1))
      startAlignment(text, attributes)
    }

    private fun endBlockElementWithoutAlignment(text: Editable) {
      val n: Newline? = getLast(text, Newline::class.java)
      if (n != null) {
        appendNewlines(text, n.numNewLines)
        text.removeSpan(n)
      }
    }

    private fun endBlockElement(text: Editable) {
      val n: Newline? = getLast(text, Newline::class.java)
      if (n != null) {
        appendNewlines(text, n.numNewLines)
        text.removeSpan(n)
      }
      endAlignment(text)
    }

    private fun handleBr(text: Editable) {
      text.append('\n')
    }

    private fun endCheckList(
      text: Editable,
      style: HtmlStyle,
    ) {
      endBlockElement(text)
      val last: Checklist? = getLast(text, Checklist::class.java)

      if (last == null) {
        return
      }

      setParagraphSpanFromMark(text, last, EnrichedChecklistSpan(style, last.mChecked))
    }

    private fun endLi(
      text: Editable,
      style: HtmlStyle,
    ) {
      endBlockElementWithoutAlignment(text)

      val l: List? = getLast(text, List::class.java)
      if (l != null) {
        if (l.mType == HtmlTags.ORDERED_LIST) {
          setParagraphSpanFromMark(text, l, EnrichedOrderedListSpan(l.mIndex, style))
        } else {
          setParagraphSpanFromMark(text, l, EnrichedUnorderedListSpan(style))
        }
      }

      endBlockElementWithoutAlignment(text)
    }

    private fun endBlockquote(
      text: Editable,
      style: HtmlStyle,
    ) {
      endBlockElement(text)
      val last: Blockquote? = getLast(text, Blockquote::class.java)
      setParagraphSpanFromMark(text, last, EnrichedBlockQuoteSpan(style))
    }

    private fun endCodeBlock(
      text: Editable,
      style: HtmlStyle,
    ) {
      endBlockElement(text)
      val last: CodeBlock? = getLast(text, CodeBlock::class.java)
      setParagraphSpanFromMark(text, last, EnrichedCodeBlockSpan(style))
    }

    private fun startHeading(
      text: Editable,
      level: Int,
      attributes: Attributes?,
    ) {
      startBlockElement(text, attributes)

      when (level) {
        1 -> start(text, H1())
        2 -> start(text, H2())
        3 -> start(text, H3())
        4 -> start(text, H4())
        5 -> start(text, H5())
        6 -> start(text, H6())
        else -> throw IllegalArgumentException("Unsupported heading level: " + level)
      }
    }

    private fun endHeading(
      text: Editable,
      style: HtmlStyle,
      level: Int,
    ) {
      endBlockElement(text)

      when (level) {
        1 -> {
          val lastH1: H1? = getLast(text, H1::class.java)
          setParagraphSpanFromMark(text, lastH1, EnrichedH1Span(style))
        }

        2 -> {
          val lastH2: H2? = getLast(text, H2::class.java)
          setParagraphSpanFromMark(text, lastH2, EnrichedH2Span(style))
        }

        3 -> {
          val lastH3: H3? = getLast(text, H3::class.java)
          setParagraphSpanFromMark(text, lastH3, EnrichedH3Span(style))
        }

        4 -> {
          val lastH4: H4? = getLast(text, H4::class.java)
          setParagraphSpanFromMark(text, lastH4, EnrichedH4Span(style))
        }

        5 -> {
          val lastH5: H5? = getLast(text, H5::class.java)
          setParagraphSpanFromMark(text, lastH5, EnrichedH5Span(style))
        }

        6 -> {
          val lastH6: H6? = getLast(text, H6::class.java)
          setParagraphSpanFromMark(text, lastH6, EnrichedH6Span(style))
        }

        else -> {
          throw IllegalArgumentException("Unsupported heading level: $level")
        }
      }
    }

    private fun addHr(
      text: Editable,
      htmlStyle: HtmlStyle,
    ) {
      val builder = SpannableStringBuilder()
      text.append(Strings.NEWLINE)
      builder.append(Strings.MAGIC_CHAR)
      builder.setSpan(
        EnrichedHorizontalRuleSpan(htmlStyle),
        0,
        1,
        Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
      )
      text.append(builder)
      text.append(Strings.NEWLINE)
    }

    private fun <T> getLast(
      text: Spanned,
      kind: Class<T>,
    ): T? {
      /*
* This knows that the last returned object from getSpans()
* will be the most recently added.
*/
      val objs = text.getSpans(0, text.length, kind)
      return if (objs.size == 0) {
        null
      } else {
        objs[objs.size - 1]
      }
    }

    private fun setSpanFromMark(
      text: Spannable,
      mark: Any?,
      vararg spans: Any?,
    ) {
      val where = text.getSpanStart(mark)
      text.removeSpan(mark)
      val len = text.length
      if (where != len) {
        for (span in spans) {
          text.setSpan(span, where, len, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        }
      }
    }

    private fun setParagraphSpanFromMark(
      text: Editable,
      mark: Any?,
      vararg spans: Any?,
    ) {
      val where = text.getSpanStart(mark)
      text.removeSpan(mark)
      var len = text.length

      // Block spans require at least one character to be applied.
      if (isEmptyTag) {
        text.append(Strings.ZERO_WIDTH_SPACE_CHAR)
        len++
      }

      // Adjust the end position to exclude the newline character, if present
      if (len > 0 && text.get(len - 1) == Strings.NEWLINE) {
        len--
      }

      if (where != len) {
        for (span in spans) {
          text.setSpan(span, where, len, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        }
      }
    }

    private fun start(
      text: Editable,
      mark: Any?,
    ) {
      val len = text.length
      text.setSpan(mark, len, len, Spannable.SPAN_INCLUSIVE_EXCLUSIVE)
    }

    private fun end(
      text: Editable,
      kind: Class<*>,
      repl: Any,
    ) {
      val obj: Any? = getLast(text, kind)
      if (obj != null) {
        setSpanFromMark(text, obj, repl)
      }
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
      text.append(Strings.SPACE_CHAR)
      text.setSpan(span, len, text.length, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
    }

    private fun startA(
      text: Editable,
      attributes: Attributes?,
    ) {
      if (attributes == null) {
        return
      }
      val href = attributes.getValue("", "href")
      start(text, Href(href))
    }

    private fun startFont(
      text: Editable,
      attributes: Attributes?,
    ) {
      if (attributes == null) {
        return
      }

      val color: Int = parseCssColor(attributes.getValue("", "color"))

      start(text, Font(color))
    }

    private fun endFont(text: Editable) {
      val font: Font? = getLast(text, Font::class.java)

      if (font == null) {
        return
      }

      setSpanFromMark(text, font, EnrichedColoredSpan(font.color))
    }

    private fun startAlignment(
      text: Editable,
      attributes: Attributes?,
    ) {
      if (attributes == null) return

      val alignmentString = attributes.getValue("", "alignment")
      if (alignmentString == null) return

      val alignment =
        when (alignmentString.lowercase()) {
          "center" -> Layout.Alignment.ALIGN_CENTER
          "right" -> Layout.Alignment.ALIGN_OPPOSITE
          "left" -> Layout.Alignment.ALIGN_NORMAL
          else -> null
        }

      if (alignment != null) {
        start(text, Alignment(alignment))
      }
    }

    private fun endAlignment(text: Editable) {
      val mark: Alignment? = getLast(text, Alignment::class.java) ?: return
      if (mark == null) {
        return
      }
      val where = text.getSpanStart(mark)
      text.removeSpan(mark)
      val end = text.length

      text.setSpan(
        EnrichedAlignmentSpan(mark.mAlignment.toStringName()),
        where,
        end,
        Spanned.SPAN_INCLUSIVE_EXCLUSIVE,
      )
    }

    private fun parseCssColor(css: String?): Int {
      var css = css
      if (css == null) return Color.BLACK

      css = css.trim { it <= ' ' }

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
        val r = parts[0]!!.trim { it <= ' ' }.toInt()
        val g = parts[1]!!.trim { it <= ' ' }.toInt()
        val b = parts[2]!!.trim { it <= ' ' }.toInt()
        return Color.rgb(r, g, b)
      }

      if (css.startsWith("rgba(")) {
        val parts: Array<String?> =
          css
            .substring(5, css.length - 1)
            .split(",".toRegex())
            .dropLastWhile { it.isEmpty() }
            .toTypedArray()
        val r = parts[0]!!.trim { it <= ' ' }.toInt()
        val g = parts[1]!!.trim { it <= ' ' }.toInt()
        val b = parts[2]!!.trim { it <= ' ' }.toInt()
        val a = parts[3]!!.trim { it <= ' ' }.toFloat()
        return Color.argb((a * 255).toInt(), r, g, b)
      }

      return Color.BLACK
    }

    private fun startMention(
      mention: Editable,
      attributes: Attributes?,
    ) {
      if (attributes == null) {
        return
      }
      val text = attributes.getValue("", "text")
      val indicator = attributes.getValue("", "indicator")

      val attributesMap: MutableMap<String, String> = HashMap()
      for (i in 0..<attributes.length) {
        val localName = attributes.getLocalName(i)

        if ("text" != localName && "indicator" != localName) {
          attributesMap.put(localName, attributes.getValue(i))
        }
      }

      start(mention, Mention(indicator, text, attributesMap))
    }
  }
}
