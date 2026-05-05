package com.swmansion.enriched.managers

class EnrichedTransactionManager {
  private var transactionCount = 0
  private var blockTextEventEmittingCount = 0
  private var ignoreSpanWatcherCount = 0

  val isDuringTransaction: Boolean
    get() = transactionCount > 0

  val blockTextEventEmitting: Boolean
    get() = blockTextEventEmittingCount > 0

  val ignoreSpanWatcher: Boolean
    get() = ignoreSpanWatcherCount > 0

  fun <T> runTransaction(block: () -> T): T =
    increment(
      increase = { transactionCount++ },
      decrease = { transactionCount-- },
      block = block,
    )

  fun <T> runWithBlockedTextEvents(block: () -> T): T =
    increment(
      increase = { blockTextEventEmittingCount++ },
      decrease = { blockTextEventEmittingCount-- },
      block = block,
    )

  fun <T> runWithIgnoredSpanWatcher(block: () -> T): T =
    increment(
      increase = { ignoreSpanWatcherCount++ },
      decrease = { ignoreSpanWatcherCount-- },
      block = block,
    )

  fun <T> runSilently(block: () -> T): T =
    runTransaction {
      runWithBlockedTextEvents {
        runWithIgnoredSpanWatcher {
          block()
        }
      }
    }

  private inline fun <T> increment(
    increase: () -> Unit,
    decrease: () -> Unit,
    block: () -> T,
  ): T {
    increase()
    try {
      return block()
    } finally {
      decrease()
    }
  }
}
