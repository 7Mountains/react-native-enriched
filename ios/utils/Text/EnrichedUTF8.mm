#import "EnrichedUTF8.h"

#include <cstdint>

bool EnrichedValidUTF8Length(const char *string, size_t *length) {
  const auto *bytes = (const unsigned char *)string;
  size_t i = 0;
  while (bytes[i] != 0) {
    unsigned char lead = bytes[i];
    if (lead < 0x80) {
      i++;
      continue;
    }

    size_t trailing;
    uint32_t codePoint;
    if (lead >= 0xC2 && lead <= 0xDF) {
      trailing = 1;
      codePoint = lead & 0x1F;
    } else if (lead >= 0xE0 && lead <= 0xEF) {
      trailing = 2;
      codePoint = lead & 0x0F;
    } else if (lead >= 0xF0 && lead <= 0xF4) {
      trailing = 3;
      codePoint = lead & 0x07;
    } else {
      return false;
    }

    for (size_t k = 1; k <= trailing; k++) {
      unsigned char next = bytes[i + k];
      if ((next & 0xC0) != 0x80) {
        return false;
      }
      codePoint = (codePoint << 6) | (next & 0x3F);
    }

    if ((trailing == 2 &&
         (codePoint < 0x800 || (codePoint >= 0xD800 && codePoint <= 0xDFFF))) ||
        (trailing == 3 && (codePoint < 0x10000 || codePoint > 0x10FFFF))) {
      return false;
    }

    i += trailing + 1;
  }

  *length = i;
  return true;
}
