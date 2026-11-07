package com.swmansion.enriched.text

import android.content.res.AssetManager
import android.graphics.Typeface
import android.text.TextUtils
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.common.ReactConstants
import com.facebook.react.uimanager.PixelUtil
import com.facebook.react.uimanager.ViewProps
import com.facebook.react.views.text.ReactTypefaceUtils
import kotlin.math.ceil

/** What the layout of the text depends on, the same for the view and its measurement */
internal data class EnrichedTextParams(
  val text: String = "",
  val htmlStyle: ReadableMap? = null,
  val fontSize: Float = DEFAULT_FONT_SIZE,
  val lineHeight: Float = 0f,
  val fontFamily: String? = null,
  val fontWeight: Int = ReactConstants.UNSET,
  val fontStyle: Int = ReactConstants.UNSET,
  val allowFontScaling: Boolean = true,
  val numberOfLines: Int = 0,
  val ellipsizeMode: String? = null,
) {
  val fontSizePx: Float
    get() = ceil(toPixels(if (fontSize > 0f) fontSize else DEFAULT_FONT_SIZE))

  val lineHeightPx: Int
    get() = if (lineHeight > 0f) ceil(toPixels(lineHeight)).toInt() else 0

  /** Identifies the html style, e.g. in a cache key: maps of the same style are equal */
  val htmlStyleKey: Int by lazy { htmlStyle?.toHashMap()?.hashCode() ?: 0 }

  val ellipsize: TextUtils.TruncateAt?
    get() =
      when (ellipsizeMode) {
        "head" -> TextUtils.TruncateAt.START
        "middle" -> TextUtils.TruncateAt.MIDDLE
        "clip" -> null
        else -> TextUtils.TruncateAt.END
      }

  fun typeface(assets: AssetManager): Typeface = ReactTypefaceUtils.applyStyles(null, fontStyle, fontWeight, fontFamily, assets)

  private fun toPixels(value: Float): Float = if (allowFontScaling) PixelUtil.toPixelFromSP(value) else PixelUtil.toPixelFromDIP(value)

  companion object {
    /** The font size of React Native's `Text` */
    const val DEFAULT_FONT_SIZE = 14f

    private const val TEXT = "text"
    private const val HTML_STYLE = "htmlStyle"

    fun fromProps(props: ReadableMap?): EnrichedTextParams {
      if (props == null) return EnrichedTextParams()

      return EnrichedTextParams(
        text = props.optString(TEXT) ?: "",
        htmlStyle = if (props.hasKey(HTML_STYLE) && !props.isNull(HTML_STYLE)) props.getMap(HTML_STYLE) else null,
        fontSize = props.optFloat(ViewProps.FONT_SIZE),
        lineHeight = props.optFloat(ViewProps.LINE_HEIGHT),
        fontFamily = props.optString(ViewProps.FONT_FAMILY)?.takeIf { it.isNotEmpty() },
        fontWeight = ReactTypefaceUtils.parseFontWeight(props.optString(ViewProps.FONT_WEIGHT)?.takeIf { it.isNotEmpty() }),
        fontStyle = ReactTypefaceUtils.parseFontStyle(props.optString(ViewProps.FONT_STYLE)?.takeIf { it.isNotEmpty() }),
        allowFontScaling =
          !props.hasKey(ViewProps.ALLOW_FONT_SCALING) ||
            props.isNull(ViewProps.ALLOW_FONT_SCALING) ||
            props.getBoolean(ViewProps.ALLOW_FONT_SCALING),
        numberOfLines =
          if (props.hasKey(ViewProps.NUMBER_OF_LINES) && !props.isNull(ViewProps.NUMBER_OF_LINES)) {
            props.getInt(ViewProps.NUMBER_OF_LINES)
          } else {
            0
          },
        ellipsizeMode = props.optString(ViewProps.ELLIPSIZE_MODE),
      )
    }

    private fun ReadableMap.optString(key: String): String? = if (hasKey(key) && !isNull(key)) getString(key) else null

    private fun ReadableMap.optFloat(key: String): Float = if (hasKey(key) && !isNull(key)) getDouble(key).toFloat() else 0f
  }
}
