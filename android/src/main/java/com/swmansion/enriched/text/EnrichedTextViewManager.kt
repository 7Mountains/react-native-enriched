package com.swmansion.enriched.text

import android.content.Context
import com.facebook.react.bridge.Dynamic
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.ReadableType
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.BackgroundStyleApplicator
import com.facebook.react.uimanager.LengthPercentage
import com.facebook.react.uimanager.LengthPercentageType
import com.facebook.react.uimanager.ReactStylesDiffMap
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.StateWrapper
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.ViewProps
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.uimanager.style.BorderRadiusProp
import com.facebook.react.uimanager.style.LogicalEdge
import com.facebook.react.viewmanagers.EnrichedTextViewManagerDelegate
import com.facebook.react.viewmanagers.EnrichedTextViewManagerInterface
import com.facebook.yoga.YogaMeasureMode
import com.swmansion.enriched.text.events.EnrichedTextSpanPressEvent

@ReactModule(name = EnrichedTextViewManager.NAME)
class EnrichedTextViewManager :
  SimpleViewManager<EnrichedTextView>(),
  EnrichedTextViewManagerInterface<EnrichedTextView> {
  private val delegate: ViewManagerDelegate<EnrichedTextView> = EnrichedTextViewManagerDelegate(this)

  init {
    // The views are reused, e.g. by the rows of a list: it takes effect with
    // React Native's `enableViewRecycling` feature flag
    setupViewRecycling()
  }

  override fun getDelegate(): ViewManagerDelegate<EnrichedTextView> = delegate

  override fun getName(): String = NAME

  override fun createViewInstance(context: ThemedReactContext): EnrichedTextView = EnrichedTextView(context)

  override fun prepareToRecycleView(
    reactContext: ThemedReactContext,
    view: EnrichedTextView,
  ): EnrichedTextView? {
    super.prepareToRecycleView(reactContext, view)
    view.prepareForRecycle()
    return view
  }

  override fun getExportedCustomDirectEventTypeConstants(): MutableMap<String, Any> =
    EnrichedTextSpanPressEvent.EVENT_NAMES.associateWithTo(mutableMapOf()) { mapOf(REGISTRATION_NAME to it) }

  override fun setText(
    view: EnrichedTextView?,
    value: String?,
  ) {
    view?.setValue(value)
  }

  override fun setHtmlStyle(
    view: EnrichedTextView?,
    value: Dynamic,
  ) {
    view?.setHtmlStyle(if (value.type == ReadableType.Map) value.asMap() else null)
  }

  override fun setNumberOfLines(
    view: EnrichedTextView?,
    value: Int,
  ) {
    view?.setNumberOfLines(value)
  }

  override fun setEllipsizeMode(
    view: EnrichedTextView?,
    value: String?,
  ) {
    view?.setEllipsizeMode(value)
  }

  override fun setSelectable(
    view: EnrichedTextView?,
    value: Boolean,
  ) {
    view?.setSelectable(value)
  }

  override fun setPressableLinks(
    view: EnrichedTextView?,
    value: Boolean,
  ) {
    view?.pressableLinks = value
  }

  override fun setPressableMentions(
    view: EnrichedTextView?,
    value: Boolean,
  ) {
    view?.pressableMentions = value
  }

  override fun setLongPressableLinks(
    view: EnrichedTextView?,
    value: Boolean,
  ) {
    view?.longPressableLinks = value
  }

  override fun setLongPressableMentions(
    view: EnrichedTextView?,
    value: Boolean,
  ) {
    view?.longPressableMentions = value
  }

  override fun setSelectionColor(
    view: EnrichedTextView?,
    value: Int?,
  ) {
    view?.setSelectionColor(value)
  }

  override fun setAllowFontScaling(
    view: EnrichedTextView?,
    value: Boolean,
  ) {
    view?.setAllowFontScaling(value)
  }

  override fun setColor(
    view: EnrichedTextView?,
    value: Int?,
  ) {
    view?.setColor(value)
  }

  override fun setFontSize(
    view: EnrichedTextView?,
    value: Float,
  ) {
    view?.setFontSize(value)
  }

  override fun setLineHeight(
    view: EnrichedTextView?,
    value: Float,
  ) {
    view?.setLineHeightValue(value)
  }

  override fun setFontFamily(
    view: EnrichedTextView?,
    value: String?,
  ) {
    view?.setFontFamily(value)
  }

  override fun setFontWeight(
    view: EnrichedTextView?,
    value: String?,
  ) {
    view?.setFontWeight(value)
  }

  override fun setFontStyle(
    view: EnrichedTextView?,
    value: String?,
  ) {
    view?.setFontStyle(value)
  }

  @ReactProp(name = ViewProps.BORDER_WIDTH)
  override fun setBorderWidth(
    view: EnrichedTextView?,
    value: Float,
  ) {
    view ?: return
    BackgroundStyleApplicator.setBorderWidth(view, LogicalEdge.ALL, value)
  }

  @ReactProp(name = ViewProps.BORDER_COLOR, customType = "Color")
  override fun setBorderColor(
    view: EnrichedTextView?,
    value: Int?,
  ) {
    view ?: return
    BackgroundStyleApplicator.setBorderColor(view, LogicalEdge.ALL, value)
  }

  @ReactProp(name = ViewProps.BORDER_TOP_END_RADIUS)
  override fun setBorderTopEndRadius(
    view: EnrichedTextView?,
    value: Float,
  ) {
    setBorderRadius(view, BorderRadiusProp.BORDER_TOP_END_RADIUS, value)
  }

  @ReactProp(name = ViewProps.BORDER_BOTTOM_START_RADIUS)
  override fun setBorderBottomStartRadius(
    view: EnrichedTextView?,
    value: Float,
  ) {
    setBorderRadius(view, BorderRadiusProp.BORDER_BOTTOM_START_RADIUS, value)
  }

  @ReactProp(name = ViewProps.BORDER_BOTTOM_END_RADIUS)
  override fun setBorderBottomEndRadius(
    view: EnrichedTextView?,
    value: Float,
  ) {
    setBorderRadius(view, BorderRadiusProp.BORDER_BOTTOM_END_RADIUS, value)
  }

  private fun setBorderRadius(
    view: EnrichedTextView?,
    property: BorderRadiusProp,
    value: Float,
  ) {
    view ?: return
    val radius = LengthPercentage(value, LengthPercentageType.POINT)
    BackgroundStyleApplicator.setBorderRadius(view, property, radius)
  }

  override fun setPadding(
    view: EnrichedTextView?,
    left: Int,
    top: Int,
    right: Int,
    bottom: Int,
  ) {
    super.setPadding(view, left, top, right, bottom)
    view?.setPadding(left, top, right, bottom)
  }

  // The text is applied with the state, after the props
  override fun updateState(
    view: EnrichedTextView,
    props: ReactStylesDiffMap?,
    stateWrapper: StateWrapper?,
  ): Any? {
    view.setPreparedText(EnrichedTextStateReader.readText(stateWrapper))
    return null
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
  ): Long = EnrichedTextMeasurement.measure(context, props, width, widthMode, height, heightMode)

  companion object {
    const val NAME = "EnrichedTextView"
    private const val REGISTRATION_NAME = "registrationName"
  }
}
