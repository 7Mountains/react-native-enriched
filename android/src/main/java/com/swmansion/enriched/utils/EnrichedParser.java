package com.swmansion.enriched.utils;

import android.graphics.drawable.Drawable;
import android.text.Editable;
import android.text.Layout;
import android.text.Spannable;
import android.text.SpannableStringBuilder;
import android.text.Spanned;
import android.text.TextUtils;
import android.text.style.AlignmentSpan;
import android.text.style.ParagraphStyle;
import com.swmansion.enriched.EnrichedTextInputView;
import com.swmansion.enriched.constants.HtmlTags;
import com.swmansion.enriched.constants.Strings;
import com.swmansion.enriched.spans.EnrichedBlockQuoteSpan;
import com.swmansion.enriched.spans.EnrichedBoldSpan;
import com.swmansion.enriched.spans.EnrichedChecklistSpan;
import com.swmansion.enriched.spans.EnrichedCodeBlockSpan;
import com.swmansion.enriched.spans.EnrichedContentSpan;
import com.swmansion.enriched.spans.EnrichedH1Span;
import com.swmansion.enriched.spans.EnrichedH2Span;
import com.swmansion.enriched.spans.EnrichedH3Span;
import com.swmansion.enriched.spans.EnrichedH4Span;
import com.swmansion.enriched.spans.EnrichedH5Span;
import com.swmansion.enriched.spans.EnrichedH6Span;
import com.swmansion.enriched.spans.EnrichedHorizontalRuleSpan;
import com.swmansion.enriched.spans.EnrichedImageSpan;
import com.swmansion.enriched.spans.EnrichedInlineCodeSpan;
import com.swmansion.enriched.spans.EnrichedItalicSpan;
import com.swmansion.enriched.spans.EnrichedLinkSpan;
import com.swmansion.enriched.spans.EnrichedMentionSpan;
import com.swmansion.enriched.spans.EnrichedOrderedListSpan;
import com.swmansion.enriched.spans.EnrichedStrikeThroughSpan;
import com.swmansion.enriched.spans.EnrichedUnderlineSpan;
import com.swmansion.enriched.spans.EnrichedUnorderedListSpan;
import com.swmansion.enriched.spans.interfaces.EnrichedBlockSpan;
import com.swmansion.enriched.spans.interfaces.EnrichedInlineSpan;
import com.swmansion.enriched.spans.interfaces.EnrichedParagraphSpan;
import com.swmansion.enriched.spans.interfaces.EnrichedZeroWidthSpaceSpan;
import com.swmansion.enriched.styles.HtmlStyle;
import java.io.IOException;
import java.io.StringReader;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import javax.annotation.Nullable;
import org.ccil.cowan.tagsoup.HTMLSchema;
import org.ccil.cowan.tagsoup.Parser;
import org.xml.sax.Attributes;
import org.xml.sax.ContentHandler;
import org.xml.sax.InputSource;
import org.xml.sax.Locator;
import org.xml.sax.SAXException;
import org.xml.sax.SAXNotRecognizedException;
import org.xml.sax.SAXNotSupportedException;
import org.xml.sax.XMLReader;

/**
 * Most of the code in this file is copied from the Android source code and adjusted to our needs.
 * For the reference see <a
 * href="https://android.googlesource.com/platform/frameworks/base/+/refs/heads/master/core/java/android/text/Html.java">docs</a>
 */
public class EnrichedParser {
  /** Retrieves images for HTML &lt;img&gt; tags. */
  public interface ImageGetter {
    /**
     * This method is called when the HTML parser encounters an &lt;img&gt; tag. The <code>source
     * </code> argument is the string from the "src" attribute; the return value should be a
     * Drawable representation of the image or <code>null</code> for a generic replacement image.
     * Make sure you call setBounds() on your Drawable if it doesn't already have its bounds set.
     */
    void loadImage(String source, ImageGetter.Callbacks callbacks, int maxWidth);

    void loadImage(String source, ImageGetter.Callbacks callbacks, int maxWidth, int minWidth);

    interface Callbacks {
      void onImageFailed();

      void onImageLoaded(Drawable drawable);

      void onImageLoading(Drawable drawable);
    }
  }

  private EnrichedParser() {}

  /**
   * Lazy initialization holder for HTML parser. This class will a) be preloaded by the zygote, or
   * b) not loaded until absolutely necessary.
   */
  private static class HtmlParser {
    private static final HTMLSchema schema = new HTMLSchema();
  }

  /**
   * Returns displayable styled text from the provided HTML string. Any &lt;img&gt; tags in the HTML
   * will use the specified ImageGetter to request a representation of the image (use null if you
   * don't want this) and the specified TagHandler to handle unknown tags (specify null if you don't
   * want this).
   *
   * <p>This uses TagSoup to handle real HTML, including all of the brokenness found in the wild.
   */
  public static Spanned fromHtml(
      String source,
      HtmlStyle style,
      ImageGetter imageGetter,
      EnrichedTextInputView textInputView) {
    Parser parser = new Parser();
    try {
      parser.setProperty(Parser.schemaProperty, HtmlParser.schema);
    } catch (SAXNotRecognizedException | SAXNotSupportedException e) {
      // Should not happen.
      throw new RuntimeException(e);
    }
    HtmlToSpannedConverter converter =
        new HtmlToSpannedConverter(source, style, imageGetter, parser, textInputView);
    return converter.convert();
  }

  public static String toHtml(Spanned text) {
    StringBuilder out = new StringBuilder();
    withinHtml(out, text);
    String outString = out.toString();

    String normalizedCodeBlock =
        outString.replaceAll(
            Strings.LT_SLASH + HtmlTags.CODE_BLOCK + Strings.GT + "\\n<br>",
            Strings.LT_SLASH + HtmlTags.CODE_BLOCK + Strings.GT);

    String normalizedBlockQuote =
        normalizedCodeBlock.replaceAll(
            Strings.LT_SLASH + HtmlTags.BLOCK_QUOTE + Strings.GT + "\\n<br>",
            Strings.LT_SLASH + HtmlTags.BLOCK_QUOTE + Strings.GT);

    return Strings.HTML_OPEN + normalizedBlockQuote + Strings.HTML_CLOSE;
  }

  public static String toHtmlWithDefault(CharSequence text) {
    if (text instanceof Spanned) {
      return toHtml((Spanned) text);
    }
    return Strings.HTML_OPEN + "<p></p>\n" + Strings.HTML_CLOSE;
  }

  /** Returns an HTML escaped representation of the given plain text. */
  public static String escapeHtml(CharSequence text) {
    StringBuilder out = new StringBuilder();
    withinStyle(out, text, 0, text.length());
    return out.toString();
  }

  private static void withinHtml(StringBuilder out, Spanned text) {
    withinDiv(out, text, 0, text.length());
  }

  private static void withinDiv(StringBuilder out, Spanned text, int start, int end) {
    int next;
    for (int i = start; i < end; i = next) {
      next = text.nextSpanTransition(i, end, EnrichedBlockSpan.class);
      EnrichedBlockSpan[] blocks = text.getSpans(i, next, EnrichedBlockSpan.class);

      String tag = HtmlTags.BLOCK_QUOTE;
      if (blocks.length > 0) {
        tag =
            blocks[0] instanceof EnrichedCodeBlockSpan ? HtmlTags.CODE_BLOCK : HtmlTags.BLOCK_QUOTE;
      }

      if (out.length() >= 5 && out.substring(out.length() - 5).equals("<br>\n")) {
        out.replace(out.length() - 5, out.length(), "");
      }

      for (EnrichedBlockSpan ignored : blocks) {
        appendOpenTag(out, tag);
        out.append(Strings.NEWLINE);
      }

      withinBlock(out, text, i, next);

      for (EnrichedBlockSpan ignored : blocks) {
        appendClosingTag(out, tag);
        out.append(Strings.NEWLINE);
      }
    }
  }

  private static TagsRegistry.TagInfo getBlockTagWithAttributes(EnrichedParagraphSpan[] spans) {
    for (EnrichedParagraphSpan span : spans) {
      TagsRegistry.TagInfo info = TagsRegistry.INSTANCE.lookup(span);
      if (info != null) return info;
    }
    return new TagsRegistry.TagInfo(HtmlTags.PARAGRAPH, false, null);
  }

  private static void withinBlock(StringBuilder out, Spanned text, int start, int end) {
    boolean isInUlList = false;
    boolean isInOlList = false;
    int next;

    for (int i = start; i <= end; i = next) {

      next = TextUtils.indexOf(text, Strings.NEWLINE, i, end);
      if (next < 0) next = end;

      if (next == i) {
        if (isInUlList) {
          isInUlList = false;
          appendClosingTag(out, HtmlTags.UNORDERED_LIST, true);
        } else if (isInOlList) {
          isInOlList = false;
          appendClosingTag(out, HtmlTags.ORDERED_LIST, true);
        }
        appendOpenTag(out, HtmlTags.BREAK_LINE, true);
      } else {

        EnrichedParagraphSpan[] paragraphStyles =
            text.getSpans(i, next, EnrichedParagraphSpan.class);

        TagsRegistry.TagInfo tagInfo = getBlockTagWithAttributes(paragraphStyles);
        String tag = tagInfo.getTag();
        if (tagInfo.isSelfClosing()) {

          if (isInOlList || isInUlList) {
            appendClosingTag(
                out, isInOlList ? HtmlTags.UNORDERED_LIST : HtmlTags.ORDERED_LIST, true);
            isInOlList = false;
            isInUlList = false;
          }

          Map<String, String> attrs =
              tagInfo.getAttributes() != null
                  ? tagInfo.getAttributes().invoke(paragraphStyles[0])
                  : null;

          appendSelfClosingTag(out, tag, attrs);
          out.append(Strings.NEWLINE);

          next++;
          continue;
        }
        boolean isUlListItem = tag.equals(HtmlTags.UNORDERED_LIST);
        boolean isOlListItem = tag.equals(HtmlTags.ORDERED_LIST);

        // Closing previous list
        if (isInUlList && !isUlListItem) {
          isInUlList = false;
          appendClosingTag(out, HtmlTags.UNORDERED_LIST, true);
        } else if (isInOlList && !isOlListItem) {
          isInOlList = false;
          appendClosingTag(out, HtmlTags.ORDERED_LIST, true);
        }

        // Opening new list
        if (isUlListItem && !isInUlList) {
          isInUlList = true;
          appendOpenTag(out, HtmlTags.UNORDERED_LIST, true);
        } else if (isOlListItem && !isInOlList) {
          isInOlList = true;
          appendOpenTag(out, HtmlTags.ORDERED_LIST, true);
        }
        boolean isListItem = isUlListItem || isOlListItem;
        String tagType = isListItem ? HtmlTags.LIST_ITEM : tag;

        Map<String, String> attrs =
            tagInfo.getAttributes() != null
                ? tagInfo.getAttributes().invoke(paragraphStyles[0])
                : null;

        appendOpenTagWithAttributes(out, tagType, attrs, false);

        withinParagraph(out, text, i, next);

        appendClosingTag(out, tagType, true);

        // If we're at the end of block, close list if active
        if (next == end) {
          if (isInUlList) {
            isInUlList = false;
            appendClosingTag(out, HtmlTags.UNORDERED_LIST, true);
          } else if (isInOlList) {
            isInOlList = false;
            appendClosingTag(out, HtmlTags.ORDERED_LIST, true);
          }
        }
      }

      next++;
    }
  }

  private static void appendOpenTag(StringBuilder out, String tag) {
    appendOpenTag(out, tag, false);
  }

  private static void appendOpenTag(StringBuilder out, String tag, boolean withNewLine) {
    out.append(Strings.LT).append(tag).append(Strings.GT);
    if (withNewLine) {
      out.append(Strings.NEWLINE);
    }
  }

  private static void appendClosingTag(StringBuilder out, String tag) {
    appendClosingTag(out, tag, false);
  }

  private static void appendOpenTagWithAttributes(
      StringBuilder out, String tag, Map<String, String> attrs, boolean withNewLine) {
    out.append(Strings.LT).append(tag);
    appendAttributes(out, attrs);
    out.append(Strings.GT);
    if (withNewLine) out.append(Strings.NEWLINE);
  }

  private static void appendAttributes(StringBuilder out, Map<String, String> attrs) {
    if (attrs == null || attrs.isEmpty()) return;

    for (Map.Entry<String, String> entry : attrs.entrySet()) {
      out.append(Strings.SPACE_CHAR)
          .append(entry.getKey())
          .append("=\"")
          .append(entry.getValue())
          .append("\"");
    }
  }

  private static void appendClosingTag(StringBuilder out, String tag, boolean withNewLine) {
    out.append(Strings.LT_SLASH).append(tag).append(Strings.GT);
    if (withNewLine) {
      out.append(Strings.NEWLINE);
    }
  }

  private static void appendSelfClosingTag(
      StringBuilder out, String tag, Map<String, String> attrs) {
    out.append(Strings.LT).append(tag);
    appendAttributes(out, attrs);
    out.append(Strings.SLASH_GT);
  }

  private static void withinParagraph(StringBuilder out, Spanned text, int start, int end) {
    int next;
    for (int i = start; i < end; i = next) {
      next = text.nextSpanTransition(i, end, EnrichedInlineSpan.class);
      EnrichedInlineSpan[] style = text.getSpans(i, next, EnrichedInlineSpan.class);
      for (int j = 0; j < style.length; j++) {
        if (style[j] instanceof EnrichedBoldSpan) {
          appendOpenTag(out, HtmlTags.BOLD);
        }
        if (style[j] instanceof EnrichedItalicSpan) {
          appendOpenTag(out, HtmlTags.ITALIC);
        }
        if (style[j] instanceof EnrichedUnderlineSpan) {
          appendOpenTag(out, HtmlTags.UNDERLINE);
        }
        if (style[j] instanceof EnrichedInlineCodeSpan) {
          appendOpenTag(out, HtmlTags.CODE_INLINE);
        }
        if (style[j] instanceof EnrichedStrikeThroughSpan) {
          appendOpenTag(out, HtmlTags.STRIKE_THROUGH);
        }
        if (style[j] instanceof EnrichedLinkSpan) {
          out.append("<a href=\"");
          out.append(((EnrichedLinkSpan) style[j]).getUrl());
          out.append("\">");
        }
        if (style[j] instanceof EnrichedMentionSpan) {
          out.append("<mention text=\"");
          out.append(((EnrichedMentionSpan) style[j]).getText());
          out.append("\"");

          out.append(" indicator=\"");
          out.append(((EnrichedMentionSpan) style[j]).getIndicator());
          out.append("\"");

          Map<String, String> attributes = ((EnrichedMentionSpan) style[j]).getAttributes();
          for (Map.Entry<String, String> entry : attributes.entrySet()) {
            out.append(Strings.SPACE_CHAR);
            out.append(entry.getKey());
            out.append("=\"");
            out.append(entry.getValue());
            out.append("\"");
          }

          out.append(">");
        }
        if (style[j] instanceof EnrichedImageSpan) {
          out.append("<img src=\"");
          out.append(((EnrichedImageSpan) style[j]).getSource());
          out.append("\"");

          out.append(" width=\"");
          out.append(((EnrichedImageSpan) style[j]).getWidth());
          out.append("\"");

          out.append(" height=\"");
          out.append(((EnrichedImageSpan) style[j]).getHeight());

          out.append("\"/>");
          // Don't output the placeholder character underlying the image.
          i = next;
        }
      }
      withinStyle(out, text, i, next);
      for (int j = style.length - 1; j >= 0; j--) {
        if (style[j] instanceof EnrichedLinkSpan) {
          appendClosingTag(out, HtmlTags.LINK);
        }
        if (style[j] instanceof EnrichedMentionSpan) {
          appendClosingTag(out, HtmlTags.MENTION);
        }
        if (style[j] instanceof EnrichedStrikeThroughSpan) {
          appendClosingTag(out, HtmlTags.STRIKE_THROUGH);
        }
        if (style[j] instanceof EnrichedUnderlineSpan) {
          appendClosingTag(out, HtmlTags.UNDERLINE);
        }
        if (style[j] instanceof EnrichedInlineCodeSpan) {
          appendClosingTag(out, HtmlTags.CODE_INLINE);
        }
        if (style[j] instanceof EnrichedBoldSpan) {
          appendClosingTag(out, HtmlTags.BOLD);
        }
        if (style[j] instanceof EnrichedItalicSpan) {
          appendClosingTag(out, HtmlTags.ITALIC);
        }
      }
    }
  }

  private static void withinStyle(StringBuilder out, CharSequence text, int start, int end) {
    for (int i = start; i < end; i++) {

      char c = text.charAt(i);

      // Skip zero-width characters
      if (c == Strings.ZERO_WIDTH_SPACE_CHAR
          || c == Strings.ZERO_WIDTH_JOINER_CHAR
          || c == Strings.ZERO_WIDTH_NON_JOINER_CHAR) {
        continue;
      }

      if (c == Strings.LT_CHAR) {
        out.append(Strings.ESC_LT);
        continue;
      }
      if (c == Strings.GT_CHAR) {
        out.append(Strings.ESC_GT);
        continue;
      }
      if (c == Strings.AMP_CHAR) {
        out.append(Strings.ESC_AMP);
        continue;
      }

      // Handle surrogate pairs (emoji, extended unicode)
      if (c >= 0xD800 && c <= 0xDFFF) {
        if (c < 0xDC00 && i + 1 < end) {
          char d = text.charAt(i + 1);
          if (d >= 0xDC00 && d <= 0xDFFF) {
            i++;
            int codepoint = 0x010000 | ((c - 0xD800) << 10) | (d - 0xDC00);
            out.append("&#").append(codepoint).append(";");
            continue;
          }
        }
      }

      if (c > 0x7E || c < ' ') {
        out.append("&#").append((int) c).append(";");
        continue;
      }

      // Collapse multiple spaces → nbsp
      if (c == Strings.SPACE_CHAR) {
        while (i + 1 < end && text.charAt(i + 1) == Strings.SPACE_CHAR) {
          out.append(Strings.ESC_NBSP);
          i++;
        }
        out.append(Strings.SPACE_CHAR);
        continue;
      }

      // Default append
      out.append(c);
    }
  }
}

class HtmlToSpannedConverter implements ContentHandler {
  private final HtmlStyle mStyle;
  private final String mSource;
  private final XMLReader mReader;
  private final SpannableStringBuilder mSpannableStringBuilder;
  private final EnrichedParser.ImageGetter mImageGetter;
  private static Integer currentOrderedListItemIndex = 0;
  private static Boolean isInOrderedList = false;
  private static Boolean isEmptyTag = false;
  private final EnrichedTextInputView mTextInputView;

  public HtmlToSpannedConverter(
      String source,
      HtmlStyle style,
      EnrichedParser.ImageGetter imageGetter,
      Parser parser,
      EnrichedTextInputView textInputView) {
    mStyle = style;
    mSource = source;
    mSpannableStringBuilder = new SpannableStringBuilder();
    mImageGetter = imageGetter;
    mReader = parser;
    mTextInputView = textInputView;
  }

  public Spanned convert() {
    mReader.setContentHandler(this);
    try {
      mReader.parse(new InputSource(new StringReader(mSource)));
    } catch (IOException e) {
      // We are reading from a string. There should not be IO problems.
      throw new RuntimeException(e);
    } catch (SAXException e) {
      // TagSoup doesn't throw parse exceptions.
      throw new RuntimeException(e);
    }
    // Fix flags and range for paragraph-type markup.
    Object[] obj =
        mSpannableStringBuilder.getSpans(0, mSpannableStringBuilder.length(), ParagraphStyle.class);
    for (int i = 0; i < obj.length; i++) {
      int start = mSpannableStringBuilder.getSpanStart(obj[i]);
      int end = mSpannableStringBuilder.getSpanEnd(obj[i]);
      // If the last line of the range is blank, back off by one.
      if (end - 2 >= 0) {
        if (mSpannableStringBuilder.charAt(end - 1) == Strings.NEWLINE
            && mSpannableStringBuilder.charAt(end - 2) == Strings.NEWLINE) {
          end--;
        }
      }
      if (end == start) {
        mSpannableStringBuilder.removeSpan(obj[i]);
      } else {
        // TODO: verify if Spannable.SPAN_EXCLUSIVE_EXCLUSIVE does not break anything.
        // Previously it was SPAN_PARAGRAPH. I've changed that in order to fix ranges for list
        // items.
        mSpannableStringBuilder.setSpan(obj[i], start, end, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
      }
    }

    // Assign zero-width space character to the proper spans.
    EnrichedZeroWidthSpaceSpan[] zeroWidthSpaceSpans =
        mSpannableStringBuilder.getSpans(
            0, mSpannableStringBuilder.length(), EnrichedZeroWidthSpaceSpan.class);
    for (EnrichedZeroWidthSpaceSpan zeroWidthSpaceSpan : zeroWidthSpaceSpans) {
      int start = mSpannableStringBuilder.getSpanStart(zeroWidthSpaceSpan);
      int end = mSpannableStringBuilder.getSpanEnd(zeroWidthSpaceSpan);

      if (mSpannableStringBuilder.charAt(start) != Strings.ZERO_WIDTH_SPACE_CHAR) {
        // Insert zero-width space character at the start if it's not already present.
        mSpannableStringBuilder.insert(start, Strings.ZERO_WIDTH_SPACE_STRING);
        end++; // Adjust end position due to insertion.
      }

      mSpannableStringBuilder.removeSpan(zeroWidthSpaceSpan);
      mSpannableStringBuilder.setSpan(
          zeroWidthSpaceSpan, start, end, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
    }

    return mSpannableStringBuilder;
  }

  private void handleStartTag(String tag, @Nullable Attributes attributes, HtmlStyle htmlStyle) {
    if (tag == null) return;
    switch (tag.toLowerCase(Locale.ROOT)) {
      case HtmlTags.BREAK_LINE:
        // no-op, handled on close
        return;

      case HtmlTags.PARAGRAPH:
        isEmptyTag = true;
        startBlockElement(mSpannableStringBuilder);
        return;

      case HtmlTags.UNORDERED_LIST:
        isInOrderedList = false;
        startBlockElement(mSpannableStringBuilder);
        return;

      case HtmlTags.ORDERED_LIST:
        isInOrderedList = true;
        currentOrderedListItemIndex = 0;
        startBlockElement(mSpannableStringBuilder);
        return;

      case HtmlTags.LIST_ITEM:
        isEmptyTag = true;
        startLi(mSpannableStringBuilder);
        return;

      case HtmlTags.BOLD:
        start(mSpannableStringBuilder, new Bold());
        return;

      case HtmlTags.ITALIC:
        start(mSpannableStringBuilder, new Italic());
        return;

      case HtmlTags.UNDERLINE:
        start(mSpannableStringBuilder, new Underline());
        return;

      case HtmlTags.STRIKE_THROUGH:
      case HtmlTags.STRIKE: // alias
        start(mSpannableStringBuilder, new Strikethrough());
        return;

      case HtmlTags.BLOCK_QUOTE:
        isEmptyTag = true;
        startBlockquote(mSpannableStringBuilder);
        return;

      case HtmlTags.CODE_BLOCK:
        isEmptyTag = true;
        startCodeBlock(mSpannableStringBuilder);
        return;

      case HtmlTags.CODE_INLINE:
        start(mSpannableStringBuilder, new Code());
        return;

      case HtmlTags.LINK:
        startA(mSpannableStringBuilder, attributes);
        return;

      case HtmlTags.H1:
        startHeading(mSpannableStringBuilder, 1);
        return;

      case HtmlTags.H2:
        startHeading(mSpannableStringBuilder, 2);
        return;

      case HtmlTags.H3:
        startHeading(mSpannableStringBuilder, 3);
        return;

      case HtmlTags.H4:
        startHeading(mSpannableStringBuilder, 4);
        return;

      case HtmlTags.H5:
        startHeading(mSpannableStringBuilder, 5);
        return;

      case HtmlTags.H6:
        startHeading(mSpannableStringBuilder, 6);
        return;

      case HtmlTags.IMAGE:
        startImg(mSpannableStringBuilder, attributes, mImageGetter);
        return;

      case HtmlTags.MENTION:
        startMention(mSpannableStringBuilder, attributes);
        return;

      case HtmlTags.HORIZONTAL_RULE:
        addHr(mSpannableStringBuilder, htmlStyle);
        return;

      case HtmlTags.CONTENT:
        addContent(mSpannableStringBuilder, attributes, htmlStyle);
        return;

      case HtmlTags.CHECKLIST:
        isEmptyTag = true;
        startChecklist(mSpannableStringBuilder, attributes);
        return;

      default:
        // unknown tag → ignore
        return;
    }
  }

  private void handleEndTag(String tag) {

    if (tag == null) return;

    switch (tag.toLowerCase(Locale.ROOT)) {
      case HtmlTags.BREAK_LINE:
        handleBr(mSpannableStringBuilder);
        return;

      case HtmlTags.PARAGRAPH:
      case HtmlTags.UNORDERED_LIST:
        endBlockElement(mSpannableStringBuilder);
        return;

      case HtmlTags.LIST_ITEM:
        endLi(mSpannableStringBuilder, mStyle);
        return;

      case HtmlTags.BOLD:
        end(mSpannableStringBuilder, Bold.class, new EnrichedBoldSpan(mStyle));
        return;

      case HtmlTags.ITALIC:
        end(mSpannableStringBuilder, Italic.class, new EnrichedItalicSpan(mStyle));
        return;

      case HtmlTags.UNDERLINE:
        end(mSpannableStringBuilder, Underline.class, new EnrichedUnderlineSpan(mStyle));
        return;

      case HtmlTags.STRIKE_THROUGH:
      case HtmlTags.STRIKE:
        end(mSpannableStringBuilder, Strikethrough.class, new EnrichedStrikeThroughSpan(mStyle));
        return;

      case HtmlTags.BLOCK_QUOTE:
        endBlockquote(mSpannableStringBuilder, mStyle);
        return;

      case HtmlTags.CODE_BLOCK:
        endCodeBlock(mSpannableStringBuilder, mStyle);
        return;

      case HtmlTags.LINK:
        endA(mSpannableStringBuilder, mStyle);
        return;

      case HtmlTags.H1:
        endHeading(mSpannableStringBuilder, mStyle, 1);
        return;

      case HtmlTags.H2:
        endHeading(mSpannableStringBuilder, mStyle, 2);
        return;

      case HtmlTags.H3:
        endHeading(mSpannableStringBuilder, mStyle, 3);
        return;

      case HtmlTags.H4:
        endHeading(mSpannableStringBuilder, mStyle, 4);
        return;

      case HtmlTags.H5:
        endHeading(mSpannableStringBuilder, mStyle, 5);
        return;

      case HtmlTags.H6:
        endHeading(mSpannableStringBuilder, mStyle, 6);
        return;

      case HtmlTags.CODE_INLINE:
        end(mSpannableStringBuilder, Code.class, new EnrichedInlineCodeSpan(mStyle));
        return;

      case HtmlTags.MENTION:
        endMention(mSpannableStringBuilder, mStyle);
        return;

      case HtmlTags.CHECKLIST:
        endCheckList(mSpannableStringBuilder, mStyle);
        return;

      default:
        // Unknown tag, ignore
        return;
    }
  }

  private static void appendNewlines(Editable text, int minNewline) {
    final int len = text.length();
    if (len == 0) {
      return;
    }
    int existingNewlines = 0;
    for (int i = len - 1; i >= 0 && text.charAt(i) == '\n'; i--) {
      existingNewlines++;
    }
    for (int j = existingNewlines; j < minNewline; j++) {
      text.append(Strings.NEWLINE);
    }
  }

  private static void startBlockElement(Editable text) {
    appendNewlines(text, 1);
    start(text, new Newline(1));
  }

  private static void endBlockElement(Editable text) {
    Newline n = getLast(text, Newline.class);
    if (n != null) {
      appendNewlines(text, n.mNumNewlines);
      text.removeSpan(n);
    }
    Alignment a = getLast(text, Alignment.class);
    if (a != null) {
      setSpanFromMark(text, a, new AlignmentSpan.Standard(a.mAlignment));
    }
  }

  private static void handleBr(Editable text) {
    text.append('\n');
  }

  private void startLi(Editable text) {
    startBlockElement(text);

    if (isInOrderedList) {
      currentOrderedListItemIndex++;
      start(text, new List(HtmlTags.ORDERED_LIST, currentOrderedListItemIndex));
    } else {
      start(text, new List(HtmlTags.UNORDERED_LIST, 0));
    }
  }

  private void startChecklist(Editable text, @Nullable Attributes attributes) {
    if (attributes == null) {
      return;
    }
    boolean checked = Objects.equals(attributes.getValue("checked"), "true");

    startBlockElement(text);
    start(text, new Checklist(checked));
  }

  private static void endCheckList(Editable text, HtmlStyle style) {
    endBlockElement(text);
    Checklist last = getLast(text, Checklist.class);

    if (last == null) {
      return;
    }

    setParagraphSpanFromMark(text, last, new EnrichedChecklistSpan(style, last.mChecked));
  }

  private static void endLi(Editable text, HtmlStyle style) {
    endBlockElement(text);

    List l = getLast(text, List.class);
    if (l != null) {
      if (l.mType.equals(HtmlTags.ORDERED_LIST)) {
        setParagraphSpanFromMark(text, l, new EnrichedOrderedListSpan(l.mIndex, style));
      } else {
        setParagraphSpanFromMark(text, l, new EnrichedUnorderedListSpan(style));
      }
    }

    endBlockElement(text);
  }

  private void startBlockquote(Editable text) {
    startBlockElement(text);
    start(text, new Blockquote());
  }

  private static void endBlockquote(Editable text, HtmlStyle style) {
    endBlockElement(text);
    Blockquote last = getLast(text, Blockquote.class);
    setParagraphSpanFromMark(text, last, new EnrichedBlockQuoteSpan(style));
  }

  private void startCodeBlock(Editable text) {
    startBlockElement(text);
    start(text, new CodeBlock());
  }

  private static void endCodeBlock(Editable text, HtmlStyle style) {
    endBlockElement(text);
    CodeBlock last = getLast(text, CodeBlock.class);
    setParagraphSpanFromMark(text, last, new EnrichedCodeBlockSpan(style));
  }

  private static void startHeading(Editable text, int level) {
    startBlockElement(text);

    switch (level) {
      case 1:
        start(text, new H1());
        break;
      case 2:
        start(text, new H2());
        break;
      case 3:
        start(text, new H3());
        break;
      case 4:
        start(text, new H4());
        break;
      case 5:
        start(text, new H5());
        break;
      case 6:
        start(text, new H6());
        break;
      default:
        throw new IllegalArgumentException("Unsupported heading level: " + level);
    }
  }

  private static void endHeading(Editable text, HtmlStyle style, int level) {
    endBlockElement(text);

    switch (level) {
      case 1:
        H1 lastH1 = getLast(text, H1.class);
        setParagraphSpanFromMark(text, lastH1, new EnrichedH1Span(style));
        break;
      case 2:
        H2 lastH2 = getLast(text, H2.class);
        setParagraphSpanFromMark(text, lastH2, new EnrichedH2Span(style));
        break;
      case 3:
        H3 lastH3 = getLast(text, H3.class);
        setParagraphSpanFromMark(text, lastH3, new EnrichedH3Span(style));
        break;
      case 4:
        H4 lastH4 = getLast(text, H4.class);
        setParagraphSpanFromMark(text, lastH4, new EnrichedH4Span(style));
        break;
      case 5:
        H5 lastH5 = getLast(text, H5.class);
        setParagraphSpanFromMark(text, lastH5, new EnrichedH5Span(style));
        break;
      case 6:
        H6 lastH6 = getLast(text, H6.class);
        setParagraphSpanFromMark(text, lastH6, new EnrichedH6Span(style));
        break;
      default:
        throw new IllegalArgumentException("Unsupported heading level: " + level);
    }
  }

  private static void addHr(Editable text, HtmlStyle htmlStyle) {
    SpannableStringBuilder builder = new SpannableStringBuilder();
    builder.append(Strings.MAGIC_CHAR);
    builder.setSpan(
        new EnrichedHorizontalRuleSpan(htmlStyle), 0, 1, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
    text.append(builder);
    text.append('\n');
  }

  private void addContent(Editable editable, @Nullable Attributes attributes, HtmlStyle htmlStyle) {
    if (attributes == null) {
      return;
    }

    String text = attributes.getValue("", "text");
    String type = attributes.getValue("", "type");
    String src = attributes.getValue("", "src");

    Map<String, String> attributesMap = new HashMap<>();
    for (int i = 0; i < attributes.getLength(); i++) {
      String localName = attributes.getLocalName(i);

      if (!"text".equals(localName) && !"type".equals(localName) && !"src".equals(localName)) {
        attributesMap.put(localName, attributes.getValue(i));
      }
    }
    SpannableStringBuilder builder = new SpannableStringBuilder();
    builder.append(Strings.MAGIC_CHAR);
    EnrichedContentSpan span =
        EnrichedContentSpan.Companion.createEnrichedContentSpan(
            text, type, src, attributesMap, htmlStyle);
    span.attachTo(mTextInputView);
    builder.setSpan(span, 0, 1, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
    editable.append(builder);
    editable.append('\n');
  }

  private static <T> T getLast(Spanned text, Class<T> kind) {
    /*
     * This knows that the last returned object from getSpans()
     * will be the most recently added.
     */
    T[] objs = text.getSpans(0, text.length(), kind);
    if (objs.length == 0) {
      return null;
    } else {
      return objs[objs.length - 1];
    }
  }

  private static void setSpanFromMark(Spannable text, Object mark, Object... spans) {
    int where = text.getSpanStart(mark);
    text.removeSpan(mark);
    int len = text.length();
    if (where != len) {
      for (Object span : spans) {
        text.setSpan(span, where, len, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
      }
    }
  }

  private static void setParagraphSpanFromMark(Editable text, Object mark, Object... spans) {
    int where = text.getSpanStart(mark);
    text.removeSpan(mark);
    int len = text.length();

    // Block spans require at least one character to be applied.
    if (isEmptyTag) {
      text.append("\u200B");
      len++;
    }

    // Adjust the end position to exclude the newline character, if present
    if (len > 0 && text.charAt(len - 1) == Strings.NEWLINE) {
      len--;
    }

    if (where != len) {
      for (Object span : spans) {
        text.setSpan(span, where, len, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
      }
    }
  }

  private static void start(Editable text, Object mark) {
    int len = text.length();
    text.setSpan(mark, len, len, Spannable.SPAN_INCLUSIVE_EXCLUSIVE);
  }

  private static void end(Editable text, Class kind, Object repl) {
    Object obj = getLast(text, kind);
    if (obj != null) {
      setSpanFromMark(text, obj, repl);
    }
  }

  private static void startImg(
      Editable text, @Nullable Attributes attributes, EnrichedParser.ImageGetter img) {
    if (attributes == null) {
      return;
    }
    String src = attributes.getValue("", "src");
    String width = attributes.getValue("", "width");
    String height = attributes.getValue("", "height");

    int len = text.length();
    EnrichedImageSpan span =
        EnrichedImageSpan.Companion.createEnrichedImageSpan(
            src, Integer.parseInt(width), Integer.parseInt(height));
    text.append(Strings.SPACE_CHAR);
    text.setSpan(span, len, text.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
  }

  private static void startA(Editable text, @Nullable Attributes attributes) {
    if (attributes == null) {
      return;
    }
    String href = attributes.getValue("", "href");
    start(text, new Href(href));
  }

  private void endA(Editable text, HtmlStyle style) {
    Href h = getLast(text, Href.class);
    if (h != null) {
      if (h.mHref != null) {
        setSpanFromMark(text, h, new EnrichedLinkSpan(h.mHref, style));
      }
    }
  }

  private static void startMention(Editable mention, @Nullable Attributes attributes) {
    if (attributes == null) {
      return;
    }
    String text = attributes.getValue("", "text");
    String indicator = attributes.getValue("", "indicator");

    Map<String, String> attributesMap = new HashMap<>();
    for (int i = 0; i < attributes.getLength(); i++) {
      String localName = attributes.getLocalName(i);

      if (!"text".equals(localName) && !"indicator".equals(localName)) {
        attributesMap.put(localName, attributes.getValue(i));
      }
    }

    start(mention, new Mention(indicator, text, attributesMap));
  }

  private void endMention(Editable text, HtmlStyle style) {
    Mention m = getLast(text, Mention.class);

    if (m == null) return;
    if (m.mText == null) return;

    setSpanFromMark(text, m, new EnrichedMentionSpan(m.mText, m.mIndicator, m.mAttributes, style));
  }

  public void setDocumentLocator(Locator locator) {}

  public void startDocument() {}

  public void endDocument() {}

  public void startPrefixMapping(String prefix, String uri) {}

  public void endPrefixMapping(String prefix) {}

  public void startElement(String uri, String localName, String qName, Attributes attributes) {
    handleStartTag(localName, attributes, mStyle);
  }

  public void endElement(String uri, String localName, String qName) {
    handleEndTag(localName);
  }

  public void characters(char[] ch, int start, int length) {
    StringBuilder sb = new StringBuilder();
    if (length > 0) isEmptyTag = false;

    /*
     * Ignore whitespace that immediately follows other whitespace;
     * newlines count as spaces.
     */
    for (int i = 0; i < length; i++) {
      char c = ch[i + start];
      if (c == Strings.SPACE_CHAR || c == Strings.NEWLINE) {
        char pred;
        int len = sb.length();
        if (len == 0) {
          len = mSpannableStringBuilder.length();
          if (len == 0) {
            pred = Strings.NEWLINE;
          } else {
            pred = mSpannableStringBuilder.charAt(len - 1);
          }
        } else {
          pred = sb.charAt(len - 1);
        }
        if (pred != Strings.SPACE_CHAR && pred != Strings.NEWLINE) {
          sb.append(Strings.SPACE_CHAR);
        }
      } else {
        sb.append(c);
      }
    }
    mSpannableStringBuilder.append(sb);
  }

  public void ignorableWhitespace(char[] ch, int start, int length) {}

  public void processingInstruction(String target, String data) {}

  public void skippedEntity(String name) {}

  private static class H1 {}

  private static class H2 {}

  private static class H3 {}

  private static class H4 {}

  private static class H5 {}

  private static class H6 {}

  private static class Bold {}

  private static class Italic {}

  private static class Underline {}

  private static class Code {}

  private static class CodeBlock {}

  private static class Strikethrough {}

  private static class Blockquote {}

  private static class List {
    public int mIndex;
    public String mType;

    public List(String type, int index) {
      mType = type;
      mIndex = index;
    }
  }

  private static class Checklist {
    public boolean mChecked;

    public Checklist(boolean checked) {
      mChecked = checked;
    }
  }

  private static class Mention {
    public Map<String, String> mAttributes;
    public String mIndicator;
    public String mText;

    public Mention(String indicator, String text, Map<String, String> attributes) {
      mIndicator = indicator;
      mAttributes = attributes;
      mText = text;
    }
  }

  private static class Href {
    public String mHref;

    public Href(String href) {
      mHref = href;
    }
  }

  private static class Newline {
    private final int mNumNewlines;

    public Newline(int numNewlines) {
      mNumNewlines = numNewlines;
    }
  }

  private static class Alignment {
    private final Layout.Alignment mAlignment;

    public Alignment(Layout.Alignment alignment) {
      mAlignment = alignment;
    }
  }
}
