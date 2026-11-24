#pragma once
#include <cstddef>

// The length of a string up to its first null, as `NSString` reads it from
// UTF-8: false when it isn't valid UTF-8, which `NSString` doesn't read
bool EnrichedValidUTF8Length(const char *string, size_t *length);
