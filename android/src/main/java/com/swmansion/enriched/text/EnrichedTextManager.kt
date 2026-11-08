package com.swmansion.enriched.text

import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.viewmanagers.EnrichedTextManagerDelegate
import com.facebook.react.viewmanagers.EnrichedTextManagerInterface

/** Lightweight, non-selectable enriched text. */
@ReactModule(name = EnrichedTextManager.NAME)
class EnrichedTextManager :
  EnrichedTextViewManager(),
  EnrichedTextManagerInterface<EnrichedTextView> {
  private val textDelegate: ViewManagerDelegate<EnrichedTextView> = EnrichedTextManagerDelegate(this)

  override fun getDelegate(): ViewManagerDelegate<EnrichedTextView> = textDelegate

  override fun getName(): String = NAME

  companion object {
    const val NAME = "EnrichedText"
  }
}
