package com.swmansion.enriched.parser;

import android.graphics.drawable.Drawable;
import android.text.Spanned;
import com.swmansion.enriched.EnrichedTextInputView;
import com.swmansion.enriched.constants.Strings;
import com.swmansion.enriched.styles.HtmlStyle;
import org.ccil.cowan.tagsoup.HTMLSchema;
import org.ccil.cowan.tagsoup.Parser;
import org.xml.sax.SAXNotRecognizedException;
import org.xml.sax.SAXNotSupportedException;

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

    return new HtmlToSpannedConverter(source, style, imageGetter, parser, textInputView).convert();
  }

  public static String toHtml(Spanned text) {
    return new EnrichedSpannedToHtmlConverter(text).convert();
  }

  public static String toHtmlWithDefault(CharSequence text) {
    if (text instanceof Spanned) {
      return toHtml((Spanned) text);
    }
    return Strings.HTML_OPEN + "<p></p>\n" + Strings.HTML_CLOSE;
  }
}
