package com.swmansion.enriched.parser

import android.graphics.drawable.Drawable
import android.text.Spanned
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.constants.Strings
import com.swmansion.enriched.styles.HtmlStyle
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import org.ccil.cowan.tagsoup.HTMLSchema
import org.ccil.cowan.tagsoup.Parser
import org.xml.sax.SAXNotRecognizedException
import org.xml.sax.SAXNotSupportedException

/**
 * Most of the code in this file is copied from the Android source code and adjusted to our needs.
 * For the reference see [docs](https://android.googlesource.com/platform/frameworks/base/+/refs/heads/master/core/java/android/text/Html.java)
 */
object EnrichedParser {
  /**
   * Lazy initialization holder for HTML parser. This will a) be preloaded by the zygote, or
   * b) not loaded until absolutely necessary.
   */
  private val htmlSchema: HTMLSchema by lazy(LazyThreadSafetyMode.PUBLICATION) {
    HTMLSchema()
  }

  private val htmlScope =
    CoroutineScope(SupervisorJob() + Dispatchers.Default)

  /**
   * Returns displayable styled text from the provided HTML string. Any &lt;img&gt; tags in the HTML
   * will use the specified ImageGetter to request a representation of the image (use null if you
   * don't want this) and the specified TagHandler to handle unknown tags (specify null if you don't
   * want this).
   *
   *
   * This uses TagSoup to handle real HTML, including all of the brokenness found in the wild.
   */
  fun fromHtml(
    source: String?,
    style: HtmlStyle,
    imageGetter: ImageGetter?,
    textInputView: EnrichedTextInputView,
  ): Spanned {
    val parser = Parser()
    try {
      parser.setProperty(Parser.schemaProperty, htmlSchema)
    } catch (e: SAXNotRecognizedException) {
      // Should not happen.
      throw RuntimeException(e)
    } catch (e: SAXNotSupportedException) {
      throw RuntimeException(e)
    }

    return HtmlToSpannedConverter(source, style, imageGetter, parser, textInputView).convert()
  }

  fun toHtml(
    text: Spanned?,
    pretify: Boolean = false,
  ): String? = EnrichedSpannedToHtmlConverter(text, pretify).convert()

  fun toHtmlWithDefault(
    text: CharSequence?,
    pretify: Boolean,
  ): String? {
    if (text is Spanned) {
      return toHtml(text, pretify)
    }
    return Strings.HTML_OPEN + "<p></p>\n" + Strings.HTML_CLOSE
  }

  /** Retrieves images for HTML &lt;img&gt; tags.  */
  interface ImageGetter {
    /**
     * This method is called when the HTML parser encounters an &lt;img&gt; tag. The `source
     ` *  argument is the string from the "src" attribute; the return value should be a
     * Drawable representation of the image or `null` for a generic replacement image.
     * Make sure you call setBounds() on your Drawable if it doesn't already have its bounds set.
     */
    fun loadImage(
      source: String?,
      callbacks: Callbacks?,
      maxWidth: Int,
    )

    fun loadImage(
      source: String?,
      callbacks: Callbacks?,
      maxWidth: Int,
      minWidth: Int,
    )

    interface Callbacks {
      fun onImageFailed()

      fun onImageLoaded(drawable: Drawable?)

      fun onImageLoading(drawable: Drawable?)
    }
  }
}
