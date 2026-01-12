package com.swmansion.enriched.drawables

import android.content.res.Resources
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorFilter
import android.graphics.DashPathEffect
import android.graphics.Paint
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.Drawable
import com.swmansion.enriched.styles.ContentStyle
import com.swmansion.enriched.styles.HtmlStyle

abstract class BaseContentDrawable(
  private val contentStyle: ContentStyle,
  private val text: String,
) : Drawable() {
  var onContentLoadEnd: (() -> Unit)? = null

  protected var textWidth = 0f
  protected var textHeight = 0f
  private var measured = false
  protected val density = Resources.getSystem().displayMetrics.density

  private val borderPaint =
    Paint(Paint.ANTI_ALIAS_FLAG).apply {
      color = contentStyle.borderColor ?: Color.TRANSPARENT
      style = Paint.Style.STROKE
      strokeWidth = contentStyle.borderWidth

      pathEffect =
        when (contentStyle.borderStyle) {
          "dashed" -> DashPathEffect(floatArrayOf(6f * density, 3f * density), 0f)
          "dotted" -> DashPathEffect(floatArrayOf(2f * density, 2f * density), 0f)
          else -> null
        }
    }

  protected val textPaint =
    Paint(Paint.ANTI_ALIAS_FLAG).apply {
      color = contentStyle.textColor ?: Color.BLACK
      textSize = contentStyle.fontSize * density
      typeface = Typeface.create(Typeface.DEFAULT, contentStyle.typefaceStyle)
    }

  protected fun measureText() {
    if (measured) return

    textWidth = textPaint.measureText(text)

    val fm = textPaint.fontMetrics
    textHeight = fm.descent - fm.ascent

    measured = true
  }

  fun measureHeight(): Int {
    measureText()

    val fullMargin = contentStyle.marginTop + contentStyle.marginBottom

    val baseHeight =
      if (contentStyle.imageHeight != null && contentStyle.imageHeight > 0) {
        contentStyle.imageHeight * density + fullMargin
      } else {
        contentStyle.paddingTop + contentStyle.paddingBottom +
          contentStyle.borderWidth * 2 + fullMargin
      }

    return baseHeight.toInt()
  }

  private val bgPaint =
    Paint(Paint.ANTI_ALIAS_FLAG).apply {
      color = contentStyle.backgroundColor ?: Color.TRANSPARENT
    }

  protected fun drawBackground(
    canvas: Canvas,
    left: Float,
    top: Float,
    right: Float,
    bottom: Float,
  ) {
    canvas.drawRoundRect(
      left,
      top,
      right,
      bottom,
      contentStyle.borderRadius,
      contentStyle.borderRadius,
      bgPaint,
    )
  }

  protected fun drawBorder(
    canvas: Canvas,
    left: Float,
    top: Float,
    right: Float,
    bottom: Float,
  ) {
    if (contentStyle.borderWidth > 0f) {
      val half = contentStyle.borderWidth / 2f

      canvas.drawRoundRect(
        left + half,
        top + half,
        right - half,
        bottom - half,
        contentStyle.borderRadius,
        contentStyle.borderRadius,
        borderPaint,
      )
    }
  }

  protected fun applyPadding(
    left: Float,
    top: Float,
    right: Float,
    bottom: Float,
  ): Box =
    Box(
      left + contentStyle.paddingLeft,
      top + contentStyle.paddingTop,
      right - contentStyle.paddingRight,
      bottom - contentStyle.paddingBottom,
    )

  override fun setAlpha(alpha: Int) {}

  override fun setColorFilter(colorFilter: ColorFilter?) {}

  override fun getOpacity() = PixelFormat.TRANSLUCENT

  companion object {
    data class Box(
      val left: Float,
      val top: Float,
      val right: Float,
      val bottom: Float,
    )
  }
}
