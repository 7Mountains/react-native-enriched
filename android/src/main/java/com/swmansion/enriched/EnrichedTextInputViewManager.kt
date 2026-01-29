package com.swmansion.enriched

import android.content.Context
import android.util.Log
import androidx.core.graphics.toColorInt
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.PixelUtil
import com.facebook.react.uimanager.ReactStylesDiffMap
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.StateWrapper
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewDefaults
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.ViewProps
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.EnrichedTextInputViewManagerDelegate
import com.facebook.react.viewmanagers.EnrichedTextInputViewManagerInterface
import com.facebook.yoga.YogaMeasureMode
import com.facebook.yoga.YogaMeasureOutput
import com.swmansion.enriched.events.OnAlignmentChangeEvent
import com.swmansion.enriched.events.OnChangeHtmlEvent
import com.swmansion.enriched.events.OnChangeSelectionEvent
import com.swmansion.enriched.events.OnChangeStateEvent
import com.swmansion.enriched.events.OnChangeTextEvent
import com.swmansion.enriched.events.OnColorChangeEvent
import com.swmansion.enriched.events.OnInputBlurEvent
import com.swmansion.enriched.events.OnInputFocusEvent
import com.swmansion.enriched.events.OnLinkDetectedEvent
import com.swmansion.enriched.events.OnMentionDetectedEvent
import com.swmansion.enriched.events.OnMentionEvent
import com.swmansion.enriched.events.OnRequestHtmlResultEvent
import com.swmansion.enriched.spans.TextStyle
import com.swmansion.enriched.styles.HtmlStyle
import com.swmansion.enriched.utils.jsonStringToStringMap

@ReactModule(name = EnrichedTextInputViewManager.NAME)
class EnrichedTextInputViewManager :
  SimpleViewManager<EnrichedTextInputView>(),
  EnrichedTextInputViewManagerInterface<EnrichedTextInputView> {
  private val mDelegate: ViewManagerDelegate<EnrichedTextInputView> =
    EnrichedTextInputViewManagerDelegate(this)
  private var view: EnrichedTextInputView? = null

  override fun getDelegate(): ViewManagerDelegate<EnrichedTextInputView>? = mDelegate

  override fun getName(): String = NAME

  public override fun createViewInstance(context: ThemedReactContext): EnrichedTextInputView {
    val viewInstance = EnrichedTextInputView(context)
    view = viewInstance
    return viewInstance
  }

  override fun onDropViewInstance(view: EnrichedTextInputView) {
    super.onDropViewInstance(view)
  }

  override fun updateState(
    view: EnrichedTextInputView,
    props: ReactStylesDiffMap?,
    stateWrapper: StateWrapper?,
  ): Any? {
    view.stateWrapper = stateWrapper
    return super.updateState(view, props, stateWrapper)
  }

  override fun getExportedCustomDirectEventTypeConstants(): MutableMap<String, Any> {
    val map = mutableMapOf<String, Any>()
    map.put(OnInputFocusEvent.EVENT_NAME, mapOf("registrationName" to OnInputFocusEvent.EVENT_NAME))
    map.put(OnInputBlurEvent.EVENT_NAME, mapOf("registrationName" to OnInputBlurEvent.EVENT_NAME))
    map.put(OnChangeTextEvent.EVENT_NAME, mapOf("registrationName" to OnChangeTextEvent.EVENT_NAME))
    map.put(OnChangeHtmlEvent.EVENT_NAME, mapOf("registrationName" to OnChangeHtmlEvent.EVENT_NAME))
    map.put(OnChangeStateEvent.EVENT_NAME, mapOf("registrationName" to OnChangeStateEvent.EVENT_NAME))
    map.put(OnLinkDetectedEvent.EVENT_NAME, mapOf("registrationName" to OnLinkDetectedEvent.EVENT_NAME))
    map.put(OnMentionDetectedEvent.EVENT_NAME, mapOf("registrationName" to OnMentionDetectedEvent.EVENT_NAME))
    map.put(OnMentionEvent.EVENT_NAME, mapOf("registrationName" to OnMentionEvent.EVENT_NAME))
    map.put(OnChangeSelectionEvent.EVENT_NAME, mapOf("registrationName" to OnChangeSelectionEvent.EVENT_NAME))
    map.put(OnRequestHtmlResultEvent.EVENT_NAME, mapOf("registrationName" to OnRequestHtmlResultEvent.EVENT_NAME))
    map.put(OnColorChangeEvent.EVENT_NAME, mapOf("registrationName" to OnColorChangeEvent.EVENT_NAME))
    map.put(OnAlignmentChangeEvent.EVENT_NAME, mapOf("registrationName" to OnAlignmentChangeEvent.EVENT_NAME))

    return map
  }

  @ReactProp(name = "defaultValue")
  override fun setDefaultValue(
    view: EnrichedTextInputView?,
    value: String?,
  ) {
    view?.setDefaultValue(value)
  }

  @ReactProp(name = "placeholder")
  override fun setPlaceholder(
    view: EnrichedTextInputView?,
    value: String?,
  ) {
    view?.setPlaceholder(value)
  }

  @ReactProp(name = "placeholderTextColor", customType = "Color")
  override fun setPlaceholderTextColor(
    view: EnrichedTextInputView?,
    color: Int?,
  ) {
    view?.setPlaceholderTextColor(color)
  }

  @ReactProp(name = "cursorColor", customType = "Color")
  override fun setCursorColor(
    view: EnrichedTextInputView?,
    color: Int?,
  ) {
    view?.setCursorColor(color)
  }

  @ReactProp(name = "selectionColor", customType = "Color")
  override fun setSelectionColor(
    view: EnrichedTextInputView?,
    color: Int?,
  ) {
    view?.setSelectionColor(color)
  }

  @ReactProp(name = "autoFocus", defaultBoolean = false)
  override fun setAutoFocus(
    view: EnrichedTextInputView?,
    autoFocus: Boolean,
  ) {
    view?.setAutoFocus(autoFocus)
  }

  @ReactProp(name = "editable", defaultBoolean = true)
  override fun setEditable(
    view: EnrichedTextInputView?,
    editable: Boolean,
  ) {
    view?.isEnabled = editable
  }

  @ReactProp(name = "mentionIndicators")
  override fun setMentionIndicators(
    view: EnrichedTextInputView?,
    indicators: ReadableArray?,
  ) {
    if (indicators == null) return

    val indicatorsList = mutableListOf<String>()
    for (i in 0 until indicators.size()) {
      val stringValue = indicators.getString(i) ?: continue
      indicatorsList.add(stringValue)
    }

    val indicatorsArray = indicatorsList.toTypedArray()
    view?.parametrizedStyles?.mentionIndicators = indicatorsArray
  }

  @ReactProp(name = "htmlStyle")
  override fun setHtmlStyle(
    view: EnrichedTextInputView?,
    style: ReadableMap?,
  ) {
    view?.htmlStyle = HtmlStyle(view, style)
  }

  @ReactProp(name = ViewProps.COLOR, customType = "Color")
  override fun setColor(
    view: EnrichedTextInputView?,
    color: Int?,
  ) {
    view?.setColor(color)
  }

  @ReactProp(name = "fontSize", defaultFloat = ViewDefaults.FONT_SIZE_SP)
  override fun setFontSize(
    view: EnrichedTextInputView?,
    size: Float,
  ) {
    view?.setFontSize(size)
  }

  @ReactProp(name = "fontFamily")
  override fun setFontFamily(
    view: EnrichedTextInputView?,
    family: String?,
  ) {
    view?.setFontFamily(family)
  }

  @ReactProp(name = "fontWeight")
  override fun setFontWeight(
    view: EnrichedTextInputView?,
    weight: String?,
  ) {
    view?.setFontWeight(weight)
  }

  @ReactProp(name = "fontStyle")
  override fun setFontStyle(
    view: EnrichedTextInputView?,
    style: String?,
  ) {
    view?.setFontStyle(style)
  }

  @ReactProp(name = "scrollEnabled")
  override fun setScrollEnabled(
    view: EnrichedTextInputView,
    scrollEnabled: Boolean,
  ) {
    view.scrollEnabled = scrollEnabled
  }

  override fun onAfterUpdateTransaction(view: EnrichedTextInputView) {
    super.onAfterUpdateTransaction(view)
    view.afterUpdateTransaction()
  }

  override fun setPadding(
    view: EnrichedTextInputView?,
    left: Int,
    top: Int,
    right: Int,
    bottom: Int,
  ) {
    super.setPadding(view, left, top, right, bottom)

    view?.setPadding(left, top, right, bottom)
  }

  override fun setIsOnChangeHtmlSet(
    view: EnrichedTextInputView?,
    value: Boolean,
  ) {
    view?.shouldEmitHtml = value
  }

  override fun setIsOnChangeTextSet(
    view: EnrichedTextInputView?,
    value: Boolean,
  ) {
    view?.shouldEmitOnChangeText = value
  }

  override fun setAutoCapitalize(
    view: EnrichedTextInputView?,
    flag: String?,
  ) {
    view?.setAutoCapitalize(flag)
  }

  override fun setAndroidExperimentalSynchronousEvents(
    view: EnrichedTextInputView?,
    value: Boolean,
  ) {
    view?.experimentalSynchronousEvents = value
  }

  override fun focus(view: EnrichedTextInputView?) {
    view?.requestFocusProgrammatically()
  }

  override fun blur(view: EnrichedTextInputView?) {
    view?.clearFocus()
  }

  override fun setValue(
    view: EnrichedTextInputView?,
    text: String,
  ) {
    view?.setValue(text, true)
  }

  override fun setSelection(
    view: EnrichedTextInputView?,
    start: Int,
    end: Int,
  ) {
    view?.setCustomSelection(start, end)
  }

  override fun toggleBold(view: EnrichedTextInputView?) {
    view?.verifyAndToggleStyle(TextStyle.BOLD)
  }

  override fun toggleItalic(view: EnrichedTextInputView?) {
    view?.verifyAndToggleStyle(TextStyle.ITALIC)
  }

  override fun toggleUnderline(view: EnrichedTextInputView?) {
    view?.verifyAndToggleStyle(TextStyle.UNDERLINE)
  }

  override fun toggleStrikeThrough(view: EnrichedTextInputView?) {
    view?.verifyAndToggleStyle(TextStyle.STRIKETHROUGH)
  }

  override fun toggleInlineCode(view: EnrichedTextInputView?) {
    view?.verifyAndToggleStyle(TextStyle.INLINE_CODE)
  }

  override fun toggleH1(view: EnrichedTextInputView?) {
    view?.verifyAndToggleStyle(TextStyle.H1)
  }

  override fun toggleH2(view: EnrichedTextInputView?) {
    view?.verifyAndToggleStyle(TextStyle.H2)
  }

  override fun toggleH3(view: EnrichedTextInputView?) {
    view?.verifyAndToggleStyle(TextStyle.H3)
  }

  override fun toggleH4(view: EnrichedTextInputView?) {
    view?.verifyAndToggleStyle(TextStyle.H4)
  }

  override fun toggleH5(view: EnrichedTextInputView?) {
    view?.verifyAndToggleStyle(TextStyle.H5)
  }

  override fun toggleH6(view: EnrichedTextInputView?) {
    view?.verifyAndToggleStyle(TextStyle.H6)
  }

  override fun toggleCodeBlock(view: EnrichedTextInputView?) {
    view?.verifyAndToggleStyle(TextStyle.CODE_BLOCK)
  }

  override fun toggleBlockQuote(view: EnrichedTextInputView?) {
    view?.verifyAndToggleStyle(TextStyle.BLOCK_QUOTE)
  }

  override fun toggleOrderedList(view: EnrichedTextInputView?) {
    view?.verifyAndToggleStyle(TextStyle.ORDERED_LIST)
  }

  override fun toggleUnorderedList(view: EnrichedTextInputView?) {
    view?.verifyAndToggleStyle(TextStyle.UNORDERED_LIST)
  }

  override fun setColor(
    view: EnrichedTextInputView?,
    color: String,
  ) {
    view?.setColor(color.toColorInt())
  }

  override fun removeColor(view: EnrichedTextInputView?) {
    view?.removeColor()
  }

  override fun addDividerAtNewLine(view: EnrichedTextInputView?) {
    view?.insertDivider()
  }

  override fun addLink(
    view: EnrichedTextInputView?,
    start: Int,
    end: Int,
    text: String,
    url: String,
  ) {
    view?.addLink(start, end, text, url)
  }

  override fun addImage(
    view: EnrichedTextInputView?,
    src: String,
    width: Float,
    height: Float,
  ) {
    view?.addImage(src, width, height)
  }

  override fun startMention(
    view: EnrichedTextInputView?,
    indicator: String,
  ) {
    view?.startMention(indicator)
  }

  override fun addMention(
    view: EnrichedTextInputView?,
    indicator: String,
    text: String,
    payload: String,
  ) {
    val attributes = jsonStringToStringMap(payload)
    view?.addMention(text, indicator, attributes)
  }

  override fun requestHTML(
    view: EnrichedTextInputView?,
    requestId: Int,
    prettify: Boolean,
  ) {
    view?.requestHTML(requestId, prettify)
  }

  override fun toggleCheckList(view: EnrichedTextInputView?) {
    view?.verifyAndToggleStyle(TextStyle.CHECK_LIST)
  }

  override fun setParagraphAlignment(
    view: EnrichedTextInputView?,
    alignment: String,
  ) {
    view?.setParagraphAlignmentSpan(alignment)
  }

  override fun setKeyboardDismissMode(
    view: EnrichedTextInputView?,
    value: String?,
  ) {
    // iOS only prop
  }

  override fun scrollTo(
    view: EnrichedTextInputView?,
    x: Float,
    y: Float,
    animated: Boolean,
  ) {
    if (view == null) return
    if (!x.isFinite() || !y.isFinite()) return

    view.post {
      val layout = view.layout ?: return@post

      val visibleWidth = view.width - view.paddingLeft - view.paddingRight
      val visibleHeight = view.height - view.paddingTop - view.paddingBottom

      if (visibleWidth <= 0 || visibleHeight <= 0) return@post

      val contentWidth = layout.width
      val contentHeight = layout.height

      val maxX = (contentWidth - visibleWidth).coerceAtLeast(0)
      val maxY = (contentHeight - visibleHeight).coerceAtLeast(0)

      val clampedX = x.toInt().coerceIn(0, maxX)
      val clampedY = y.toInt().coerceIn(0, maxY)
      view.scrollTo(clampedX, clampedY)
    }
  }

  override fun measure(
    context: Context,
    localData: ReadableMap?,
    props: ReadableMap?,
    state: ReadableMap?,
    width: Float,
    widthMode: YogaMeasureMode?,
    height: Float,
    heightMode: YogaMeasureMode?,
    attachmentsPositions: FloatArray?,
  ): Long {
    val layout = view?.layout

    val measuredWidthDip =
      when {
        widthMode == YogaMeasureMode.EXACTLY -> {
          width
        }

        layout != null -> {
          val contentWidthPx = layout.width
          val contentWidthDip = PixelUtil.toDIPFromPixel(contentWidthPx.toFloat())

          when (widthMode) {
            YogaMeasureMode.AT_MOST -> contentWidthDip.coerceAtMost(width)
            YogaMeasureMode.UNDEFINED, null -> contentWidthDip
            else -> contentWidthDip
          }
        }

        else -> {
          0f
        }
      }

    val measuredHeightDip =
      when {
        heightMode == YogaMeasureMode.EXACTLY -> {
          height
        }

        layout != null -> {
          val contentHeightPx = layout.height
          val contentHeightDip = PixelUtil.toDIPFromPixel(contentHeightPx.toFloat())

          when (heightMode) {
            YogaMeasureMode.AT_MOST -> contentHeightDip.coerceAtMost(height)
            YogaMeasureMode.UNDEFINED, null -> contentHeightDip
            else -> contentHeightDip
          }
        }

        else -> {
          0f
        }
      }

    return YogaMeasureOutput.make(measuredWidthDip, measuredHeightDip)
  }

  companion object {
    const val NAME = "EnrichedTextInputView"
  }
}
