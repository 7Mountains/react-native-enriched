package com.swmansion.enriched.constants

object Strings {
  const val MAGIC_CHAR = '\uFEFF' // '*'
  const val MAGIC_STRING = "" + MAGIC_CHAR
  const val REPLACEMENT_MARKER_CHAR = '\u202F'
  const val REPLACEMENT_MARKER_STRING = "" + REPLACEMENT_MARKER_CHAR
  const val ZWJ_CHAR = '\u200B' // '§'
  const val ZERO_WIDTH_PLACEHOLDER_CHAR = '\u200C'
  const val ZERO_WIDTH_PLACEHOLDER_STRING = "" + ZERO_WIDTH_PLACEHOLDER_CHAR
  const val ZWJ_STRING = "" + ZWJ_CHAR
  const val IMG_CHAR = '\uFFFC'
  const val IMG_STRING = "" + IMG_CHAR
  const val NEWLINE = '\n'
  const val NEWLINE_STRING = "" + NEWLINE
  const val END_OF_BUFFER_MARKER = ZWJ_CHAR
  const val END_OF_BUFFER_MARKER_STRING = "" + ZWJ_CHAR
}
