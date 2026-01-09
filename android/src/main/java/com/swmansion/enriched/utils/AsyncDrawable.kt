package com.swmansion.enriched.utils

import android.content.res.Resources
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorFilter
import android.graphics.PixelFormat
import android.graphics.drawable.Drawable
import androidx.core.graphics.drawable.toDrawable
import com.swmansion.enriched.R
import com.swmansion.enriched.loaders.EnrichedImageLoader

class AsyncDrawable(
  private val url: String,
) : Drawable() {
  private var internalDrawable: Drawable = Color.TRANSPARENT.toDrawable()
  var isLoaded = false
    private set
  var onLoaded: ((Drawable) -> Unit)? = null

  init {
    load()
  }

  private fun load() {
    isLoaded = false
    EnrichedImageLoader.instance.load(url) { bitmap ->
      internalDrawable = bitmap?.toDrawable(Resources.getSystem())
        ?: ResourceManager.getDrawableResource(R.drawable.broken_image)

      isLoaded = true
      onLoaded?.invoke(internalDrawable)
    }
  }

  override fun draw(canvas: Canvas) {
    internalDrawable.draw(canvas)
  }

  override fun setBounds(
    left: Int,
    top: Int,
    right: Int,
    bottom: Int,
  ) {
    super.setBounds(left, top, right, bottom)
    internalDrawable.setBounds(left, top, right, bottom)
  }

  override fun setAlpha(alpha: Int) {
    internalDrawable.alpha = alpha
  }

  override fun setColorFilter(colorFilter: ColorFilter?) {
    internalDrawable.colorFilter = colorFilter
  }

  override fun getOpacity() = PixelFormat.TRANSLUCENT
}
