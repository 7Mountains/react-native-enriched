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

@end

NS_ASSUME_NONNULL_END
