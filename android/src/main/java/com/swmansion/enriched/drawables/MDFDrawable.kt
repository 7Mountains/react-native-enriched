package com.swmansion.enriched.drawables

import android.content.res.Resources
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorFilter
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PixelFormat
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.drawable.Drawable
import androidx.core.graphics.drawable.toDrawable
import androidx.core.graphics.withClip
import com.swmansion.enriched.loaders.EnrichedImageLoader
import com.swmansion.enriched.spans.EnrichedMDFSpan
import com.swmansion.enriched.styles.MDFStyle

class MDFDrawable(
  private val params: EnrichedMDFSpan.Companion.MDFParams,
  private val styles: MDFStyle,
) : Drawable() {
  var onImageLoaded: (() -> Unit)? = null

  private val density = Resources.getSystem().displayMetrics.density
  private val imageSpacing = 8f * density

  private val textPaint =
    Paint(Paint.ANTI_ALIAS_FLAG).apply {
      color = styles.textColor ?: Color.BLACK
      textSize = styles.fontSize * density
    }

  private val backgroundPaint =
    Paint(Paint.ANTI_ALIAS_FLAG).apply {
      color = styles.backgroundColor ?: Color.TRANSPARENT
      style = Paint.Style.FILL
    }

  private val borderPaint =
    Paint(Paint.ANTI_ALIAS_FLAG).apply {
      color = styles.borderColor ?: Color.TRANSPARENT
      strokeWidth = styles.borderWidth
      style = Paint.Style.STROKE
    }

  private val stripePaint =
    Paint(Paint.ANTI_ALIAS_FLAG).apply {
      color = params.tintColor
      style = Paint.Style.FILL
    }

  private var imageDrawable: Drawable? = null

  init {
    loadImage()
  }

  override fun draw(canvas: Canvas) {
    val rect = bounds

    val contentLeft = rect.left + styles.marginLeft
    val contentTop = rect.top + styles.marginTop
    val contentRight = rect.right - styles.marginRight
    val contentBottom = rect.bottom - styles.marginBottom

    val contentRect = RectF(contentLeft, contentTop, contentRight, contentBottom)

    drawBackground(canvas, contentRect)
    drawBorder(canvas, contentRect)
    drawStripe(canvas, contentRect)

    val inner = applyPadding(contentRect)

    val imageContainer = computeImageContainer(inner)

    drawImageContainer(canvas, imageContainer)
    drawImage(canvas, imageContainer)

    drawText(canvas, inner, imageContainer)
  }

  private fun drawBackground(
    canvas: Canvas,
    rect: RectF,
  ) {
    val path = Path()
    path.addRoundRect(rect, styles.borderRadius, styles.borderRadius, Path.Direction.CW)
    canvas.drawPath(path, backgroundPaint)
  }

  private fun drawBorder(
    canvas: Canvas,
    rect: RectF,
  ) {
    if (styles.borderWidth <= 0f) return

    val borderRect =
      RectF(
        rect.left + styles.borderWidth / 2,
        rect.top + styles.borderWidth / 2,
        rect.right - styles.borderWidth / 2,
        rect.bottom - styles.borderWidth / 2,
      )

    val path = Path()
    path.addRoundRect(borderRect, styles.borderRadius, styles.borderRadius, Path.Direction.CW)

    canvas.drawPath(path, borderPaint)
  }

  private fun drawStripe(
    canvas: Canvas,
    rect: RectF,
  ) {
    if (styles.stripeWidth <= 0f) return

    val path = Path()
    path.addRoundRect(rect, styles.borderRadius, styles.borderRadius, Path.Direction.CW)

    canvas.withClip(path) {
      val stripe =
        RectF(
          rect.left,
          rect.top,
          rect.left + styles.stripeWidth,
          rect.bottom,
        )

      canvas.drawRect(stripe, stripePaint)
    }
  }

  private fun applyPadding(rect: RectF): RectF =
    RectF(
      rect.left + styles.paddingLeft,
      rect.top + styles.paddingTop,
      rect.right - styles.paddingRight,
      rect.bottom - styles.paddingBottom,
    )

  private fun computeImageContainer(inner: RectF): RectF {
    val startX = inner.left + styles.stripeWidth

    val w = styles.imageContainerWidth
    val h = styles.imageContainerHeight

    val top = inner.centerY() - h / 2

    return RectF(
      startX,
      top,
      startX + w,
      top + h,
    )
  }

  private fun drawImageContainer(
    canvas: Canvas,
    rect: RectF,
  ) {
    val paint =
      Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = params.tintColor
        style = Paint.Style.FILL
      }

    val path = Path()
    path.addRoundRect(rect, styles.imageBorderRadius, styles.imageBorderRadius, Path.Direction.CW)

    canvas.drawPath(path, paint)
  }

  private fun drawImage(
    canvas: Canvas,
    rect: RectF,
  ) {
    val d = imageDrawable ?: return

    val w = styles.imageWidth
    val h = styles.imageHeight

    val left = rect.left + (rect.width() - w) / 2
    val top = rect.top + (rect.height() - h) / 2

    val imageRect =
      Rect(
        left.toInt(),
        top.toInt(),
        (left + w).toInt(),
        (top + h).toInt(),
      )

    d.bounds = imageRect
    d.draw(canvas)
  }

  private fun drawText(
    canvas: Canvas,
    inner: RectF,
    imageRect: RectF,
  ) {
    val textX = imageRect.right + imageSpacing

    val fm = textPaint.fontMetrics
    val baseline = inner.centerY() - (fm.ascent + fm.descent) / 2

    canvas.drawText(params.label, textX, baseline, textPaint)
  }

  private fun loadImage() {
    val uri = styles.imageUri ?: return

    EnrichedImageLoader.instance.load(uri) { bitmap ->
      imageDrawable = bitmap?.toDrawable(Resources.getSystem())
      onImageLoaded?.invoke()
      invalidateSelf()
    }
  }

  override fun setAlpha(alpha: Int) {
    textPaint.alpha = alpha
  }

  override fun setColorFilter(colorFilter: ColorFilter?) {
    textPaint.colorFilter = colorFilter
  }

  override fun getOpacity(): Int = PixelFormat.TRANSLUCENT

  fun measureHeight(): Int {
    val textHeight = textPaint.fontMetrics.run { descent - ascent }

    val imageHeight =
      if (styles.imageHeight > 0f) {
        styles.imageHeight
      } else {
        styles.imageContainerHeight
      }

    val contentHeight = maxOf(textHeight, imageHeight)

    val paddedHeight =
      contentHeight +
        styles.paddingTop +
        styles.paddingBottom

    val totalHeight =
      paddedHeight +
        styles.marginTop +
        styles.marginBottom

    return if (styles.height > 0f) {
      (styles.height + styles.marginTop + styles.marginBottom).toInt()
    } else {
      totalHeight.toInt()
    }
  }
}
