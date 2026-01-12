package com.swmansion.enriched.styles

import android.graphics.Color
import com.facebook.react.bridge.ColorPropConverter
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.PixelUtil
import com.facebook.react.views.text.ReactTypefaceUtils

data class ContentStyle(
  val backgroundColor: Int?,
  val textColor: Int?,
  val borderColor: Int?,
  val borderWidth: Float,
  val borderStyle: String?,
  val borderRadius: Float,
  val marginTop: Float,
  val marginBottom: Float,
  val marginLeft: Float,
  val marginRight: Float,
  val paddingTop: Float,
  val paddingBottom: Float,
  val paddingLeft: Float,
  val paddingRight: Float,
  val imageWidth: Float?,
  val imageHeight: Float?,
  val imageBorderRadiusTopLeft: Float,
  val imageBorderRadiusTopRight: Float,
  val imageBorderRadiusBottomLeft: Float,
  val imageBorderRadiusBottomRight: Float,
  val imageResizeMode: String?,
  val fallbackImageURI: String?,
  val width: Float,
  val height: Float,
  val fontSize: Float,
  val typefaceStyle: Int,
) {
  companion object {
    fun fromReadableMap(
      map: ReadableMap,
      context: ReactContext,
    ): ContentStyle {
      fun dip(
        key: String,
        def: Double = 0.0,
      ): Float =
        if (map.hasKey(key) && !map.isNull(key)) {
          PixelUtil.toPixelFromDIP(map.getDouble(key))
        } else {
          def.toFloat()
        }

      fun raw(
        key: String,
        def: Double = 0.0,
      ): Float =
        if (map.hasKey(key) && !map.isNull(key)) {
          map.getDouble(key).toFloat()
        } else {
          def.toFloat()
        }

      fun txt(
        key: String,
        def: String? = null,
      ): String? =
        if (map.hasKey(key) && !map.isNull(key)) {
          map.getString(key)
        } else {
          def
        }

      fun clr(
        key: String,
        def: Int?,
      ): Int? =
        if (map.hasKey(key) && !map.isNull(key)) {
          ColorPropConverter.getColor(map.getDouble(key), context)
        } else {
          def
        }

      return ContentStyle(
        backgroundColor = clr("backgroundColor", null),
        textColor = clr("textColor", Color.BLACK),
        borderColor = clr("borderColor", null),
        borderWidth = dip("borderWidth"),
        borderStyle = txt("borderStyle", "solid"),
        borderRadius = dip("borderRadius"),
        marginTop = dip("marginTop"),
        marginBottom = dip("marginBottom"),
        marginLeft = dip("marginLeft"),
        marginRight = dip("marginRight"),
        paddingTop = dip("paddingTop"),
        paddingBottom = dip("paddingBottom"),
        paddingLeft = dip("paddingLeft"),
        paddingRight = dip("paddingRight"),
        imageWidth = raw("imageWidth"),
        imageHeight = raw("imageHeight"),
        imageBorderRadiusTopLeft = dip("imageBorderRadiusTopLeft"),
        imageBorderRadiusTopRight = dip("imageBorderRadiusTopRight"),
        imageBorderRadiusBottomLeft = dip("imageBorderRadiusBottomLeft"),
        imageBorderRadiusBottomRight = dip("imageBorderRadiusBottomRight"),
        imageResizeMode = txt("imageResizeMode", "cover"),
        fallbackImageURI = txt("fallbackImageURI"),
        width = dip("width"),
        height = dip("height", 50.0),
        fontSize = raw("fontSize", 14.0),
        typefaceStyle = ReactTypefaceUtils.parseFontWeight(txt("fontWeight", "400")),
      )
    }

    fun parseComplex(
      map: ReadableMap?,
      context: ReactContext?,
    ): Map<String, ContentStyle> {
      if (map == null || context == null) return emptyMap()

      val result = mutableMapOf<String, ContentStyle>()
      val iterator = map.keySetIterator()

      while (iterator.hasNextKey()) {
        val key = iterator.nextKey()
        val section = map.getMap(key) ?: continue
        result[key] = fromReadableMap(section, context)
      }

      return result
    }
  }
}
