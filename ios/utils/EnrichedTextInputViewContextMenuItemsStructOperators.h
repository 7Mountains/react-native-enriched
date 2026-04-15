#pragma once

#include <react/renderer/components/RNEnrichedTextInputViewSpec/Props.h>

namespace facebook {
namespace react {

inline bool operator==(const EnrichedTextInputViewContextMenuItemsStruct &a,
                       const EnrichedTextInputViewContextMenuItemsStruct &b) {

  return a.text == b.text && a.key == b.key && a.iOSIcon == b.iOSIcon;
}

inline bool operator!=(const EnrichedTextInputViewContextMenuItemsStruct &a,
                       const EnrichedTextInputViewContextMenuItemsStruct &b) {

  return !(a == b);
}

} // namespace react
} // namespace facebook
