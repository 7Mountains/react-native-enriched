#pragma once

#include "EnrichedTextState.h"

#include <folly/dynamic.h>
#include <react/renderer/core/LayoutConstraints.h>
#include <react/renderer/core/ReactPrimitives.h>
#include <react/utils/ContextContainer.h>

namespace facebook::react {

// Measures <EnrichedTextView> with its view manager (`measure`), the same
// layout of the text the view draws
class EnrichedTextMeasurementManager {
public:
  EnrichedTextMeasurementManager(
      const std::shared_ptr<const ContextContainer> &contextContainer)
      : contextContainer_(contextContainer) {}

  struct Measurement {
    Size size;
    EnrichedPreparedText prepared;
  };

  // `text`: the text built by a previous measurement of the same props and
  // width, not parsed again
  Measurement measure(SurfaceId surfaceId, const folly::dynamic &layoutProps,
                      LayoutConstraints layoutConstraints,
                      const EnrichedTextRef &text) const;

private:
  const std::shared_ptr<const ContextContainer> contextContainer_;
};

} // namespace facebook::react
