package com.swmansion.enriched.drawables

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.DashPathEffect
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Typeface
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import androidx.core.graphics.withClip
import androidx.core.graphics.withTranslation
import com.swmansion.enriched.styles.ContentStyle
import kotlin.math.max

class ImageLabelRenderer(
  private val contentStyle: ContentStyle,
  private val title: CharSequence,
  private val description: CharSequence?,
  private val subTitle: CharSequence? = null,
  private val subDescription: CharSequence? = null,
  private val bitmap: Bitmap?,
  private val imageBackgroundColor: Int? = null,
  private val borderLeftColor: Int? = null,
) {
  private val titlePaint =
    TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
      color = contentStyle.title.color
      textSize = contentStyle.title.fontSize
      typeface = Typeface.create(contentStyle.title.fontFamily, contentStyle.title.typefaceStyle)
    }

  private val descPaint =
    TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
      color = contentStyle.description.color
      textSize = contentStyle.description.fontSize
      typeface = Typeface.create(contentStyle.description.fontFamily, contentStyle.description.typefaceStyle)
    }

  private val subtitlePaint =
    TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
      color = contentStyle.subtitle.color
      textSize = contentStyle.subtitle.fontSize
      typeface = Typeface.create(contentStyle.subtitle.fontFamily, contentStyle.subtitle.typefaceStyle)
    }

  private val subdescPaint =
    TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
      color = contentStyle.subDescription.color
      textSize = contentStyle.subDescription.fontSize
      typeface = Typeface.create(contentStyle.subDescription.fontFamily, contentStyle.subDescription.typefaceStyle)
    }

  private var titleLayout: StaticLayout? = null
  private var descLayout: StaticLayout? = null
  private var subtitleLayout: StaticLayout? = null
  private var subDescriptionLayout: StaticLayout? = null

  constructor(
    contentStyle: ContentStyle,
    title: CharSequence,
    description: CharSequence?,
    bitmap: Bitmap?,
    imageBackgroundColor: Int? = null,
    borderLeftColor: Int? = null,
  ) : this(
    contentStyle = contentStyle,
    title = title,
    description = description,
    subTitle = null,
    subDescription = null,
    bitmap = bitmap,
    imageBackgroundColor = imageBackgroundColor,
    borderLeftColor = borderLeftColor,
  )

  fun measure(width: Int): Int {
    val contentWidth = width.toFloat()

    val imageBlockWidth = contentStyle.imageContainer.width

    val textX =
      contentStyle.container.padding.left +
        imageBlockWidth +
        contentStyle.textContainer.margin.left

    var textWidth =
      contentWidth -
        textX -
        contentStyle.container.padding.right -
        contentStyle.textContainer.margin.right

    textWidth -= contentStyle.textContainer.padding.left + contentStyle.textContainer.padding.right
    textWidth = max(textWidth, 0f)

    val safeWidth = max(textWidth.toInt(), 1)

    val titleLayout = createTitleLayoutIfNeeded(title, titlePaint, safeWidth)
    val descLayout = createDescriptionLayoutIfNeeded(description, descPaint, safeWidth)
    val subtitleLayout = createSubTitleLayoutIfNeeded(subTitle, subtitlePaint, safeWidth)
    val subDescriptionLayout = createSubTitleLayoutIfNeeded(subDescription, subdescPaint, safeWidth)

    val titleHeight = titleLayout?.height ?: 0
    val descHeight = descLayout?.height ?: 0
    val subtitleHeight = subtitleLayout?.height ?: 0
    val subDescHeight = subDescriptionLayout?.height ?: 0

    var textHeight = titleHeight

    if (descLayout != null) {
      textHeight += descHeight
    }

    if (subtitleLayout != null) {
      textHeight += subtitleHeight
    }

    if (subDescriptionLayout != null) {
      textHeight += subDescHeight
    }

    val totalTextHeight =
      textHeight +
        contentStyle.textContainer.padding.top +
        contentStyle.textContainer.padding.bottom

    val contentHeight = max(totalTextHeight, contentStyle.imageContainer.height)

    return max(
      contentHeight + contentStyle.container.padding.top + contentStyle.container.padding.bottom,
      contentStyle.container.minHeight,
    ).toInt()
  }

  fun draw(
    canvas: Canvas,
    width: Int,
    height: Int,
  ) {
    if (titleLayout == null) {
      measure(width)
    }

    val bounds = RectF(0f, 0f, width.toFloat(), height.toFloat())
    val radius = contentStyle.container.borderRadius

    val contentPath =
      Path().apply {
        addRoundRect(bounds, radius, radius, Path.Direction.CW)
      }

    canvas.withClip(contentPath) {
      drawBackground(canvas, bounds, radius)
      drawLeftBorder(canvas, height)

      val contentLeft = contentStyle.container.borderLeftWidth

      withTranslation(contentLeft, 0f) {
        drawContent(
          canvas = this,
          width = (width - contentLeft).toInt(),
          height = height,
        )
      }
    }

    drawOuterBorder(canvas, bounds, radius)
  }

  private fun drawContent(
    canvas: Canvas,
    width: Int,
    height: Int,
  ) {
    val contentHeight =
      height - contentStyle.container.padding.top - contentStyle.container.padding.bottom

    val imageRect = calculateImageRect(contentHeight)

    val containerPath = createImagePath(imageRect)

    drawImageBackground(canvas, containerPath)
    drawImage(canvas, containerPath, imageRect)

    drawText(canvas, imageRect, contentHeight)
  }

  private fun calculateImageRect(contentHeight: Float): RectF {
    val imageLeft = contentStyle.container.padding.left

    val imageHeight =
      if (contentStyle.imageContainer.height > 0) {
        contentStyle.imageContainer.height
      } else {
        contentHeight
      }

    val imageWidth =
      if (contentStyle.imageContainer.width > 0) {
        contentStyle.imageContainer.width
      } else {
        imageHeight
      }

    val imageTop =
      contentStyle.container.padding.top +
        (contentHeight - imageHeight) / 2f

    return RectF(
      imageLeft,
      imageTop,
      imageLeft + imageWidth,
      imageTop + imageHeight,
    )
  }

  private fun createImagePath(imageRect: RectF): Path {
    val radius = contentStyle.imageContainer.borderRadius

    val radii =
      floatArrayOf(
        radius,
        radius,
        radius,
        radius,
        radius,
        radius,
        radius,
        radius,
      )

    return Path().apply {
      addRoundRect(imageRect, radii, Path.Direction.CW)
    }
  }

  private fun drawBackground(
    canvas: Canvas,
    bounds: RectF,
    radius: Float,
  ) {
    contentStyle.container.backgroundColor?.let {
      val paint =
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
          color = it
          style = Paint.Style.FILL
        }
      canvas.drawRoundRect(bounds, radius, radius, paint)
    }
  }

  private fun drawLeftBorder(
    canvas: Canvas,
    height: Int,
  ) {
    borderLeftColor?.let { color ->
      if (contentStyle.container.borderLeftWidth > 0f) {
        val paint =
          Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = color
            style = Paint.Style.STROKE
            strokeWidth = contentStyle.container.borderLeftWidth
          }

        val x = contentStyle.container.borderLeftWidth / 2

        canvas.drawLine(x, 0f, x, height.toFloat(), paint)
      }
    }
  }

  private fun drawOuterBorder(
    canvas: Canvas,
    bounds: RectF,
    radius: Float,
  ) {
    if (contentStyle.container.borderWidth <= 0 ||
      contentStyle.container.borderStyle == ContentStyle.Companion.BorderStyle.NONE
    ) {
      return
    }

    val paint =
      Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = contentStyle.container.borderWidth
        color = contentStyle.container.borderColor ?: Color.TRANSPARENT

        pathEffect =
          when (contentStyle.container.borderStyle) {
            ContentStyle.Companion.BorderStyle.DASHED -> {
              DashPathEffect(floatArrayOf(16f, 12f), 0f)
            }

            ContentStyle.Companion.BorderStyle.DOTTED -> {
              DashPathEffect(floatArrayOf(2f, 6f), 0f)
            }

            else -> {
              null
            }
          }

        if (contentStyle.container.borderStyle ==
          ContentStyle.Companion.BorderStyle.DOTTED
        ) {
          strokeCap = Paint.Cap.ROUND
        }
      }

    canvas.drawRoundRect(bounds, radius, radius, paint)
  }

  private fun drawImageBackground(
    canvas: Canvas,
    path: Path,
  ) {
    val color = imageBackgroundColor ?: contentStyle.imageContainer.backgroundColor
    color?.let { color ->
      val paint =
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
          this.color = color
          style = Paint.Style.FILL
        }
      canvas.drawPath(path, paint)
    }
  }

  private fun drawImage(
    canvas: Canvas,
    path: Path,
    imageRect: RectF,
  ) {
    bitmap?.let { bmp ->
      if (imageRect.width() <= 0 || imageRect.height() <= 0) return

      val containerW = imageRect.width()
      val containerH = imageRect.height()

      val imageW =
        if (contentStyle.image.width > 0) {
          contentStyle.image.width
        } else {
          containerW
        }

      val imageH =
        if (contentStyle.image.height > 0) {
          contentStyle.image.height
        } else {
          containerH
        }

      val imageDrawRect =
        RectF(
          imageRect.left + (containerW - imageW) / 2f,
          imageRect.top + (containerH - imageH) / 2f,
          imageRect.left + (containerW + imageW) / 2f,
          imageRect.top + (containerH + imageH) / 2f,
        )

      canvas.withClip(path) {
        val paint =
          Paint(Paint.ANTI_ALIAS_FLAG).apply {
            isFilterBitmap = true
          }
        drawBitmap(bmp, null, imageDrawRect, paint)
      }
    }
  }

  private fun drawText(
    canvas: Canvas,
    imageRect: RectF,
    contentHeight: Float,
  ) {
    val textX = imageRect.right + contentStyle.textContainer.margin.left

    val titleHeight = titleLayout?.height ?: 0
    val descHeight = descLayout?.height ?: 0

    val subtitleHeight = subtitleLayout?.height ?: 0
    val subDescHeight = subDescriptionLayout?.height ?: 0

    var textHeight = 0f

    if (titleLayout != null) {
      val margin = contentStyle.title.margin
      textHeight += margin.top + titleHeight + margin.bottom
    }

    if (descLayout != null) {
      val margin = contentStyle.description.margin
      textHeight += margin.top + descHeight + margin.bottom
    }

    if (subtitleLayout != null) {
      val margin = contentStyle.subtitle.margin
      textHeight += margin.top + subtitleHeight + margin.bottom
    }

    if (subDescriptionLayout != null) {
      val margin = contentStyle.subDescription.margin
      textHeight += margin.top + subDescHeight + margin.bottom
    }

    val containerHeight =
      textHeight +
        contentStyle.textContainer.padding.top +
        contentStyle.textContainer.padding.bottom

    val centerY = contentStyle.container.padding.top + contentHeight / 2f
    val containerY = centerY - containerHeight / 2f

    val textStartX = textX + contentStyle.textContainer.padding.left
    var currentY = containerY + contentStyle.textContainer.padding.top

    titleLayout?.let {
      val margin = contentStyle.title.margin

      currentY += margin.top

      canvas.withTranslation(textStartX, currentY) {
        it.draw(this)
      }

      currentY += it.height + margin.bottom
    }

    descLayout?.let {
      val margin = contentStyle.description.margin

      currentY += margin.top

      canvas.withTranslation(textStartX, currentY) {
        it.draw(this)
      }

      currentY += it.height + margin.bottom
    }

    subtitleLayout?.let {
      val margin = contentStyle.subtitle.margin

      currentY += margin.top

      canvas.withTranslation(textStartX, currentY) {
        it.draw(this)
      }

      currentY += it.height + margin.bottom
    }

    subDescriptionLayout?.let {
      val margin = contentStyle.subDescription.margin

      currentY += margin.top

      canvas.withTranslation(textStartX, currentY) {
        it.draw(this)
      }
    }
  }

  private fun createTitleLayoutIfNeeded(
    text: CharSequence?,
    paint: TextPaint,
    width: Int,
  ): StaticLayout? {
    if (text.isNullOrEmpty()) {
      return null
    }

    val titleLayout = titleLayout
    if (titleLayout != null) {
      return titleLayout
    }

    val layout = createTitleLayout(text, paint, width)
    this.titleLayout = layout

    return layout
  }

  private fun createSubTitleLayoutIfNeeded(
    text: CharSequence?,
    paint: TextPaint,
    width: Int,
  ): StaticLayout? {
    if (text.isNullOrEmpty()) {
      return null
    }
    val titleLayout = subtitleLayout
    if (titleLayout != null) {
      return titleLayout
    }

    val layout = createTitleLayout(text, paint, width)
    this.subtitleLayout = layout

    return layout
  }

  private fun createDescriptionLayoutIfNeeded(
    text: CharSequence?,
    paint: TextPaint,
    width: Int,
  ): StaticLayout? {
    if (text.isNullOrEmpty()) {
      return null
    }
    val descriptionLayout = descLayout
    if (descriptionLayout != null) {
      return descriptionLayout
    }

    val layout = createDescriptionLayout(text, paint, width)
    this.descLayout = layout

    return layout
  }

  private fun createSubDescriptionLayoutIfNeeded(
    text: CharSequence?,
    paint: TextPaint,
    width: Int,
  ): StaticLayout? {
    if (text.isNullOrEmpty()) {
      return null
    }
    val descriptionLayout = subDescriptionLayout
    if (descriptionLayout != null) {
      return descriptionLayout
    }

    val layout = createDescriptionLayout(text, paint, width)
    this.subDescriptionLayout = layout

    return layout
  }

  private fun createDescriptionLayout(
    text: CharSequence,
    paint: TextPaint,
    width: Int,
  ): StaticLayout =
    StaticLayout.Builder
      .obtain(text, 0, text.length, paint, width)
      .setAlignment(Layout.Alignment.ALIGN_NORMAL)
      .setIncludePad(false)
      .build()

  private fun createTitleLayout(
    titleText: CharSequence,
    paint: TextPaint,
    width: Int,
  ): StaticLayout {
    val ellipsizedTitle =
      android.text.TextUtils.ellipsize(
        titleText,
        paint,
        width.toFloat(),
        android.text.TextUtils.TruncateAt.END,
      )

    return StaticLayout.Builder
      .obtain(ellipsizedTitle, 0, ellipsizedTitle.length, titlePaint, width)
      .setMaxLines(1)
      .setAlignment(Layout.Alignment.ALIGN_NORMAL)
      .setIncludePad(false)
      .build()
  }
}
