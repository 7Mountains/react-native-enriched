#pragma once
#import <UIKit/UIKit.h>

@class InputConfig;

NS_ASSUME_NONNULL_BEGIN

// The text of an EnrichedTextView built by its shadow node, for the view
// through the state, with the config its drawing reads (lists, quotes, code
// blocks, checkboxes)
@interface EnrichedPreparedText : NSObject

@property(nonatomic, readonly) NSAttributedString *text;
@property(nonatomic, readonly) InputConfig *config;

- (instancetype)initWithText:(NSAttributedString *)text
                      config:(InputConfig *)config;

// The size of the text laid out as the view lays it out (see
// `EnrichedTextBuilder`), on any thread. Measured again with the same
// constraints, the text isn't laid out again: only its size is kept, not its
// layout
- (CGSize)sizeConstrainedToWidth:(CGFloat)width
            maximumNumberOfLines:(NSInteger)maximumNumberOfLines
                   lineBreakMode:(NSLineBreakMode)lineBreakMode;

@end

NS_ASSUME_NONNULL_END
