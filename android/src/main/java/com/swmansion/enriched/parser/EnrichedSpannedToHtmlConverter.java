package com.swmansion.enriched.parser;

import android.text.Spanned;
import android.text.TextUtils;
import com.swmansion.enriched.constants.HtmlTags;
import com.swmansion.enriched.constants.Strings;
import com.swmansion.enriched.spans.EnrichedBoldSpan;
import com.swmansion.enriched.spans.EnrichedColoredSpan;
import com.swmansion.enriched.spans.EnrichedImageSpan;
import com.swmansion.enriched.spans.EnrichedInlineCodeSpan;
import com.swmansion.enriched.spans.EnrichedItalicSpan;
import com.swmansion.enriched.spans.EnrichedLinkSpan;
import com.swmansion.enriched.spans.EnrichedMentionSpan;
import com.swmansion.enriched.spans.EnrichedStrikeThroughSpan;
import com.swmansion.enriched.spans.EnrichedUnderlineSpan;
import com.swmansion.enriched.spans.interfaces.EnrichedInlineSpan;
import com.swmansion.enriched.spans.interfaces.EnrichedParagraphSpan;
import com.swmansion.enriched.utils.TagsRegistry;
import java.util.HashMap;
import java.util.Map;

/** Responsible for converting Spanned → HTML. */
public class EnrichedSpannedToHtmlConverter {

  private final Spanned text;

  public EnrichedSpannedToHtmlConverter(Spanned text) {
    this.text = text;
  }

  public String convert() {
    StringBuilder out = new StringBuilder(text.length() * 2);
    withinHtml(out, text);

    return Strings.HTML_OPEN + out + Strings.HTML_CLOSE;
  }

  private void withinHtml(StringBuilder out, Spanned text) {
    withinBlock(out, text, 0, text.length());
  }

  private TagsRegistry.TagInfo getBlockTagWithAttributes(EnrichedParagraphSpan[] spans) {
    if (spans.length == 0) {
      return new TagsRegistry.TagInfo(HtmlTags.PARAGRAPH, false, null);
    }

    if (spans.length == 1) {
      return TagsRegistry.INSTANCE.lookup(spans[0]);
    }

    String resultingTag = HtmlTags.PARAGRAPH;
    boolean selfClosing = false;
    Map<String, String> attrs = new HashMap<>();

    for (EnrichedParagraphSpan span : spans) {
      TagsRegistry.TagInfo info = TagsRegistry.INSTANCE.lookup(span);
      if (info == null) continue;
      if (!info.getTag().equals(HtmlTags.PARAGRAPH) && !info.getTag().isEmpty()) {
        resultingTag = info.getTag();
        selfClosing = info.isSelfClosing();
      }

      if (info.getAttributes() != null) {
        Map<String, String> a = info.getAttributes().invoke(span);
        if (a != null) attrs.putAll(a);
      }
    }

    return new TagsRegistry.TagInfo(resultingTag, selfClosing, (ignored) -> attrs);
  }

  private void withinBlock(StringBuilder out, Spanned text, int start, int end) {
    boolean isInUlList = false;
    boolean isInOlList = false;
    int next;

    for (int i = start; i <= end; i = next) {
      next = TextUtils.indexOf(text, Strings.NEWLINE, i, end);
      if (next < 0) next = end;

      if (next == i) { // empty line
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
        Map<String, String> attrs =
            tagInfo.getAttributes() != null
                ? tagInfo.getAttributes().invoke(paragraphStyles[0])
                : null;

        if (tagInfo.isSelfClosing()) {
          if (isInUlList || isInOlList) {
            appendClosingTag(
                out, isInUlList ? HtmlTags.UNORDERED_LIST : HtmlTags.ORDERED_LIST, true);
            isInUlList = false;
            isInOlList = false;
          }

          appendSelfClosingTag(out, tag, attrs);
          out.append(Strings.NEWLINE);
          next++;
          continue;
        }

        boolean isUlListItem = tag.equals(HtmlTags.UNORDERED_LIST);
        boolean isOlListItem = tag.equals(HtmlTags.ORDERED_LIST);

        // close previous lists
        if (isInUlList && !isUlListItem) {
          isInUlList = false;
          appendClosingTag(out, tag, true);
        } else if (isInOlList && !isOlListItem) {
          isInOlList = false;
          appendClosingTag(out, tag, true);
        }

        // open new lists
        if (isUlListItem && !isInUlList) {
          isInUlList = true;

          appendOpenTagWithAttributes(out, tag, attrs, true);
        } else if (isOlListItem && !isInOlList) {
          isInOlList = true;

          appendOpenTagWithAttributes(out, tag, attrs, true);
        }

        boolean isListItem = isUlListItem || isOlListItem;

        String tagType = isListItem ? HtmlTags.LIST_ITEM : tag;

        if (isListItem) {
          appendOpenTag(out, tagType, false);
        } else {
          appendOpenTagWithAttributes(out, tagType, attrs, false);
        }

        withinParagraph(out, text, i, next);

        appendClosingTag(out, tagType, true);

        // close list at block's end
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

  private void appendOpenTag(StringBuilder out, String tag) {
    appendOpenTag(out, tag, false);
  }

  private void appendOpenTag(StringBuilder out, String tag, boolean withNewLine) {
    out.append(Strings.LT).append(tag).append(Strings.GT);
    if (withNewLine) out.append(Strings.NEWLINE);
  }

  private void appendClosingTag(StringBuilder out, String tag) {
    appendClosingTag(out, tag, false);
  }

  private void appendClosingTag(StringBuilder out, String tag, boolean withNewLine) {
    out.append(Strings.LT_SLASH).append(tag).append(Strings.GT);
    if (withNewLine) out.append(Strings.NEWLINE);
  }

  private void appendOpenTagWithAttributes(
      StringBuilder out, String tag, Map<String, String> attrs, boolean withNewLine) {

    out.append(Strings.LT).append(tag);
    appendAttributes(out, attrs);
    out.append(Strings.GT);

    if (withNewLine) out.append(Strings.NEWLINE);
  }

  private void appendAttributes(StringBuilder out, Map<String, String> attrs) {
    if (attrs == null || attrs.isEmpty()) return;

    for (Map.Entry<String, String> entry : attrs.entrySet()) {
      out.append(" ").append(entry.getKey()).append("=\"").append(entry.getValue()).append("\"");
    }
  }

  private void appendSelfClosingTag(StringBuilder out, String tag, Map<String, String> attrs) {

    out.append(Strings.LT).append(tag);
    appendAttributes(out, attrs);
    out.append(Strings.SLASH_GT);
  }

  private void withinParagraph(StringBuilder out, Spanned text, int start, int end) {
    int next;

    for (int i = start; i < end; i = next) {
      next = text.nextSpanTransition(i, end, EnrichedInlineSpan.class);
      EnrichedInlineSpan[] style = text.getSpans(i, next, EnrichedInlineSpan.class);

      // Open inline spans
      for (EnrichedInlineSpan span : style) {

        if (span instanceof EnrichedColoredSpan) {
          out.append("<font color=\"")
              .append(((EnrichedColoredSpan) span).getHexColor())
              .append("\">");
        }
        if (span instanceof EnrichedBoldSpan) {
          appendOpenTag(out, HtmlTags.BOLD);
        }
        if (span instanceof EnrichedItalicSpan) {
          appendOpenTag(out, HtmlTags.ITALIC);
        }
        if (span instanceof EnrichedUnderlineSpan) {
          appendOpenTag(out, HtmlTags.UNDERLINE);
        }
        if (span instanceof EnrichedInlineCodeSpan) {
          appendOpenTag(out, HtmlTags.CODE_INLINE);
        }
        if (span instanceof EnrichedStrikeThroughSpan) {
          appendOpenTag(out, HtmlTags.STRIKE_THROUGH);
        }
        if (span instanceof EnrichedLinkSpan) {
          out.append("<a href=\"").append(((EnrichedLinkSpan) span).getUrl()).append("\">");
        }
        if (span instanceof EnrichedMentionSpan mention) {

          out.append("<mention text=\"")
              .append(mention.getText())
              .append("\" indicator=\"")
              .append(mention.getIndicator())
              .append("\"");

          Map<String, String> attrs = mention.getAttributes();
          for (Map.Entry<String, String> entry : attrs.entrySet()) {
            out.append(" ")
                .append(entry.getKey())
                .append("=\"")
                .append(entry.getValue())
                .append("\"");
          }

          out.append(">");
        }
        if (span instanceof EnrichedImageSpan) {
          EnrichedImageSpan img = (EnrichedImageSpan) span;
          out.append("<img src=\"")
              .append(img.getSource())
              .append("\" width=\"")
              .append(img.getWidth())
              .append("\" height=\"")
              .append(img.getHeight())
              .append("\"/>");

          // skip placeholder character
          i = next;
        }
      }

      withinStyle(out, text, i, next);

      // Closing spans
      for (int j = style.length - 1; j >= 0; j--) {
        EnrichedInlineSpan span = style[j];

        if (span instanceof EnrichedLinkSpan) appendClosingTag(out, HtmlTags.LINK);
        if (span instanceof EnrichedMentionSpan) appendClosingTag(out, HtmlTags.MENTION);
        if (span instanceof EnrichedStrikeThroughSpan)
          appendClosingTag(out, HtmlTags.STRIKE_THROUGH);
        if (span instanceof EnrichedUnderlineSpan) appendClosingTag(out, HtmlTags.UNDERLINE);
        if (span instanceof EnrichedInlineCodeSpan) appendClosingTag(out, HtmlTags.CODE_INLINE);
        if (span instanceof EnrichedBoldSpan) appendClosingTag(out, HtmlTags.BOLD);
        if (span instanceof EnrichedItalicSpan) appendClosingTag(out, HtmlTags.ITALIC);
        if (span instanceof EnrichedColoredSpan) appendClosingTag(out, HtmlTags.FONT);
      }
    }
  }

  private void withinStyle(StringBuilder out, CharSequence text, int start, int end) {
    for (int i = start; i < end; i++) {

      char c = text.charAt(i);

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

      // surrogate pairs — emoji etc.
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

      // collapse multiple spaces
      if (c == Strings.SPACE_CHAR) {
        while (i + 1 < end && text.charAt(i + 1) == Strings.SPACE_CHAR) {
          out.append(Strings.ESC_NBSP);
          i++;
        }
        out.append(" ");
        continue;
      }

      out.append(c);
    }
  }
}
