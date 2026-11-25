#pragma once
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Draws the text of its container as its layout manager lays it out (with
// the paragraphs of LayoutManagerExtension): for EnrichedTextView when its
// text isn't selectable. Lighter than a text view: no scroll view, no tiles,
// no text input. Redrawn by its owner when the text or its layout changes
@interface EnrichedTextDrawingView : UIView

- (instancetype)initWithTextContainer:(NSTextContainer *)textContainer
    NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

// Replaced by the container of a text laid out elsewhere (see
// `EnrichedLaidOutText`)
@property(nonatomic, strong) NSTextContainer *textContainer;

@end

NS_ASSUME_NONNULL_END
