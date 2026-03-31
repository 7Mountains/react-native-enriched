package com.swmansion.enriched.styles

import android.graphics.Color
import com.facebook.react.bridge.ColorPropConverter
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.PixelUtil
import com.facebook.react.views.text.ReactTypefaceUtils

data class ContentStyle(
  val container: ContainerStyle,
  val title: TextStyle,
  val description: TextStyle,
  val image: ImageStyle,
  val imageContainer: ImageContainerStyle,
  val textContainer: TextContainerStyle,
  val fallbackImageURI: String?,
  val imageUri: String?,
) {
  companion object {
    data class ContainerStyle(
      val backgroundColor: Int?,
      val borderColor: Int?,
      val borderWidth: Float,
      val borderLeftWidth: Float,
      val borderRadius: Float,
      val borderStyle: BorderStyle,
      val padding: Insets,
      val margin: Insets,
      val minHeight: Float,
    )

    data class TextStyle(
      val color: Int,
      val fontSize: Float,
      val typefaceStyle: Int,
      val fontFamily: String?,
    )

    data class ImageStyle(
      val width: Float,
      val height: Float,
      val resizeMode: ImageResizeMode,
    )

    data class ImageContainerStyle(
      val width: Float,
      val height: Float,
      val borderRadius: Float,
    )

    data class TextContainerStyle(
      val padding: Insets,
      val margin: Insets,
    )

    data class Insets(
      val top: Float,
      val left: Float,
      val bottom: Float,
      val right: Float,
    )

    enum class BorderStyle {
      SOLID,
      DASHED,
      DOTTED,
      NONE,
    }

    enum class ImageResizeMode {
      COVER,
      CONTAIN,
      STRETCH,
    }

    fun parseInsets(
      map: ReadableMap?,
      prefix: String = "padding",
    ): Insets {
      if (map == null) return Insets(0f, 0f, 0f, 0f)

      fun v(key: String) =
        if (map.hasKey(key) && !map.isNull(key)) {
          PixelUtil.toPixelFromDIP(map.getDouble(key))
        } else {
          0f
        }

      return Insets(
        top = v("${prefix}Top"),
        left = v("${prefix}Left"),
        bottom = v("${prefix}Bottom"),
        right = v("${prefix}Right"),
      )
    }

    fun parseBorderStyle(value: String?): BorderStyle =
      when (value) {
        "dashed" -> BorderStyle.DASHED
        "dotted" -> BorderStyle.DOTTED
        "none" -> BorderStyle.NONE
        else -> BorderStyle.SOLID
      }

    fun parseResizeMode(value: String?): ImageResizeMode =
      when (value) {
        "contain" -> ImageResizeMode.CONTAIN
        "stretch" -> ImageResizeMode.STRETCH
        else -> ImageResizeMode.COVER
      }

    fun fromReadableMap(
      map: ReadableMap?,
      context: ReactContext,
    ): ContentStyle {
      if (map == null) {
        return default()
      }

      fun obj(key: String): ReadableMap? = if (map.hasKey(key) && !map.isNull(key)) map.getMap(key) else null

      fun dip(
        map: ReadableMap?,
        key: String,
        def: Float = 0f,
      ): Float =
        if (map != null && map.hasKey(key) && !map.isNull(key)) {
          PixelUtil.toPixelFromDIP(map.getDouble(key))
        } else {
          def
        }

      fun str(
        map: ReadableMap?,
        key: String,
        def: String? = null,
      ): String? =
        if (map != null && map.hasKey(key) && !map.isNull(key)) {
          map.getString(key)
        } else {
          def
        }

      fun clr(
        map: ReadableMap?,
        key: String,
        def: Int?,
      ): Int? =
        if (map != null && map.hasKey(key) && !map.isNull(key)) {
          ColorPropConverter.getColor(map.getDouble(key), context)
        } else {
          def
        }

      val container = obj("container")
      val title = obj("title")
      val description = obj("description")
      val image = obj("image")
      val imageContainer = obj("imageContainer")
      val textContainer = obj("textContainer")

      return ContentStyle(
        container =
          ContainerStyle(
            backgroundColor = clr(container, "backgroundColor", null),
            borderColor = clr(container, "borderColor", null),
            borderWidth = dip(container, "borderWidth"),
            borderRadius = dip(container, "borderRadius"),
            borderStyle = parseBorderStyle(str(container, "borderStyle")),
            padding = parseInsets(container),
            margin = parseInsets(container, "margin"),
            minHeight = dip(container, "minHeight"),
            borderLeftWidth = dip(container, "borderLeftWidth"),
          ),
        title =
          TextStyle(
            color = clr(title, "color", Color.BLACK)!!,
            fontSize = dip(title, "fontSize", 14f),
            typefaceStyle = ReactTypefaceUtils.parseFontWeight(str(title, "fontWeight")),
            fontFamily = str(title, "fontFamily"),
          ),
        description =
          TextStyle(
            color = clr(description, "color", Color.GRAY)!!,
            fontSize = dip(description, "fontSize", 14f),
            typefaceStyle = ReactTypefaceUtils.parseFontWeight(str(description, "fontWeight")),
            fontFamily = str(description, "fontFamily"),
          ),
        image =
          ImageStyle(
            width = dip(image, "width"),
            height = dip(image, "height"),
            resizeMode = parseResizeMode(str(image, "resizeMode")),
          ),
        imageContainer =
          ImageContainerStyle(
            width = dip(imageContainer, "width"),
            height = dip(imageContainer, "height"),
            borderRadius = dip(imageContainer, "borderRadius"),
          ),
        textContainer =
          TextContainerStyle(
            padding = parseInsets(textContainer),
            margin = parseInsets(textContainer, "margin"),
          ),
        fallbackImageURI = str(map, "fallbackImageURI"),
        imageUri = str(map, "imageUri"),
      )
    }

    fun default(): ContentStyle =
      ContentStyle(
        container =
          ContainerStyle(
            backgroundColor = null,
            borderColor = null,
            borderWidth = 0f,
            borderRadius = 0f,
            borderLeftWidth = 0f,
            borderStyle = BorderStyle.SOLID,
            padding = Insets(0f, 0f, 0f, 0f),
            margin = Insets(0f, 0f, 0f, 0f),
            minHeight = 56f,
          ),
        title =
          TextStyle(
            color = Color.BLACK,
            fontSize = 14f,
            typefaceStyle = ReactTypefaceUtils.parseFontWeight("400"),
            fontFamily = null,
          ),
        description =
          TextStyle(
            color = Color.GRAY,
            fontSize = 14f,
            typefaceStyle = ReactTypefaceUtils.parseFontWeight("400"),
            fontFamily = null,
          ),
        image =
          ImageStyle(
            width = 40f,
            height = 40f,
            resizeMode = ImageResizeMode.COVER,
          ),
        imageContainer =
          ImageContainerStyle(
            width = 56f,
            height = 56f,
            borderRadius = 0f,
          ),
        textContainer =
          TextContainerStyle(
            padding = Insets(0f, 0f, 0f, 0f),
            margin = Insets(0f, 0f, 0f, 0f),
          ),
        fallbackImageURI = null,
        imageUri = null,
      )

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
