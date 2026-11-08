#pragma once
#import <UIKit/UIKit.h>
#include <react/renderer/components/RNEnrichedTextInputViewSpec/Props.h>

@class EnrichedPreparedText;

NS_ASSUME_NONNULL_BEGIN

// Builds and measures the text of <EnrichedTextView> on any thread: the shadow
// node measures it with the layout the view shows (TextKit 1, as the input)
@interface EnrichedTextBuilder : NSObject

+ (EnrichedPreparedText *)
    preparedTextWithProps:(const facebook::react::EnrichedTextViewProps &)props
       fontSizeMultiplier:(CGFloat)fontSizeMultiplier;

+ (EnrichedPreparedText *)
    preparedTextWithLabelProps:(const facebook::react::EnrichedTextProps &)props
            fontSizeMultiplier:(CGFloat)fontSizeMultiplier;

+ (CGSize)sizeOfText:(NSAttributedString *)text
      constrainedToWidth:(CGFloat)width
    maximumNumberOfLines:(NSInteger)maximumNumberOfLines
           lineBreakMode:(NSLineBreakMode)lineBreakMode;

// The same container for the measurement and the view
+ (void)configureTextContainer:(NSTextContainer *)textContainer
          maximumNumberOfLines:(NSInteger)maximumNumberOfLines
                 lineBreakMode:(NSLineBreakMode)lineBreakMode;

@end

NSLineBreakMode
EnrichedNSLineBreakModeFromEllipsizeMode(const std::string &ellipsizeMode);

NS_ASSUME_NONNULL_END
