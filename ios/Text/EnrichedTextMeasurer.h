#pragma once
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Measures the texts of EnrichedTextView with TextKit 1, as the view lays
// them out (see `EnrichedTextBuilder`), on any thread
@interface EnrichedTextMeasurer : NSObject

+ (CGSize)sizeOfText:(NSAttributedString *)text
      constrainedToWidth:(CGFloat)width
    maximumNumberOfLines:(NSInteger)maximumNumberOfLines
           lineBreakMode:(NSLineBreakMode)lineBreakMode;

@end

NS_ASSUME_NONNULL_END
