package com.swmansion.enriched.text

import android.content.res.AssetManager
import android.graphics.Typeface
import android.text.TextUtils
import com.facebook.react.common.ReactConstants
import com.facebook.react.uimanager.PixelUtil
import com.swmansion.enriched.utils.TypefaceCache
import kotlin.math.ceil

/** What the layout of the text depends on, the same for the view and its measurement */
internal data class EnrichedTextParams(
  val text: String = "",
  val htmlStyleId: Int = 0,
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

  val ellipsize: TextUtils.TruncateAt?
    get() =
      when (ellipsizeMode) {
        "head" -> TextUtils.TruncateAt.START
        "middle" -> TextUtils.TruncateAt.MIDDLE
        "clip" -> null
        else -> TextUtils.TruncateAt.END
      }

  fun hasSameTypeface(other: EnrichedTextParams): Boolean =
    fontFamily == other.fontFamily && fontWeight == other.fontWeight && fontStyle == other.fontStyle

  fun hasSameLines(other: EnrichedTextParams): Boolean = numberOfLines == other.numberOfLines && ellipsizeMode == other.ellipsizeMode

  fun typeface(assets: AssetManager): Typeface = TypefaceCache.get(fontFamily, fontStyle, fontWeight, assets)

  private fun toPixels(value: Float): Float = if (allowFontScaling) PixelUtil.toPixelFromSP(value) else PixelUtil.toPixelFromDIP(value)

  companion object {
    /** The font size of React Native's `Text` */
    const val DEFAULT_FONT_SIZE = 14f
  }
}
