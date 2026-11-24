package com.swmansion.enriched.styles

import android.content.Context
import android.graphics.Color
import com.facebook.react.bridge.ColorPropConverter
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.PixelUtil
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontWeight
import com.swmansion.enriched.styles.HtmlStyle.Companion.MentionStyle
import kotlin.math.ceil

/**
 * The html style given in the props, the same for every view showing it: the
 * views with the same props (and the measurements of their texts) share it.
 * What depends on the view (its width, its font size) is in [HtmlStyle].
 */
internal data class ParsedHtmlStyle(
  val h1FontSize: Int = 72,
  val h1Bold: Boolean = false,
  val h2FontSize: Int = 64,
  val h2Bold: Boolean = false,
  val h3FontSize: Int = 56,
  val h3Bold: Boolean = false,
  val h4FontSize: Int = 48,
  val h4Bold: Boolean = false,
  val h5FontSize: Int = 40,
  val h5Bold: Boolean = false,
  val h6FontSize: Int = 32,
  val h6Bold: Boolean = false,
  val blockquoteColor: Int? = null,
  val blockquoteBorderColor: Int = Color.BLACK,
  val blockquoteStripeWidth: Int = 2,
  val blockquoteGapWidth: Int = 16,
  val olGapWidth: Int = 16,
  // Without the half of the font size the view adds
  val olMarginLeft: Int = 24,
  val olMarkerFontWeight: Int? = null,
  val olMarkerColor: Int? = null,
  val ulGapWidth: Int = 16,
  val ulMarginLeft: Int = 24,
  val ulBulletSize: Int = 8,
  val ulBulletColor: Int = Color.BLACK,
  val aColor: Int = Color.BLACK,
  val aUnderline: Boolean = true,
  val codeBlockColor: Int = Color.BLACK,
  val codeBlockBackgroundColor: Int = Color.BLACK,
  val codeBlockRadius: Float = 4f,
  val inlineCodeColor: Int = Color.BLACK,
  val inlineCodeBackgroundColor: Int = Color.BLACK,
  val mentionsStyle: Map<String, MentionStyle> = emptyMap(),
  val contentStyle: Map<String, ContentStyle> = emptyMap(),
  val dividerThickness: Float = 2.0f,
  val dividerHeight: Float = 24.0f,
  val dividerColor: Int = Color.GRAY,
  val checkboxStyle: CheckboxStyle = CheckboxStyle.fromReadableMap(null, null),
  val mdf: ContentStyle = ContentStyle.default(),
) {
  companion object {
    // Default values are ignored as they are specified on the JS side: they're
    // used only until the props are set
    private val DEFAULT = ParsedHtmlStyle()

    private const val CACHE_SIZE = 8

    private data class CacheKey(
      val styleId: Int,
      // The parsed values are in pixels and the drawables depend on the theme
      val density: Float,
      val fontScale: Float,
      val uiMode: Int,
    )

    private val cache =
      object : LinkedHashMap<CacheKey, ParsedHtmlStyle>(CACHE_SIZE, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<CacheKey, ParsedHtmlStyle>?): Boolean = size > CACHE_SIZE
      }

    /**
     * @param styleId The id of a style registered with [HtmlStyleRegistry],
     * parsed once, instead of [style]: 0 for [style], parsed every time
     */
    fun of(
      style: ReadableMap?,
      context: Context?,
      styleId: Int,
    ): ParsedHtmlStyle {
      if (styleId == 0 || context == null) {
        return if (style == null) DEFAULT else parse(style, context)
      }

      val configuration = context.resources.configuration
      val key =
        CacheKey(
          styleId,
          context.resources.displayMetrics.density,
          configuration.fontScale,
          configuration.uiMode,
        )

      synchronized(cache) { cache[key] }?.let { return it }

      val source = HtmlStyleRegistry.get(styleId) ?: return DEFAULT
      val parsed = parse(source, context)
      synchronized(cache) { cache[key] = parsed }
      return parsed
    }

    private fun parse(
      style: ReadableMap,
      context: Context?,
    ): ParsedHtmlStyle {
      val reactContext = context as ReactContext

      val h1Style = style.getMap("h1")
      val h2Style = style.getMap("h2")
      val h3Style = style.getMap("h3")
      val h4Style = style.getMap("h4")
      val h5Style = style.getMap("h5")
      val h6Style = style.getMap("h6")
      val blockquoteStyle = style.getMap("blockquote")
      val olStyle = style.getMap("ol")
      val ulStyle = style.getMap("ul")
      val aStyle = style.getMap("a")
      val codeBlockStyle = style.getMap("codeblock")
      val inlineCodeStyle = style.getMap("code")
      val dividerStyle = style.getMap("divider")

      return ParsedHtmlStyle(
        h1FontSize = parseFloat(h1Style, "fontSize").toInt(),
        h1Bold = h1Style?.getBoolean("bold") == true,
        h2FontSize = parseFloat(h2Style, "fontSize").toInt(),
        h2Bold = h2Style?.getBoolean("bold") == true,
        h3FontSize = parseFloat(h3Style, "fontSize").toInt(),
        h3Bold = h3Style?.getBoolean("bold") == true,
        h4FontSize = parseFloat(h4Style, "fontSize").toInt(),
        h4Bold = h4Style?.getBoolean("bold") == true,
        h5FontSize = parseFloat(h5Style, "fontSize").toInt(),
        h5Bold = h5Style?.getBoolean("bold") == true,
        h6FontSize = parseFloat(h6Style, "fontSize").toInt(),
        h6Bold = h6Style?.getBoolean("bold") == true,
        blockquoteColor = parseOptionalColor(blockquoteStyle, "color", reactContext),
        blockquoteBorderColor = parseColor(blockquoteStyle, "borderColor", reactContext),
        blockquoteGapWidth = parseFloat(blockquoteStyle, "gapWidth").toInt(),
        blockquoteStripeWidth = parseFloat(blockquoteStyle, "borderWidth").toInt(),
        olMarginLeft = parseFloat(olStyle, "marginLeft").toInt(),
        olGapWidth = parseFloat(olStyle, "gapWidth").toInt(),
        olMarkerColor = parseOptionalColor(olStyle, "markerColor", reactContext),
        olMarkerFontWeight = parseOptionalFontWeight(olStyle, "markerFontWeight"),
        ulBulletColor = parseColor(ulStyle, "bulletColor", reactContext),
        ulGapWidth = parseFloat(ulStyle, "gapWidth").toInt(),
        ulMarginLeft = parseFloat(ulStyle, "marginLeft").toInt(),
        ulBulletSize = parseFloat(ulStyle, "bulletSize").toInt(),
        aColor = parseColor(aStyle, "color", reactContext),
        aUnderline = parseIsUnderline(aStyle),
        codeBlockRadius = parseFloat(codeBlockStyle, "borderRadius"),
        codeBlockColor = parseColor(codeBlockStyle, "color", reactContext),
        codeBlockBackgroundColor = parseColorWithOpacity(codeBlockStyle, "backgroundColor", 80, reactContext),
        inlineCodeColor = parseColor(inlineCodeStyle, "color", reactContext),
        inlineCodeBackgroundColor = parseColorWithOpacity(inlineCodeStyle, "backgroundColor", 80, reactContext),
        mentionsStyle = parseMentionsStyle(style.getMap("mention"), reactContext),
        contentStyle = ContentStyle.parseComplex(style.getMap("content"), reactContext),
        dividerHeight = parseFloat(dividerStyle, "height"),
        dividerThickness = parseFloat(dividerStyle, "thickness"),
        dividerColor = parseColor(dividerStyle, "color", reactContext),
        checkboxStyle = CheckboxStyle.fromReadableMap(style.getMap("checkbox"), reactContext),
        mdf = ContentStyle.fromReadableMap(style.getMap("mdf"), reactContext),
      )
    }

    private fun parseFloat(
      map: ReadableMap?,
      key: String,
    ): Float {
      val safeMap = ensureValueIsSet(map, key)

      val value = safeMap.getDouble(key)
      return ceil(PixelUtil.toPixelFromSP(value))
    }

    private fun parseColorWithOpacity(
      map: ReadableMap?,
      key: String,
      opacity: Int,
      context: ReactContext,
    ): Int {
      val color = parseColor(map, key, context)
      return withOpacity(color, opacity)
    }

    private fun parseOptionalColor(
      map: ReadableMap?,
      key: String,
      context: ReactContext,
    ): Int? {
      if (map == null) return null
      if (!map.hasKey(key)) return null
      if (map.isNull(key)) return null

      return parseColor(map, key, context)
    }

    private fun parseColor(
      map: ReadableMap?,
      key: String,
      context: ReactContext,
    ): Int {
      val safeMap = ensureValueIsSet(map, key)

      val color = safeMap.getDouble(key)
      val parsedColor = ColorPropConverter.getColor(color, context)
      if (parsedColor == null) {
        throw Error("Specified color value is not supported: $color")
      }

      return parsedColor
    }

    private fun withOpacity(
      color: Int,
      alpha: Int,
    ): Int {
      // Do not apply opacity to transparent color
      if (Color.alpha(color) == 0) return color
      val a = alpha.coerceIn(0, 255)
      return (color and 0x00FFFFFF) or (a shl 24)
    }

    private fun parseIsUnderline(map: ReadableMap?): Boolean {
      val underline = map?.getString("textDecorationLine")
      val isEnabled = underline == "underline"
      val isDisabled = underline == "none"

      if (isEnabled) return true
      if (isDisabled) return false

      throw Error("Specified textDecorationLine value is not supported: $underline. Supported values are 'underline' and 'none'.")
    }

    private fun ensureValueIsSet(
      map: ReadableMap?,
      key: String,
    ): ReadableMap {
      if (map == null) throw Error("Style map cannot be null")

      if (!map.hasKey(key)) throw Error("Style map must contain key: $key")

      if (map.isNull(key)) throw Error("Style map cannot contain null value for key: $key")

      return map
    }

    private fun parseMentionsStyle(
      mentionsStyle: ReadableMap?,
      context: ReactContext,
    ): Map<String, MentionStyle> {
      if (mentionsStyle == null) throw Error("Mentions style cannot be null")

      val parsedMentionsStyle: MutableMap<String, MentionStyle> = mutableMapOf()

      val iterator = mentionsStyle.keySetIterator()
      while (iterator.hasNextKey()) {
        val key = iterator.nextKey()
        val value = mentionsStyle.getMap(key)

        if (value == null) throw Error("Mention style for key '$key' cannot be null")

        val color = parseColor(value, "color", context)
        val backgroundColor = parseColorWithOpacity(value, "backgroundColor", 80, context)
        val isUnderline = parseIsUnderline(value)
        parsedMentionsStyle[key] = MentionStyle(color, backgroundColor, isUnderline)
      }

      return parsedMentionsStyle
    }

    private fun parseOptionalFontWeight(
      map: ReadableMap?,
      key: String,
    ): Int? {
      if (map == null) return null
      if (!map.hasKey(key)) return null
      if (map.isNull(key)) return null

      val fontWeight = map.getString(key) ?: return null
      return parseFontWeight(fontWeight)
    }
  }
}
