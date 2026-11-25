package com.swmansion.enriched.text

import android.text.Spannable
import android.text.SpannableString
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.text.SpannedString
import android.util.Log
import com.swmansion.enriched.EnrichedHtmlHost
import com.swmansion.enriched.parser.EnrichedParser
import com.swmansion.enriched.spans.CustomLineHeightSpan
import com.swmansion.enriched.spans.EnrichedImageSpan
import com.swmansion.enriched.spans.interfaces.EnrichedFullWidthSpan
import com.swmansion.enriched.spans.interfaces.EnrichedHostBoundSpan
import com.swmansion.enriched.styles.HtmlStyle

/** Builds the text shown by `EnrichedTextView`, the same for the view and its measurement */
internal object EnrichedTextContent {
  private const val TAG = "EnrichedTextContent"

  fun build(
    params: EnrichedTextParams,
    host: EnrichedHtmlHost,
  ): CharSequence {
    val content = parseHtml(params, host) ?: params.text
    val lineHeightPx = params.lineHeightPx

    if (lineHeightPx <= 0) return content

    // A plain text isn't edited: not in a builder, with room to grow
    val spannable = content as? Spannable ?: SpannableString(content)
    spannable.setSpan(CustomLineHeightSpan(lineHeightPx), 0, spannable.length, Spannable.SPAN_INCLUSIVE_INCLUSIVE)

    return spannable
  }

  /**
   * The text for a view, built elsewhere (by the measurement): immutable, as
   * a TextView adds its spans to a spannable text it shows (its watchers, the
   * selection), while the measurement may read it on the layout thread.
   */
  fun forView(content: CharSequence): CharSequence = if (content is Spanned) SpannedString(content) else content

  /** Whether the text is laid out for its width: its spans take the width of their host (e.g. the horizontal rule) */
  fun dependsOnWidth(content: CharSequence): Boolean = content.hasSpans(EnrichedFullWidthSpan::class.java)

  /**
   * Whether views can show the text at once: its spans don't belong to the
   * view showing them (e.g. the images, redrawn by it once they load)
   */
  fun isShareable(content: CharSequence): Boolean =
    !content.hasSpans(EnrichedImageSpan::class.java) && !content.hasSpans(EnrichedHostBoundSpan::class.java)

  private fun CharSequence.hasSpans(type: Class<*>): Boolean = this is Spanned && getSpans(0, length, type).isNotEmpty()

  private fun parseHtml(
    params: EnrichedTextParams,
    host: EnrichedHtmlHost,
  ): CharSequence? {
    if (!EnrichedParser.isHtml(params.text)) return null

    return try {
      val htmlStyle = HtmlStyle(host, null, params.htmlStyleId)
      val parsed = EnrichedParser.fromHtml(params.text.trim(), htmlStyle, null, host)

      if (parsed is SpannableStringBuilder && !parsed.endsWith('\n')) {
        parsed
      } else {
        SpannableStringBuilder(parsed.trimEnd('\n'))
      }
    } catch (e: Exception) {
      Log.w(TAG, "Error parsing HTML: ${e.message}")
      null
    }
  }
}
