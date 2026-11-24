#pragma once
#include <folly/dynamic.h>
#include <react/renderer/components/RNEnrichedTextInputViewSpec/Props.h>

#include <memory>

namespace facebook::react {

// The html styles of <EnrichedTextView> by their ids: JS registers a style
// once (see `EnrichedHtmlStyles`), and the texts pass only its id
class EnrichedHtmlStyleRegistry {
public:
  // The style parsed once, as the html style of the input. Returns its id,
  // never 0
  static int registerStyle(const folly::dynamic &style);

  // `nullptr` for an unknown id (e.g. 0, the default style)
  static std::shared_ptr<const EnrichedTextInputViewHtmlStyleStruct>
  get(int id);
};

} // namespace facebook::react
