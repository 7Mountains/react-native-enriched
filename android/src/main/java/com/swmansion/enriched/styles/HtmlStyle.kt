package com.swmansion.enriched.styles

import android.graphics.drawable.Drawable
import com.facebook.react.bridge.ReadableMap
import com.swmansion.enriched.EnrichedHtmlHost
import com.swmansion.enriched.drawables.HRDrawable

/**
 * The html style of a view: the style parsed from the props, shared by the
 * views with the same props, and what depends on the view (its width and its
 * font size), updated with [updateHostMetrics].
 *
 * @param styleId The id of a style registered with [HtmlStyleRegistry], parsed
 * once, instead of [style]: 0 for [style], parsed for this view
 */
class HtmlStyle(
  private val view: EnrichedHtmlHost?,
  style: ReadableMap?,
  styleId: Int = 0,
) {
  private val parsed = ParsedHtmlStyle.of(style, view?.hostContext, styleId)

  var editorWidth = 0
    private set

  var olMarginLeft = 0
    private set

  private var hrDrawable: HRDrawable? = null

  init {
    updateHostMetrics()
  }

  /** Reads the width and the font size of the view again, without parsing the style */
  fun updateHostMetrics() {
    editorWidth = view?.editorWidth ?: 0
    olMarginLeft = (view?.fontSize?.toInt() ?: 0) / 2 + parsed.olMarginLeft
  }

  val h1FontSize: Int get() = parsed.h1FontSize
  val h1Bold: Boolean get() = parsed.h1Bold
  val h2FontSize: Int get() = parsed.h2FontSize
  val h2Bold: Boolean get() = parsed.h2Bold
  val h3FontSize: Int get() = parsed.h3FontSize
  val h3Bold: Boolean get() = parsed.h3Bold
  val h4FontSize: Int get() = parsed.h4FontSize
  val h4Bold: Boolean get() = parsed.h4Bold
  val h5FontSize: Int get() = parsed.h5FontSize
  val h5Bold: Boolean get() = parsed.h5Bold
  val h6FontSize: Int get() = parsed.h6FontSize
  val h6Bold: Boolean get() = parsed.h6Bold

  val blockquoteColor: Int? get() = parsed.blockquoteColor
  val blockquoteBorderColor: Int get() = parsed.blockquoteBorderColor
  val blockquoteStripeWidth: Int get() = parsed.blockquoteStripeWidth
  val blockquoteGapWidth: Int get() = parsed.blockquoteGapWidth

  val olGapWidth: Int get() = parsed.olGapWidth
  val olMarkerFontWeight: Int? get() = parsed.olMarkerFontWeight
  val olMarkerColor: Int? get() = parsed.olMarkerColor

  val ulGapWidth: Int get() = parsed.ulGapWidth
  val ulMarginLeft: Int get() = parsed.ulMarginLeft
  val ulBulletSize: Int get() = parsed.ulBulletSize
  val ulBulletColor: Int get() = parsed.ulBulletColor

  val aColor: Int get() = parsed.aColor
  val aUnderline: Boolean get() = parsed.aUnderline

  val codeBlockColor: Int get() = parsed.codeBlockColor
  val codeBlockBackgroundColor: Int get() = parsed.codeBlockBackgroundColor
  val codeBlockRadius: Float get() = parsed.codeBlockRadius

  val inlineCodeColor: Int get() = parsed.inlineCodeColor
  val inlineCodeBackgroundColor: Int get() = parsed.inlineCodeBackgroundColor

  val mentionsStyle: Map<String, MentionStyle> get() = parsed.mentionsStyle
  val contentStyle: Map<String, ContentStyle> get() = parsed.contentStyle

  val dividerThickness: Float get() = parsed.dividerThickness
  val dividerHeight: Float get() = parsed.dividerHeight
  val dividerColor: Int get() = parsed.dividerColor

  val checkboxStyle: CheckboxStyle get() = parsed.checkboxStyle

  val mdf: ContentStyle get() = parsed.mdf

  fun getHorizontalRuleDrawable(): Drawable {
    hrDrawable
      ?.takeIf {
        dividerColor == it.color && dividerThickness == it.thickness
      }?.let { return it }

    return HRDrawable(dividerThickness, dividerColor).also {
      hrDrawable = it
      it.invalidateSelf()
    }
  }

  override fun equals(other: Any?): Boolean {
    if (this === other) return true
    if (other !is HtmlStyle) return false

    return parsed == other.parsed && olMarginLeft == other.olMarginLeft
  }

  override fun hashCode(): Int = 31 * parsed.hashCode() + olMarginLeft

  companion object {
    data class MentionStyle(
      val color: Int,
      val backgroundColor: Int,
      val underline: Boolean,
    )
  }
}
