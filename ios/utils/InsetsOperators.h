#pragma once
#import <UIKit/UIKit.h>
#import <react/renderer/components/RNEnrichedTextInputViewSpec/Props.h>

using namespace facebook::react;

// ---- ContentInsets ----

inline UIEdgeInsets
toUIEdgeInsets(const EnrichedTextInputViewContentInsetsStruct &v) {
  return UIEdgeInsetsMake(v.top, v.left, v.bottom, v.right);
}

inline UIEdgeInsets
operator+(const UIEdgeInsets &a,
          const EnrichedTextInputViewContentInsetsStruct &b) {

  return UIEdgeInsetsMake(a.top + b.top, a.left + b.left, a.bottom + b.bottom,
                          a.right + b.right);
}

inline bool operator==(const EnrichedTextInputViewContentInsetsStruct &a,
                       const EnrichedTextInputViewContentInsetsStruct &b) {

  return a.top == b.top && a.left == b.left && a.bottom == b.bottom &&
         a.right == b.right;
}

inline bool operator!=(const EnrichedTextInputViewContentInsetsStruct &a,
                       const EnrichedTextInputViewContentInsetsStruct &b) {
  return !(a == b);
}

inline EnrichedTextInputViewContentInsetsStruct
operator+(const EnrichedTextInputViewContentInsetsStruct &a,
          const EnrichedTextInputViewContentInsetsStruct &b) {

  return EnrichedTextInputViewContentInsetsStruct{.top = a.top + b.top,
                                                  .left = a.left + b.left,
                                                  .bottom = a.bottom + b.bottom,
                                                  .right = a.right + b.right};
}

// ---- ScrollIndicatorInsets ----

inline bool
operator==(const EnrichedTextInputViewScrollIndicatorInsetsStruct &a,
           const EnrichedTextInputViewScrollIndicatorInsetsStruct &b) {

  return a.top == b.top && a.left == b.left && a.bottom == b.bottom &&
         a.right == b.right;
}

inline bool
operator!=(const EnrichedTextInputViewScrollIndicatorInsetsStruct &a,
           const EnrichedTextInputViewScrollIndicatorInsetsStruct &b) {
  return !(a == b);
}

inline UIEdgeInsets
toUIEdgeInsets(const EnrichedTextInputViewScrollIndicatorInsetsStruct &v) {
  return UIEdgeInsetsMake(v.top, v.left, v.bottom, v.right);
}
