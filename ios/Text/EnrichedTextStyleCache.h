#pragma once
#import <UIKit/UIKit.h>
#include <react/renderer/components/RNEnrichedTextInputViewSpec/Props.h>

@class InputConfig;

NS_ASSUME_NONNULL_BEGIN

// The config and the typing attributes a text is built with
struct EnrichedTextStyle {
  InputConfig *config;
  NSDictionary<NSAttributedStringKey, id> *attributes;
};

// Built once for the texts with the same style and font, which share them:
// parsing the html style (e.g. its content styles and their fonts) is the
// slowest part. On any thread
EnrichedTextStyle
EnrichedTextStyleForProps(const facebook::react::EnrichedTextViewProps &props,
                          CGFloat fontSizeMultiplier);

NS_ASSUME_NONNULL_END
