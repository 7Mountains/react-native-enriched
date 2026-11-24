package com.swmansion.enriched.styles

import com.facebook.react.bridge.JavaOnlyMap
import com.facebook.react.bridge.ReadableMap
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger

/**
 * The html styles of `EnrichedTextView` by their ids: JS registers a style
 * once (see `EnrichedHtmlStylesModule`), and the texts pass only its id.
 */
internal object HtmlStyleRegistry {
  private val styles = ConcurrentHashMap<Int, ReadableMap>()
  private val lastId = AtomicInteger()

  /** @return The id of the style, never 0 */
  fun register(style: ReadableMap): Int {
    val id = lastId.incrementAndGet()
    // A Java copy: read on any thread, without JNI
    styles[id] = JavaOnlyMap.deepClone(style)
    return id
  }

  fun get(id: Int): ReadableMap? = styles[id]
}
