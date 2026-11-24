package com.swmansion.enriched

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.module.annotations.ReactModule
import com.swmansion.enriched.styles.HtmlStyleRegistry

@ReactModule(name = NativeEnrichedHtmlStylesSpec.NAME)
class EnrichedHtmlStylesModule(
  reactContext: ReactApplicationContext,
) : NativeEnrichedHtmlStylesSpec(reactContext) {
  override fun registerHtmlStyle(style: ReadableMap): Double = HtmlStyleRegistry.register(style).toDouble()
}
