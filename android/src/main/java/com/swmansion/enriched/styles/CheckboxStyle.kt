package com.swmansion.enriched.styles

import android.graphics.drawable.Drawable
import androidx.appcompat.content.res.AppCompatResources
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.PixelUtil
import com.swmansion.enriched.R

data class CheckboxStyle(
  val imageWidth: Float = 0f,
  val imageHeight: Float = 0f,
  var checkedImage: Drawable?,
  var uncheckedImage: Drawable?,
  val marginLeft: Float = 0f,
  val gapWidth: Float = 8f,
) {
  companion object {
    private fun getDrawableByNameOrNull(
      context: ReactContext,
      name: String,
    ): Drawable? {
      val resId = context.resources.getIdentifier(name, "drawable", context.packageName)
      return if (resId != 0) {
        AppCompatResources.getDrawable(context, resId)
      } else {
        null
      }
    }

    private fun getCheckboxDrawable(
      context: ReactContext,
      enrichedName: String,
      fallbackRes: Int,
    ): Drawable? =
      getDrawableByNameOrNull(context, enrichedName)
        ?: AppCompatResources.getDrawable(context, fallbackRes)

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

      val defaultChecked =
        getCheckboxDrawable(context, "enriched_checkbox_on", R.drawable.checkbox_checked)

      val defaultUnchecked =
        getCheckboxDrawable(context, "enriched_checkbox_off", R.drawable.checkbox_unchecked)

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

      val style =
        CheckboxStyle(
          imageWidth = optFloat("imageWidth", 24f),
          imageHeight = optFloat("imageHeight", 24f),
          checkedImage = defaultChecked,
          uncheckedImage = defaultUnchecked,
          marginLeft = optFloat("marginLeft", 0f),
          gapWidth = optFloat("gapWidth", 8f),
        )

      return style
    }
  }
}
