package com.swmansion.enriched

import com.facebook.react.BaseReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.model.ReactModuleInfo
import com.facebook.react.module.model.ReactModuleInfoProvider
import com.facebook.react.uimanager.ViewManager
import com.swmansion.enriched.text.EnrichedTextMeasurement
import com.swmansion.enriched.text.EnrichedTextViewManager
import com.swmansion.enriched.utils.ResourceManager
import java.util.ArrayList

class EnrichedTextInputViewPackage : BaseReactPackage() {
  override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
    ResourceManager.init(reactContext.applicationContext)
    EnrichedTextMeasurement.context = reactContext
    val viewManagers: MutableList<ViewManager<*, *>> = ArrayList()
    viewManagers.add(EnrichedTextInputViewManager())
    viewManagers.add(EnrichedTextViewManager())
    return viewManagers
  }

  override fun getModule(
    name: String,
    reactContext: ReactApplicationContext,
  ): NativeModule? =
    when (name) {
      NativeEnrichedHtmlStylesSpec.NAME -> EnrichedHtmlStylesModule(reactContext)
      else -> null
    }

  override fun getReactModuleInfoProvider(): ReactModuleInfoProvider =
    ReactModuleInfoProvider {
      mapOf(
        NativeEnrichedHtmlStylesSpec.NAME to
          ReactModuleInfo(
            name = NativeEnrichedHtmlStylesSpec.NAME,
            className = EnrichedHtmlStylesModule::class.java.name,
            canOverrideExistingModule = false,
            needsEagerInit = false,
            isCxxModule = false,
            isTurboModule = true,
          ),
      )
    }
}
