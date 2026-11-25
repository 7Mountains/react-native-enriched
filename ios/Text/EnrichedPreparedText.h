#pragma once
#import <UIKit/UIKit.h>

@class EnrichedLaidOutText;
@class InputConfig;

NS_ASSUME_NONNULL_BEGIN

// The text of an EnrichedTextView built by its shadow node, for the view
// through the state, with the config its drawing reads (lists, quotes, code
// blocks, checkboxes)
@interface EnrichedPreparedText : NSObject

@property(nonatomic, readonly) NSAttributedString *text;
@property(nonatomic, readonly) InputConfig *config;

// Whether its lines are laid out the same in any container they fit: its
// paragraphs are aligned to the left, written left to right
@property(nonatomic, readonly) BOOL isLaidOutAtAnyWidth;

- (instancetype)initWithText:(NSAttributedString *)text
                      config:(InputConfig *)config;

// The size of the text laid out as the view lays it out (see
// `EnrichedTextBuilder`), on any thread. Measured again with the same
// constraints, the text isn't laid out again. The layout of the last
// measurement is kept for the view (see `takeLaidOutTextForSize:`)
- (CGSize)sizeConstrainedToWidth:(CGFloat)width
            maximumNumberOfLines:(NSInteger)maximumNumberOfLines
                   lineBreakMode:(NSLineBreakMode)lineBreakMode;

// The layout of the last measurement, when the view of this size draws it as
// it is: given once, then measured again for another view. On the main thread
- (nullable EnrichedLaidOutText *)
    takeLaidOutTextForSize:(CGSize)size
      maximumNumberOfLines:(NSInteger)maximumNumberOfLines
             lineBreakMode:(NSLineBreakMode)lineBreakMode;

@end

NS_ASSUME_NONNULL_END
