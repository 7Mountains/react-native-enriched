package com.swmansion.enriched.constants

object Strings {
  // Magic markers
  const val MAGIC_CHAR = '\uFEFF'
  const val MAGIC_STRING = "" + MAGIC_CHAR

  const val REPLACEMENT_MARKER_CHAR = '\u202F'
  const val REPLACEMENT_MARKER_STRING = "" + REPLACEMENT_MARKER_CHAR

  // Zero-width characters
  const val ZERO_WIDTH_SPACE_CHAR = '\u200B'
  const val ZERO_WIDTH_SPACE_STRING = "" + ZERO_WIDTH_SPACE_CHAR

  const val ZERO_WIDTH_NON_JOINER_CHAR = '\u200C'
  const val ZERO_WIDTH_NON_JOINER_STRING = "" + ZERO_WIDTH_NON_JOINER_CHAR

  const val ZERO_WIDTH_JOINER_CHAR = '\u200D'
  const val ZERO_WIDTH_JOINER_STRING = "" + ZERO_WIDTH_JOINER_CHAR

  // Object replacement (images)
  const val OBJECT_REPLACEMENT_CHAR = '\uFFFC'
  const val OBJECT_REPLACEMENT_STRING = "" + OBJECT_REPLACEMENT_CHAR

  // Newline
  const val NEWLINE = '\n'
  const val NEWLINE_STRING = "" + NEWLINE

  const val LT_CHAR = '<'
  const val GT_CHAR = '>'
  const val AMP_CHAR = '&'
  const val SPACE_CHAR = ' '

  // HTML tag delimiters
  const val LT = "<"
  const val GT = ">"
  const val LT_SLASH = "</"
  const val SLASH_GT = "/>"

  // escaping HTML
  const val ESC_LT = "&lt;"
  const val ESC_GT = "&gt;"
  const val ESC_AMP = "&amp;"
  const val ESC_NBSP = "&nbsp;"

  // End of buffer marker
  const val END_OF_BUFFER_MARKER = ZERO_WIDTH_SPACE_CHAR
  const val END_OF_BUFFER_MARKER_STRING = "" + END_OF_BUFFER_MARKER

  const val HTML_OPEN = "<html>"
  const val HTML_CLOSE = "</html>"
}
