#pragma once

#include <folly/dynamic.h>

namespace facebook::react {

class EnrichedTextInputState {
public:
  EnrichedTextInputState() : contentHeight_(0) {}

  // Used by Kotlin to set current text value
  EnrichedTextInputState(EnrichedTextInputState const &previousState,
                         folly::dynamic data)
      : contentHeight_((int)data["height"].getInt()){};
  folly::dynamic getDynamic() const { return {}; };

  int getHeight() const;

private:
  const int contentHeight_{};
};

} // namespace facebook::react
