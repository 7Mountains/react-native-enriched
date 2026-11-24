#pragma once

#include "EnrichedTextState.h"

#include <react/renderer/components/RNEnrichedTextInputViewSpec/Props.h>
#include <react/renderer/core/LayoutConstraints.h>

namespace facebook::react {

// Measures <EnrichedTextView> with `EnrichedTextMeasurement` (Kotlin), the
// same layout of the text the view draws. Called directly with the props, not
// through `FabricUIManager.measure`, which takes them as a map
class EnrichedTextMeasurementManager {
public:
  struct Measurement {
    Size size;
    EnrichedPreparedText prepared;
  };

  // `text`: the text built by a previous measurement of the same props and
  // width, not parsed again
  Measurement measure(const EnrichedTextViewProps &props,
                      LayoutConstraints layoutConstraints,
                      const EnrichedTextRef &text) const;
};

} // namespace facebook::react
