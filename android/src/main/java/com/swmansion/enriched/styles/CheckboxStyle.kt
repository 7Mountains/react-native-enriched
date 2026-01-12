package com.swmansion.enriched.styles

import android.content.res.Resources
import android.graphics.drawable.Drawable
import androidx.appcompat.content.res.AppCompatResources
import androidx.core.graphics.drawable.toDrawable
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.PixelUtil
import com.swmansion.enriched.R
import com.swmansion.enriched.loaders.EnrichedImageLoader

data class CheckboxStyle(
  val imageWidth: Float = 0f,
  val imageHeight: Float = 0f,
  var checkedImage: Drawable?,
  var uncheckedImage: Drawable?,
  val marginLeft: Float = 0f,
  val gapWidth: Float = 8f,
) {
  companion object {
    fun loadImageWithFallback(
      src: String?,
      fallback: Drawable?,
      assign: (Drawable?) -> Unit,
    ) {
      EnrichedImageLoader.instance.load(src) {
        assign(it?.toDrawable(Resources.getSystem()) ?: fallback)
      }
    }

    fun fromReadableMap(
      map: ReadableMap?,
      context: ReactContext?,
    ): CheckboxStyle {
      if (context == null) {
        return CheckboxStyle(
          imageWidth = 24f,
          imageHeight = 24f,
          checkedImage = null,
          uncheckedImage = null,
        )
      }

      val defaultChecked = AppCompatResources.getDrawable(context, R.drawable.checkbox_checked)
      val defaultUnchecked = AppCompatResources.getDrawable(context, R.drawable.checkbox_unchecked)

      if (map == null) {
        return CheckboxStyle(
          imageWidth = 24f,
          imageHeight = 24f,
          checkedImage = defaultChecked,
          uncheckedImage = defaultUnchecked,
        )
      }

      fun optFloat(
        key: String,
        def: Float,
      ): Float =
        if (map.hasKey(key) && !map.isNull(key)) {
          PixelUtil.toPixelFromDIP(map.getDouble(key))
        } else {
          def
        }

      val checkedSource = map.getString("checkedImage")
      val uncheckedSource = map.getString("uncheckedImage")

      val style =
        CheckboxStyle(
          imageWidth = optFloat("imageWidth", 24f),
          imageHeight = optFloat("imageHeight", 24f),
          checkedImage = defaultChecked,
          uncheckedImage = defaultUnchecked,
          marginLeft = optFloat("marginLeft", 0f),
          gapWidth = optFloat("gapWidth", 8f),
        )

      loadImageWithFallback(checkedSource, defaultChecked) {
        style.checkedImage = it
      }
      loadImageWithFallback(uncheckedSource, defaultUnchecked) {
        style.uncheckedImage = it
      }

      return style
    }
  }
}
