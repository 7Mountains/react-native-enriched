#pragma once
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// A text laid out by a measurement, with the TextKit 1 stack it's laid out
// in: drawn as it is by the view showing it (see EnrichedTextDrawingView).
// Used by one thread at a time: given to the view, not measured again
@interface EnrichedLaidOutText : NSObject

@property(nonatomic, readonly) NSTextStorage *textStorage;
@property(nonatomic, readonly) NSLayoutManager *layoutManager;
@property(nonatomic, readonly) NSTextContainer *textContainer;
@property(nonatomic, readonly) CGSize size;

- (instancetype)initWithTextStorage:(NSTextStorage *)textStorage
                      layoutManager:(NSLayoutManager *)layoutManager
                      textContainer:(NSTextContainer *)textContainer
                               size:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
