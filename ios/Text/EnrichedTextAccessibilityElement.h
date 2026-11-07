#pragma once
#import <UIKit/UIKit.h>

@class EnrichedTextPressableRange;

NS_ASSUME_NONNULL_BEGIN

@protocol EnrichedTextAccessibilityContainer <NSObject>
- (void)activatePressableRange:(EnrichedTextPressableRange *)range;
@end

/*
 * The text, or one of its links or mentions, for VoiceOver. Placed in the
 * space of its container, it follows the container when it moves (e.g.
 * scrolls).
 */
@interface EnrichedTextAccessibilityElement : UIAccessibilityElement

// The link or the mention VoiceOver presses, nil for the text
@property(nonatomic, strong, nullable)
    EnrichedTextPressableRange *pressableRange;

// Where VoiceOver touches (e.g. to double tap and hold), in the space of the
// container
@property(nonatomic) CGPoint activationPointInContainerSpace;

@end

NS_ASSUME_NONNULL_END
