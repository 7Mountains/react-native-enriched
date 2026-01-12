package com.swmansion.enriched.drawables

import android.graphics.Canvas
import android.graphics.Paint
import com.swmansion.enriched.styles.ContentStyle

class LabelContentDrawable(
  private val contentStyle: ContentStyle,
  private val text: String,
) : BaseContentDrawable(contentStyle, text) {
  override fun draw(canvas: Canvas) {
    measureText()

    val left = bounds.left.toFloat()
    val top = bounds.top.toFloat()
    val right = bounds.right.toFloat()
    val bottom = bounds.bottom.toFloat()

    val ml = contentStyle.marginLeft
    val mt = contentStyle.marginTop
    val mr = contentStyle.marginRight
    val mb = contentStyle.marginBottom

    val contentLeft = left + ml
    val contentTop = top + mt
    val contentRight = right - mr
    val contentBottom = bottom - mb

    drawBackground(canvas, contentLeft, contentTop, contentRight, contentBottom)
    drawBorder(canvas, contentLeft, contentTop, contentRight, contentBottom)

    val padded = applyPadding(contentLeft, contentTop, contentRight, contentBottom)

    val paddedCenterX = (padded.left + padded.right) / 2f
    val paddedCenterY = (padded.top + padded.bottom) / 2f

    val fm = textPaint.fontMetrics
    val baseline = paddedCenterY - (fm.ascent + fm.descent) / 2f

    textPaint.textAlign = Paint.Align.CENTER
    canvas.drawText(text, paddedCenterX, baseline, textPaint)
  }
}
