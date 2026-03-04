package com.swmansion.enriched.styles

import android.graphics.Color
import com.facebook.react.bridge.ColorPropConverter
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.PixelUtil
import com.facebook.react.views.text.ReactTypefaceUtils

data class MDFStyle(
  val height: Float,
  val imageUri: String?,
  val borderRadius: Float,
  val borderWidth: Float,
  val borderColor: Int?,
  val stripeWidth: Float,
  val fontSize: Float,
  val typefaceStyle: Int,
  val marginLeft: Float,
  val marginRight: Float,
  val marginTop: Float,
  val marginBottom: Float,
  val textColor: Int?,
  val backgroundColor: Int?,
  val imageHeight: Float,
  val imageWidth: Float,
  val imageBorderRadius: Float,
  val paddingTop: Float,
  val paddingBottom: Float,
  val paddingRight: Float,
  val paddingLeft: Float,
  val imageContainerHeight: Float,
  val imageContainerWidth: Float,
) {
  companion object {
    fun default(): MDFStyle =
      MDFStyle(
        height = 40f,
        imageUri = null,
        borderRadius = 8f,
        borderWidth = 0f,
        borderColor = null,
        stripeWidth = 4f,
        fontSize = 14f,
        typefaceStyle = ReactTypefaceUtils.parseFontWeight("400"),
        marginLeft = 0f,
        marginRight = 0f,
        marginTop = 0f,
        marginBottom = 0f,
        textColor = Color.BLACK,
        backgroundColor = null,
        imageHeight = 20f,
        imageWidth = 20f,
        imageBorderRadius = 4f,
        paddingTop = 8f,
        paddingBottom = 8f,
        paddingRight = 8f,
        paddingLeft = 8f,
        imageContainerHeight = 24f,
        imageContainerWidth = 24f,
      )

    fun fromMap(
      map: ReadableMap?,
      context: ReactContext?,
    ): MDFStyle {
      if (map == null || context == null) {
        return default()
      }
      return fromReadableMap(map, context)
    }

    fun fromReadableMap(
      map: ReadableMap,
      context: ReactContext,
    ): MDFStyle {
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

      return MDFStyle(
        height = dip("height", 40.0),
        imageUri = txt("imageUri"),
        borderRadius = dip("borderRadius"),
        borderWidth = dip("borderWidth"),
        borderColor = clr("borderColor", null),
        stripeWidth = dip("stripeWidth"),
        fontSize = raw("fontSize", 14.0),
        typefaceStyle = ReactTypefaceUtils.parseFontWeight(txt("fontWeight", "400")),
        marginLeft = dip("marginLeft"),
        marginRight = dip("marginRight"),
        marginTop = dip("marginTop"),
        marginBottom = dip("marginBottom"),
        textColor = clr("textColor", Color.BLACK),
        backgroundColor = clr("backgroundColor", null),
        imageHeight = dip("imageHeight"),
        imageWidth = dip("imageWidth"),
        imageBorderRadius = dip("imageBorderRadius"),
        paddingTop = dip("paddingTop"),
        paddingBottom = dip("paddingBottom"),
        paddingRight = dip("paddingRight"),
        paddingLeft = dip("paddingLeft"),
        imageContainerHeight = dip("imageContainerHeight"),
        imageContainerWidth = dip("imageContainerWidth"),
      )
    }
  }
}
