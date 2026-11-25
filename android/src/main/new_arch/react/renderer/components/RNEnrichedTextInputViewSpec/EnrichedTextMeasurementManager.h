#pragma once

#include "EnrichedTextMeasureCache.h"
#include "EnrichedTextState.h"

#include <react/renderer/components/RNEnrichedTextInputViewSpec/Props.h>
#include <react/renderer/core/LayoutConstraints.h>
#include <react/renderer/core/LayoutContext.h>

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
                      const LayoutContext &layoutContext,
                      LayoutConstraints layoutConstraints,
                      const EnrichedTextRef &text) const;

private:
  Measurement measureText(const EnrichedTextViewProps &props,
                          LayoutConstraints layoutConstraints,
                          const EnrichedTextRef &text, bool *isShareable) const;

  // With their texts, shown by the nodes as built: only the texts views can
  // show at once. One for each React instance: a text built for the previous
  // one isn't kept with its context
  mutable EnrichedTextMeasureCache<Measurement> cache_;
};

} // namespace facebook::react
