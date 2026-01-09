package com.swmansion.enriched.drawables

import android.graphics.Canvas
import android.graphics.ColorFilter
import android.graphics.Paint
import android.graphics.PixelFormat
import android.graphics.drawable.Drawable

class HRDrawable(
  val thickness: Float,
  val color: Int,
) : Drawable() {
  private val paint = Paint(Paint.ANTI_ALIAS_FLAG)

  override fun draw(canvas: Canvas) {
    paint.style = Paint.Style.STROKE
    paint.strokeWidth = thickness
    paint.color = color

    val y = bounds.height() / 2f
    canvas.drawLine(
      0f,
      y,
      bounds.width().toFloat(),
      y,
      paint,
    )
  }

  override fun setAlpha(alpha: Int) {
    paint.alpha = alpha
  }

  override fun setColorFilter(filter: ColorFilter?) {
    paint.colorFilter = filter
  }

  override fun getOpacity(): Int = PixelFormat.TRANSLUCENT
}
