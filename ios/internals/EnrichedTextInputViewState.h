#pragma once
#include <memory>

@class NSAttributedString;

namespace facebook::react {

class EnrichedTextInputViewState {
public:
  EnrichedTextInputViewState() = default;

  explicit EnrichedTextInputViewState(NSAttributedString *attributedText)
      : attributedText_(attributedText) {}

  NSAttributedString *getAttributedText() const { return attributedText_; }

private:
  NSAttributedString *attributedText_ = nullptr;
};

} // namespace facebook::react
