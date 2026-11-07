package com.swmansion.enriched.text

import android.content.Context
import android.text.Layout
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.PixelUtil
import com.facebook.yoga.YogaMeasureMode
import com.facebook.yoga.YogaMeasureOutput
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min

/** Measures `EnrichedTextView` from its props, with the text and the layout the view draws */
internal object EnrichedTextMeasurement {
  fun measure(
    context: Context,
    props: ReadableMap?,
    width: Float,
    widthMode: YogaMeasureMode?,
    height: Float,
    heightMode: YogaMeasureMode?,
  ): Long {
    val params = EnrichedTextParams.fromProps(props)
    val typeface = params.typeface(context.assets)
    val paint = EnrichedTextLayout.createPaint(params, typeface)
    val hasWidth = widthMode != YogaMeasureMode.UNDEFINED && !width.isNaN() && !width.isInfinite()
    val editorWidth = if (hasWidth) width.toInt() else 0
    val offered = EnrichedTextHandoff.takeOffered()
    val content = offered ?: EnrichedTextContent.forView(buildContent(context, params, editorWidth))
    val builtWidth = if (EnrichedTextContent.dependsOnWidth(content)) PixelUtil.toDIPFromPixel(editorWidth.toFloat()) else Float.NaN
    EnrichedTextHandoff.putBuilt(content, builtWidth, EnrichedTextContent.isReusable(content))

    val layoutWidth =
      if (hasWidth) {
        width
      } else {
        ceil(Layout.getDesiredWidth(content, paint))
      }

    val layout = EnrichedTextLayout.build(content, paint, layoutWidth.toInt(), params)

    // StaticLayout reports all the lines for maxLines >= 2 without the END
    // ellipsis, even when they're cut
    val lineCount =
      if (params.numberOfLines > 0) {
        min(layout.lineCount, params.numberOfLines)
      } else {
        layout.lineCount
      }

    val measuredHeight = if (lineCount > 0) layout.getLineBottom(lineCount - 1).toFloat() else 0f

    val measuredWidth =
      if (widthMode == YogaMeasureMode.EXACTLY) {
        width
      } else {
        var widest = 0f
        for (line in 0 until lineCount) {
          val endsWithNewLine =
            content.isNotEmpty() && content[layout.getLineEnd(line) - 1] == '\n'
          val lineWidth =
            if (endsWithNewLine) layout.getLineMax(line) else layout.getLineWidth(line)
          widest = max(widest, lineWidth)
        }
        min(ceil(widest) + 1f, layoutWidth)
      }

    val finalHeight =
      when (heightMode) {
        YogaMeasureMode.EXACTLY -> height
        YogaMeasureMode.AT_MOST -> min(measuredHeight, height)
        else -> measuredHeight
      }

    return YogaMeasureOutput.make(
      PixelUtil.toDIPFromPixel(measuredWidth),
      PixelUtil.toDIPFromPixel(finalHeight),
    )
  }

  private fun buildContent(
    context: Context,
    params: EnrichedTextParams,
    width: Int,
  ): CharSequence = EnrichedTextContent.build(params, DetachedHtmlHost(context, width, params.fontSizePx))
}
