package com.swmansion.enriched

import androidx.core.graphics.toColorInt
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.BackgroundStyleApplicator
import com.facebook.react.uimanager.LengthPercentage
import com.facebook.react.uimanager.LengthPercentageType
import com.facebook.react.uimanager.ReactStylesDiffMap
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.StateWrapper
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewDefaults
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.ViewProps
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.uimanager.style.BorderRadiusProp
import com.facebook.react.uimanager.style.BorderStyle
import com.facebook.react.uimanager.style.LogicalEdge
import com.facebook.react.viewmanagers.EnrichedTextInputViewManagerDelegate
import com.facebook.react.viewmanagers.EnrichedTextInputViewManagerInterface
import com.swmansion.enriched.events.OnAlignmentChangeEvent
import com.swmansion.enriched.events.OnAnyContentChangeEvent
import com.swmansion.enriched.events.OnChangeHtmlEvent
import com.swmansion.enriched.events.OnChangeSelectionEvent
import com.swmansion.enriched.events.OnChangeStateEvent
import com.swmansion.enriched.events.OnChangeTextEvent
import com.swmansion.enriched.events.OnCheckboxPressEvent
import com.swmansion.enriched.events.OnColorChangeEvent
import com.swmansion.enriched.events.OnContextMenuItemPressEvent
import com.swmansion.enriched.events.OnInputBlurEvent
import com.swmansion.enriched.events.OnInputFocusEvent
import com.swmansion.enriched.events.OnInputKeyPressEvent
import com.swmansion.enriched.events.OnLinkDetectedEvent
import com.swmansion.enriched.events.OnMentionDetectedEvent
import com.swmansion.enriched.events.OnMentionEvent
import com.swmansion.enriched.events.OnRequestHtmlResultEvent
import com.swmansion.enriched.events.OnScrollEvent
import com.swmansion.enriched.loaders.EnrichedCookieManager
import com.swmansion.enriched.spans.TextStyle
import com.swmansion.enriched.styles.HtmlStyle
import com.swmansion.enriched.utils.jsonStringToStringMap
import com.swmansion.enriched.watchers.EnrichedScrollWatcher

@ReactModule(name = EnrichedTextInputViewManager.NAME)
class EnrichedTextInputViewManager :
  SimpleViewManager<EnrichedTextInputView>(),
  EnrichedTextInputViewManagerInterface<EnrichedTextInputView> {
  private val mDelegate: ViewManagerDelegate<EnrichedTextInputView> =
    EnrichedTextInputViewManagerDelegate(this)

  override fun getDelegate(): ViewManagerDelegate<EnrichedTextInputView>? = mDelegate

  override fun getName(): String = NAME

  public override fun createViewInstance(context: ThemedReactContext): EnrichedTextInputView = EnrichedTextInputView(context)

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
    map.put(OnInputFocusEvent.EVENT_NAME, mapOf(REGISTRATION_NAME to OnInputFocusEvent.EVENT_NAME))
    map.put(OnInputBlurEvent.EVENT_NAME, mapOf(REGISTRATION_NAME to OnInputBlurEvent.EVENT_NAME))
    map.put(OnChangeTextEvent.EVENT_NAME, mapOf(REGISTRATION_NAME to OnChangeTextEvent.EVENT_NAME))
    map.put(OnChangeHtmlEvent.EVENT_NAME, mapOf(REGISTRATION_NAME to OnChangeHtmlEvent.EVENT_NAME))
    map.put(OnChangeStateEvent.EVENT_NAME, mapOf(REGISTRATION_NAME to OnChangeStateEvent.EVENT_NAME))
    map.put(OnLinkDetectedEvent.EVENT_NAME, mapOf(REGISTRATION_NAME to OnLinkDetectedEvent.EVENT_NAME))
    map.put(OnMentionDetectedEvent.EVENT_NAME, mapOf(REGISTRATION_NAME to OnMentionDetectedEvent.EVENT_NAME))
    map.put(OnMentionEvent.EVENT_NAME, mapOf(REGISTRATION_NAME to OnMentionEvent.EVENT_NAME))
    map.put(OnChangeSelectionEvent.EVENT_NAME, mapOf(REGISTRATION_NAME to OnChangeSelectionEvent.EVENT_NAME))
    map.put(OnRequestHtmlResultEvent.EVENT_NAME, mapOf(REGISTRATION_NAME to OnRequestHtmlResultEvent.EVENT_NAME))
    map.put(OnColorChangeEvent.EVENT_NAME, mapOf(REGISTRATION_NAME to OnColorChangeEvent.EVENT_NAME))
    map.put(OnAlignmentChangeEvent.EVENT_NAME, mapOf(REGISTRATION_NAME to OnAlignmentChangeEvent.EVENT_NAME))
    map.put(OnScrollEvent.TOP_EVENT_NAME, mapOf(REGISTRATION_NAME to OnScrollEvent.EVENT_NAME))
    map.put(OnCheckboxPressEvent.EVENT_NAME, mapOf(REGISTRATION_NAME to OnCheckboxPressEvent.EVENT_NAME))
    map.put(OnAnyContentChangeEvent.EVENT_NAME, mapOf(REGISTRATION_NAME to OnAnyContentChangeEvent.EVENT_NAME))
    map.put(OnInputKeyPressEvent.EVENT_NAME, mapOf(REGISTRATION_NAME to OnInputKeyPressEvent.EVENT_NAME))
    map.put(OnContextMenuItemPressEvent.EVENT_NAME, mapOf(REGISTRATION_NAME to OnContextMenuItemPressEvent.EVENT_NAME))

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
    view?.styleManipulator?.parametrizedStyles?.mentionIndicators = indicatorsArray
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

  @ReactProp(name = ViewProps.BORDER_WIDTH)
  override fun setBorderWidth(
    view: EnrichedTextInputView?,
    width: Float,
  ) {
    setBorderWidth(view, LogicalEdge.ALL, width)
  }

  @ReactProp(name = ViewProps.BORDER_LEFT_WIDTH)
  override fun setBorderLeftWidth(
    view: EnrichedTextInputView?,
    width: Float,
  ) {
    setBorderWidth(view, LogicalEdge.LEFT, width)
  }

  @ReactProp(name = ViewProps.BORDER_RIGHT_WIDTH)
  override fun setBorderRightWidth(
    view: EnrichedTextInputView?,
    width: Float,
  ) {
    setBorderWidth(view, LogicalEdge.RIGHT, width)
  }

  @ReactProp(name = ViewProps.BORDER_TOP_WIDTH)
  override fun setBorderTopWidth(
    view: EnrichedTextInputView?,
    width: Float,
  ) {
    setBorderWidth(view, LogicalEdge.TOP, width)
  }

  @ReactProp(name = ViewProps.BORDER_BOTTOM_WIDTH)
  override fun setBorderBottomWidth(
    view: EnrichedTextInputView?,
    width: Float,
  ) {
    setBorderWidth(view, LogicalEdge.BOTTOM, width)
  }

  @ReactProp(name = ViewProps.BORDER_START_WIDTH)
  override fun setBorderStartWidth(
    view: EnrichedTextInputView?,
    width: Float,
  ) {
    setBorderWidth(view, LogicalEdge.START, width)
  }

  @ReactProp(name = ViewProps.BORDER_END_WIDTH)
  override fun setBorderEndWidth(
    view: EnrichedTextInputView?,
    width: Float,
  ) {
    setBorderWidth(view, LogicalEdge.END, width)
  }

  @ReactProp(name = ViewProps.BORDER_COLOR, customType = "Color")
  override fun setBorderColor(
    view: EnrichedTextInputView?,
    color: Int?,
  ) {
    setBorderColor(view, LogicalEdge.ALL, color)
  }

  @ReactProp(name = ViewProps.BORDER_LEFT_COLOR, customType = "Color")
  override fun setBorderLeftColor(
    view: EnrichedTextInputView?,
    color: Int?,
  ) {
    setBorderColor(view, LogicalEdge.LEFT, color)
  }

  @ReactProp(name = ViewProps.BORDER_RIGHT_COLOR, customType = "Color")
  override fun setBorderRightColor(
    view: EnrichedTextInputView?,
    color: Int?,
  ) {
    setBorderColor(view, LogicalEdge.RIGHT, color)
  }

  @ReactProp(name = ViewProps.BORDER_TOP_COLOR, customType = "Color")
  override fun setBorderTopColor(
    view: EnrichedTextInputView?,
    color: Int?,
  ) {
    setBorderColor(view, LogicalEdge.TOP, color)
  }

  @ReactProp(name = ViewProps.BORDER_BOTTOM_COLOR, customType = "Color")
  override fun setBorderBottomColor(
    view: EnrichedTextInputView?,
    color: Int?,
  ) {
    setBorderColor(view, LogicalEdge.BOTTOM, color)
  }

  @ReactProp(name = ViewProps.BORDER_START_COLOR, customType = "Color")
  override fun setBorderStartColor(
    view: EnrichedTextInputView?,
    color: Int?,
  ) {
    setBorderColor(view, LogicalEdge.START, color)
  }

  @ReactProp(name = ViewProps.BORDER_END_COLOR, customType = "Color")
  override fun setBorderEndColor(
    view: EnrichedTextInputView?,
    color: Int?,
  ) {
    setBorderColor(view, LogicalEdge.END, color)
  }

  @ReactProp(name = ViewProps.BORDER_BLOCK_COLOR, customType = "Color")
  override fun setBorderBlockColor(
    view: EnrichedTextInputView?,
    color: Int?,
  ) {
    setBorderColor(view, LogicalEdge.BLOCK, color)
  }

  @ReactProp(name = ViewProps.BORDER_BLOCK_START_COLOR, customType = "Color")
  override fun setBorderBlockStartColor(
    view: EnrichedTextInputView?,
    color: Int?,
  ) {
    setBorderColor(view, LogicalEdge.BLOCK_START, color)
  }

  @ReactProp(name = ViewProps.BORDER_BLOCK_END_COLOR, customType = "Color")
  override fun setBorderBlockEndColor(
    view: EnrichedTextInputView?,
    color: Int?,
  ) {
    setBorderColor(view, LogicalEdge.BLOCK_END, color)
  }

  @ReactProp(name = ViewProps.BORDER_RADIUS)
  override fun setBorderRadius(
    view: EnrichedTextInputView?,
    radius: Float,
  ) {
    setBorderRadius(view, BorderRadiusProp.BORDER_RADIUS, radius)
  }

  @ReactProp(name = ViewProps.BORDER_TOP_LEFT_RADIUS)
  override fun setBorderTopLeftRadius(
    view: EnrichedTextInputView?,
    radius: Float,
  ) {
    setBorderRadius(view, BorderRadiusProp.BORDER_TOP_LEFT_RADIUS, radius)
  }

  @ReactProp(name = ViewProps.BORDER_TOP_RIGHT_RADIUS)
  override fun setBorderTopRightRadius(
    view: EnrichedTextInputView?,
    radius: Float,
  ) {
    setBorderRadius(view, BorderRadiusProp.BORDER_TOP_RIGHT_RADIUS, radius)
  }

  @ReactProp(name = ViewProps.BORDER_BOTTOM_LEFT_RADIUS)
  override fun setBorderBottomLeftRadius(
    view: EnrichedTextInputView?,
    radius: Float,
  ) {
    setBorderRadius(view, BorderRadiusProp.BORDER_BOTTOM_LEFT_RADIUS, radius)
  }

  @ReactProp(name = ViewProps.BORDER_BOTTOM_RIGHT_RADIUS)
  override fun setBorderBottomRightRadius(
    view: EnrichedTextInputView?,
    radius: Float,
  ) {
    setBorderRadius(view, BorderRadiusProp.BORDER_BOTTOM_RIGHT_RADIUS, radius)
  }

  @ReactProp(name = ViewProps.BORDER_TOP_START_RADIUS)
  override fun setBorderTopStartRadius(
    view: EnrichedTextInputView?,
    radius: Float,
  ) {
    setBorderRadius(view, BorderRadiusProp.BORDER_TOP_START_RADIUS, radius)
  }

  @ReactProp(name = ViewProps.BORDER_TOP_END_RADIUS)
  override fun setBorderTopEndRadius(
    view: EnrichedTextInputView?,
    radius: Float,
  ) {
    setBorderRadius(view, BorderRadiusProp.BORDER_TOP_END_RADIUS, radius)
  }

  @ReactProp(name = ViewProps.BORDER_BOTTOM_START_RADIUS)
  override fun setBorderBottomStartRadius(
    view: EnrichedTextInputView?,
    radius: Float,
  ) {
    setBorderRadius(view, BorderRadiusProp.BORDER_BOTTOM_START_RADIUS, radius)
  }

  @ReactProp(name = ViewProps.BORDER_BOTTOM_END_RADIUS)
  override fun setBorderBottomEndRadius(
    view: EnrichedTextInputView?,
    radius: Float,
  ) {
    setBorderRadius(view, BorderRadiusProp.BORDER_BOTTOM_END_RADIUS, radius)
  }

  @ReactProp(name = ViewProps.BORDER_START_START_RADIUS)
  override fun setBorderStartStartRadius(
    view: EnrichedTextInputView?,
    radius: Float,
  ) {
    setBorderRadius(view, BorderRadiusProp.BORDER_START_START_RADIUS, radius)
  }

  @ReactProp(name = ViewProps.BORDER_START_END_RADIUS)
  override fun setBorderStartEndRadius(
    view: EnrichedTextInputView?,
    radius: Float,
  ) {
    setBorderRadius(view, BorderRadiusProp.BORDER_START_END_RADIUS, radius)
  }

  @ReactProp(name = ViewProps.BORDER_END_START_RADIUS)
  override fun setBorderEndStartRadius(
    view: EnrichedTextInputView?,
    radius: Float,
  ) {
    setBorderRadius(view, BorderRadiusProp.BORDER_END_START_RADIUS, radius)
  }

  @ReactProp(name = ViewProps.BORDER_END_END_RADIUS)
  override fun setBorderEndEndRadius(
    view: EnrichedTextInputView?,
    radius: Float,
  ) {
    setBorderRadius(view, BorderRadiusProp.BORDER_END_END_RADIUS, radius)
  }

  @ReactProp(name = "borderStyle")
  override fun setBorderStyle(
    view: EnrichedTextInputView?,
    style: String?,
  ) {
    view ?: return
    BackgroundStyleApplicator.setBorderStyle(view, style?.let { BorderStyle.fromString(it) })
  }

  private fun setBorderWidth(
    view: EnrichedTextInputView?,
    edge: LogicalEdge,
    width: Float,
  ) {
    view ?: return
    BackgroundStyleApplicator.setBorderWidth(view, edge, width)
  }

  private fun setBorderColor(
    view: EnrichedTextInputView?,
    edge: LogicalEdge,
    color: Int?,
  ) {
    view ?: return
    BackgroundStyleApplicator.setBorderColor(view, edge, color)
  }

  private fun setBorderRadius(
    view: EnrichedTextInputView?,
    property: BorderRadiusProp,
    radius: Float,
  ) {
    view ?: return
    val borderRadius =
      LengthPercentage(radius, LengthPercentageType.POINT)
    BackgroundStyleApplicator.setBorderRadius(view, property, borderRadius)
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

  @ReactProp(name = "paragraphsLimit")
  override fun setParagraphsLimit(
    view: EnrichedTextInputView?,
    value: Int,
  ) {
    view?.paragraphsLimit = value
  }

  @ReactProp(name = "lineHeight")
  override fun setLineHeight(
    view: EnrichedTextInputView?,
    value: Float,
  ) {
    view?.setLineHeight(value.toInt())
  }

  @ReactProp(name = "writingToolsBehavior")
  override fun setWritingToolsBehavior(
    view: EnrichedTextInputView?,
    value: String?,
  ) {
    // NO-OP iOS only prop
  }

  override fun setContextMenuItems(
    view: EnrichedTextInputView?,
    value: ReadableArray?,
  ) {
    view?.setContextMenuItems(value)
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
    view?.styleManipulator?.setColor(color.toColorInt())
  }

  override fun removeColor(view: EnrichedTextInputView?) {
    view?.styleManipulator?.removeColor()
  }

  override fun addDividerAtNewLine(view: EnrichedTextInputView?) {
    view?.styleManipulator?.insertDivider()
  }

  override fun addLink(
    view: EnrichedTextInputView?,
    start: Int,
    end: Int,
    text: String,
    url: String,
  ) {
    view?.styleManipulator?.addLink(start, end, text, url)
  }

  override fun addImage(
    view: EnrichedTextInputView?,
    src: String,
    width: Float,
    height: Float,
  ) {
    view?.styleManipulator?.addImage(src, width, height)
  }

  override fun startMention(
    view: EnrichedTextInputView?,
    indicator: String,
  ) {
    view?.styleManipulator?.startMention(indicator)
  }

  override fun addMention(
    view: EnrichedTextInputView?,
    indicator: String,
    text: String,
    type: String,
    payload: String,
  ) {
    val attributes = jsonStringToStringMap(payload)
    view?.styleManipulator?.addMention(text, indicator, type, attributes)
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
    view?.styleManipulator?.setParagraphAlignment(alignment)
  }

  override fun hideContextMenu(view: EnrichedTextInputView?) {
    view?.hideContextMenu()
  }

  override fun setKeyboardDismissMode(
    view: EnrichedTextInputView?,
    value: String?,
  ) {
    // iOS only prop
  }

  override fun setContentInsets(
    view: EnrichedTextInputView?,
    value: ReadableMap?,
  ) {
    // iOS only prop
  }

  override fun setScrollIndicatorInsets(
    view: EnrichedTextInputView?,
    value: ReadableMap?,
  ) {
    // iOS only prop
  }

  override fun setAutomaticallyAdjustsScrollIndicatorInsets(
    view: EnrichedTextInputView,
    value: Boolean,
  ) {
    // iOS only prop
  }

  override fun setAutomaticallyAdjustContentInsets(
    view: EnrichedTextInputView?,
    value: Boolean,
  ) {
    // iOS only prop
  }

  override fun setIOSparagraphSpacing(
    view: EnrichedTextInputView?,
    value: Float,
  ) {
    // iOS only prop
  }

  override fun setIOSparagraphSpacingBefore(
    view: EnrichedTextInputView?,
    value: Float,
  ) {
    // iOS only prop
  }

  override fun setLoaderCookies(
    view: EnrichedTextInputView?,
    value: ReadableArray?,
  ) {
    if (value == null) {
      EnrichedCookieManager.clear()
      return
    }

    val cookies = mutableListOf<EnrichedCookieManager.Cookie>()

    for (i in 0 until value.size()) {
      val item = value.getMap(i) ?: continue

      val domain = item.getString("domain")
      val name = item.getString("name")
      val valueStr = item.getString("value")

      if (domain.isNullOrEmpty() ||
        name.isNullOrEmpty() ||
        valueStr.isNullOrEmpty()
      ) {
        continue
      }

      cookies +=
        EnrichedCookieManager.Cookie(
          domain = domain,
          name = name,
          value = valueStr,
        )
    }

    EnrichedCookieManager.setCookies(cookies)
  }

  override fun setIsOnScrollSet(
    view: EnrichedTextInputView?,
    onScroll: Boolean,
  ) {
    if (onScroll) {
      view?.setScrollWatcher(EnrichedScrollWatcher(view))
    } else {
      view?.setScrollWatcher(null)
    }
  }

  override fun setStylesConfig(
    view: EnrichedTextInputView?,
    value: ReadableArray?,
  ) {
    val styles =
      value
        ?.toArrayList()
        ?.filterIsInstance<String>()

    view?.setStylesConfig(styles)
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

  override fun addContent(
    view: EnrichedTextInputView?,
    text: String,
    type: String,
    src: String,
    attributes: String,
  ) {
    val attributesMap = jsonStringToStringMap(attributes)
    view?.styleManipulator?.addContent(text, type, src, attributesMap)
  }

  override fun insertTextAtSelection(
    view: EnrichedTextInputView?,
    text: String,
  ) {
    view?.insertText(text)
  }

  override fun insertText(
    view: EnrichedTextInputView?,
    text: String,
    start: Int,
    end: Int,
  ) {
    view?.insertText(text, start, end)
  }

  override fun removeLink(
    view: EnrichedTextInputView?,
    start: Int,
    end: Int,
  ) {
    view?.styleManipulator?.removeLink(start, end)
  }

  companion object {
    const val NAME = "EnrichedTextInputView"
    const val REGISTRATION_NAME = "registrationName"
  }
}
