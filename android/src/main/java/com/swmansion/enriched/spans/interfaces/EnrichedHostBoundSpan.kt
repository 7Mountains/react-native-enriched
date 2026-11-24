package com.swmansion.enriched.spans.interfaces

import com.swmansion.enriched.EnrichedHtmlHost

/**
 * A span bound to the host showing it, redrawn by the host when its state
 * changes on the host's thread (e.g. when its image loads). Its size doesn't
 * depend on that state: a measurement can lay it out on another thread.
 */
interface EnrichedHostBoundSpan {
  fun attachTo(host: EnrichedHtmlHost)
}
