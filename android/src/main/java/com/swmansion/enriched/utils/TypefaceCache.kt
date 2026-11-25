package com.swmansion.enriched.utils

import android.content.res.AssetManager
import android.graphics.Typeface
import com.facebook.react.views.text.ReactTypefaceUtils

/** The typefaces of the texts by their font props, few in an app */
internal object TypefaceCache {
  private const val MAX_TYPEFACES = 32

  // Read without a lock on every measurement, replaced as a whole when one
  // is added. The app's assets, as React Native's font manager keeps them
  @Volatile
  private var typefaces = emptyArray<Entry>()
  private val lock = Any()

  fun get(
    fontFamily: String?,
    fontStyle: Int,
    fontWeight: Int,
    assets: AssetManager,
  ): Typeface {
    for (entry in typefaces) {
      if (entry.fontStyle == fontStyle && entry.fontWeight == fontWeight && entry.fontFamily == fontFamily) {
        return entry.typeface
      }
    }

    val typeface = ReactTypefaceUtils.applyStyles(null, fontStyle, fontWeight, fontFamily, assets)
    synchronized(lock) {
      if (typefaces.size < MAX_TYPEFACES) {
        typefaces += Entry(fontFamily, fontStyle, fontWeight, typeface)
      }
    }
    return typeface
  }

  private class Entry(
    val fontFamily: String?,
    val fontStyle: Int,
    val fontWeight: Int,
    val typeface: Typeface,
  )
}
