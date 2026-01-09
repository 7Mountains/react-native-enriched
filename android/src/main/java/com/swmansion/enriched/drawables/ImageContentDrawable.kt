package com.swmansion.enriched.drawables

import android.content.res.Resources
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.Rect
import android.graphics.drawable.Drawable
import androidx.core.graphics.drawable.toDrawable
import androidx.core.graphics.withClip
import com.swmansion.enriched.R
import com.swmansion.enriched.loaders.EnrichedImageLoader
import com.swmansion.enriched.styles.HtmlStyle
import com.swmansion.enriched.utils.ResourceManager

class ImageContentDrawable(
  private val contentStyle: HtmlStyle.Companion.ContentStyle,
  private val text: String,
  private val src: String,
) : BaseContentDrawable(contentStyle, text) {
  val imageSpacing = 8.0f * density

  var isLoaded = false

  private var imageDrawable: Drawable? = null

  private val onImageLoaded: (Drawable?) -> Unit = { drawable ->
    imageDrawable = drawable
    onContentLoadEnd?.invoke()
    isLoaded = true
    invalidateSelf()
  }

  init {
    loadImageAsync()
  }

  override fun draw(canvas: Canvas) {
    measureText()

    val left = bounds.left.toFloat()
    val top = bounds.top.toFloat()
    val right = bounds.right.toFloat()
    val bottom = bounds.bottom.toFloat()

    val contentLeft = left + contentStyle.marginLeft
    val contentTop = top + contentStyle.marginTop
    val contentRight = right - contentStyle.marginRight
    val contentBottom = bottom - contentStyle.marginBottom

    drawBackground(canvas, contentLeft, contentTop, contentRight, contentBottom)
    drawBorder(canvas, contentLeft, contentTop, contentRight, contentBottom)

    val inner = applyPadding(contentLeft, contentTop, contentRight, contentBottom)

    val imageRect = computeImageRect(inner)

    drawImage(canvas, imageRect)

    val paddedCenterY = (inner.top + inner.bottom) / 2f
    val fm = textPaint.fontMetrics
    val baseline = paddedCenterY - (fm.ascent + fm.descent) / 2f

    val textX = imageRect.right + imageSpacing
    canvas.drawText(text, textX, baseline, textPaint)
  }

  private fun computeImageRect(area: Companion.Box): Companion.Box {
    val w =
      when {
        contentStyle.imageWidth != null -> contentStyle.imageWidth * density
        (imageDrawable?.intrinsicWidth ?: 0) > 0 -> imageDrawable!!.intrinsicWidth.toFloat()
        else -> 24f * density
      }

    val h =
      when {
        contentStyle.imageHeight != null -> contentStyle.imageHeight * density
        (imageDrawable?.intrinsicHeight ?: 0) > 0 -> imageDrawable!!.intrinsicHeight.toFloat()
        else -> 24f * density
      }

    val left = area.left

    val top = (area.top + area.bottom - h) / 2f

    return Companion.Box(
      left,
      top,
      left + w,
      top + h,
    )
  }

  private fun drawImage(
    canvas: Canvas,
    rect: Companion.Box,
  ) {
    val d = imageDrawable ?: return drawPlaceholder(canvas, rect)

    val tl = contentStyle.imageBorderRadiusTopLeft
    val tr = contentStyle.imageBorderRadiusTopRight
    val br = contentStyle.imageBorderRadiusBottomRight
    val bl = contentStyle.imageBorderRadiusBottomLeft

    val radii = floatArrayOf(tl, tl, tr, tr, br, br, bl, bl)

    val path = Path()
    path.addRoundRect(rect.left, rect.top, rect.right, rect.bottom, radii, Path.Direction.CW)

    canvas.withClip(path) {
      d.bounds = Rect(rect.left.toInt(), rect.top.toInt(), rect.right.toInt(), rect.bottom.toInt())
      d.draw(canvas)
    }
  }

  private fun drawPlaceholder(
    canvas: Canvas,
    rect: Companion.Box,
  ) {
    val paint =
      Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = 0xFFCCCCCC.toInt()
        style = Paint.Style.FILL
      }

    drawRoundedRect(
      canvas,
      rect,
      contentStyle.imageBorderRadiusTopLeft,
      contentStyle.imageBorderRadiusTopRight,
      contentStyle.imageBorderRadiusBottomRight,
      contentStyle.imageBorderRadiusBottomLeft,
      paint,
    )
  }

  private fun drawRoundedRect(
    canvas: Canvas,
    rect: Companion.Box,
    tl: Float,
    tr: Float,
    br: Float,
    bl: Float,
    paint: Paint,
  ) {
    val radii =
      floatArrayOf(
        tl,
        tl,
        tr,
        tr,
        br,
        br,
        bl,
        bl,
      )

    val path = Path()
    path.addRoundRect(
      rect.left,
      rect.top,
      rect.right,
      rect.bottom,
      radii,
      Path.Direction.CW,
    )
    canvas.drawPath(path, paint)
  }

  private fun loadImageAsync() {
    EnrichedImageLoader.instance.load(src) { bitmap ->
      if (bitmap == null) {
        loadFallbackImage()
      } else {
        onImageLoaded(bitmap.toDrawable(Resources.getSystem()))
      }
    }
  }

  private fun loadFallbackImage() {
    val fallbackUri = contentStyle.fallbackImageURI
    if (fallbackUri == null) {
      loadBaseFallbackImage()
    } else {
      EnrichedImageLoader.instance.load(fallbackUri) { bitmap ->
        if (bitmap == null) {
          loadBaseFallbackImage()
        } else {
          onImageLoaded(bitmap.toDrawable(Resources.getSystem()))
        }
      }
    }
  }

  private fun loadBaseFallbackImage() {
    onImageLoaded(ResourceManager.getDrawableResource(R.drawable.broken_image))
  }
}
