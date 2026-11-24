package com.swmansion.enriched.text

import android.content.Context
import android.text.Layout
import com.facebook.proguard.annotations.DoNotStrip
import com.facebook.react.common.ReactConstants
import com.facebook.react.uimanager.PixelUtil
import com.facebook.react.views.text.ReactTypefaceUtils
import com.facebook.yoga.YogaMeasureMode
import com.facebook.yoga.YogaMeasureOutput
import com.swmansion.enriched.utils.LineSeparatorTransformationMethod
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min

/**
 * The size of a text measured by [EnrichedTextMeasurement], and the text for
 * the view (through the state of the shadow node), read by the shadow node
 */
@DoNotStrip
internal class EnrichedTextMeasurementResult(
  /** Packed by `YogaMeasureOutput` */
  @JvmField @DoNotStrip val size: Long,
  @JvmField @DoNotStrip val text: Any,
  /** The width (dp) the text is laid out for, NaN when it doesn't depend on it */
  @JvmField @DoNotStrip val builtWidth: Float,
)

/**
 * Measures `EnrichedTextView`, with the text and the layout the view draws.
 * Called by its shadow node (C++) directly with the props, instead of through
 * `FabricUIManager.measure`, which takes the props as a map.
 */
@DoNotStrip
internal object EnrichedTextMeasurement {
  private val lineSeparatorTransformationMethod = LineSeparatorTransformationMethod()

  // Set with the view managers: the texts are measured before any view exists
  @Volatile
  var context: Context? = null

  /**
   * @param text The text of the props, `null` with [offeredText]
   * @param offeredText The text built by a previous measurement of the same
   * props and width, laid out again without parsing the HTML
   */
  @JvmStatic
  @DoNotStrip
  fun measure(
    text: String?,
    htmlStyleId: Int,
    fontSize: Float,
    lineHeight: Float,
    fontFamily: String?,
    fontWeight: String?,
    fontStyle: String?,
    allowFontScaling: Boolean,
    numberOfLines: Int,
    ellipsizeMode: String?,
    minWidth: Float,
    maxWidth: Float,
    minHeight: Float,
    maxHeight: Float,
    offeredText: Any?,
  ): EnrichedTextMeasurementResult {
    val params =
      EnrichedTextParams(
        text = text ?: "",
        htmlStyleId = htmlStyleId,
        fontSize = fontSize,
        lineHeight = lineHeight,
        fontFamily = fontFamily,
        fontWeight = if (fontWeight != null) ReactTypefaceUtils.parseFontWeight(fontWeight) else ReactConstants.UNSET,
        fontStyle = if (fontStyle != null) ReactTypefaceUtils.parseFontStyle(fontStyle) else ReactConstants.UNSET,
        allowFontScaling = allowFontScaling,
        numberOfLines = numberOfLines,
        ellipsizeMode = ellipsizeMode,
      )

    return measure(
      checkNotNull(context) { "EnrichedTextMeasurement is used before its view manager is created" },
      params,
      toYogaSize(minWidth, maxWidth),
      toYogaMeasureMode(minWidth, maxWidth),
      toYogaSize(minHeight, maxHeight),
      toYogaMeasureMode(minHeight, maxHeight),
      offeredText as? CharSequence,
    )
  }

  // As `FabricUIManager.measure`: the constraints (dp) of the shadow node to
  // the size (px) and the mode of Yoga
  private fun toYogaSize(
    minSize: Float,
    maxSize: Float,
  ): Float = if (minSize != maxSize && maxSize.isInfinite()) Float.POSITIVE_INFINITY else PixelUtil.toPixelFromDIP(maxSize)

  private fun toYogaMeasureMode(
    minSize: Float,
    maxSize: Float,
  ): YogaMeasureMode =
    when {
      minSize == maxSize -> YogaMeasureMode.EXACTLY
      maxSize.isInfinite() -> YogaMeasureMode.UNDEFINED
      else -> YogaMeasureMode.AT_MOST
    }

  private fun measure(
    context: Context,
    params: EnrichedTextParams,
    width: Float,
    widthMode: YogaMeasureMode,
    height: Float,
    heightMode: YogaMeasureMode,
    offeredText: CharSequence?,
  ): EnrichedTextMeasurementResult {
    val typeface = params.typeface(context.assets)
    val paint = EnrichedTextLayout.createPaint(params, typeface)
    val hasWidth = widthMode != YogaMeasureMode.UNDEFINED && !width.isNaN() && !width.isInfinite()
    val editorWidth = if (hasWidth) width.toInt() else 0
    val content = offeredText ?: EnrichedTextContent.forView(buildContent(context, params, editorWidth))
    val transformedContent = lineSeparatorTransformationMethod.getTransformation(content, null)
    val builtWidth = if (EnrichedTextContent.dependsOnWidth(content)) PixelUtil.toDIPFromPixel(editorWidth.toFloat()) else Float.NaN

    val layoutWidth =
      if (hasWidth) {
        width
      } else {
        ceil(Layout.getDesiredWidth(transformedContent, paint))
      }

    val layout = EnrichedTextLayout.build(transformedContent, paint, layoutWidth.toInt(), params)

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
            transformedContent.isNotEmpty() && transformedContent[layout.getLineEnd(line) - 1] == '\n'
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

    return EnrichedTextMeasurementResult(
      size =
        YogaMeasureOutput.make(
          PixelUtil.toDIPFromPixel(measuredWidth),
          PixelUtil.toDIPFromPixel(finalHeight),
        ),
      text = content,
      builtWidth = builtWidth,
    )
  }

  private fun buildContent(
    context: Context,
    params: EnrichedTextParams,
    width: Int,
  ): CharSequence = EnrichedTextContent.build(params, DetachedHtmlHost(context, width, params.fontSizePx))
}
