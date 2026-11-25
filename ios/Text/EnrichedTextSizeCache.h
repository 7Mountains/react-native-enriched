#pragma once
#include "EnrichedTextMeasureCache.h"

#include <react/renderer/graphics/Size.h>

namespace facebook::react {

// The sizes of the texts measured last (see `EnrichedTextMeasureCache`).
// Emptied when fonts are registered: a text measured before its font was
// registered was laid out with another one
EnrichedTextMeasureCache<Size> &EnrichedTextSizeCache();

} // namespace facebook::react
