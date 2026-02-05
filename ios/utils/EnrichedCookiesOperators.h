#pragma once

#include <react/renderer/components/RNEnrichedTextInputViewSpec/Props.h>

namespace facebook {
namespace react {

inline bool operator==(const EnrichedTextInputViewLoaderCookiesStruct &a,
                       const EnrichedTextInputViewLoaderCookiesStruct &b) {

  return a.domain == b.domain && a.name == b.name && a.value == b.value;
}

inline bool operator!=(const EnrichedTextInputViewLoaderCookiesStruct &a,
                       const EnrichedTextInputViewLoaderCookiesStruct &b) {

  return !(a == b);
}

} // namespace react
} // namespace facebook
