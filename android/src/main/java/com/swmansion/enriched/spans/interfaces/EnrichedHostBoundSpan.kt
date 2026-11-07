package com.swmansion.enriched.spans.interfaces

import com.swmansion.enriched.EnrichedHtmlHost

/**
 * A span bound to the host showing it: its state changes on the host's thread
 * (e.g. when its image loads), so it can't be laid out on another one
 */
interface EnrichedHostBoundSpan {
  fun attachTo(host: EnrichedHtmlHost)
}
