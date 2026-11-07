#pragma once
#import <UIKit/UIKit.h>

@class EnrichedTextPressRecognizer, MentionParams;

NS_ASSUME_NONNULL_BEGIN

// A link or a mention of the text, which can be pressed
@interface EnrichedTextPressableRange : NSObject
@property(nonatomic) NSRange range;
@property(nonatomic, copy, nullable) NSString *url;
@property(nonatomic, strong, nullable) MentionParams *mention;
@end

@protocol EnrichedTextPressRecognizerDelegate <NSObject>

- (nullable EnrichedTextPressableRange *)
          pressRecognizer:(EnrichedTextPressRecognizer *)pressRecognizer
    pressableRangeAtPoint:(CGPoint)point;

- (BOOL)pressRecognizer:(EnrichedTextPressRecognizer *)pressRecognizer
                  range:(EnrichedTextPressableRange *)range
          containsPoint:(CGPoint)point;

- (BOOL)pressRecognizer:(EnrichedTextPressRecognizer *)pressRecognizer
      canLongPressRange:(EnrichedTextPressableRange *)range;

- (void)pressRecognizer:(EnrichedTextPressRecognizer *)pressRecognizer
    didBeginPressingRange:(EnrichedTextPressableRange *)range;

// The touch is lifted, moved away or cancelled
- (void)pressRecognizer:(EnrichedTextPressRecognizer *)pressRecognizer
    didEndPressingRange:(EnrichedTextPressableRange *)range;

- (void)pressRecognizer:(EnrichedTextPressRecognizer *)pressRecognizer
            didTapRange:(EnrichedTextPressableRange *)range;

- (void)pressRecognizer:(EnrichedTextPressRecognizer *)pressRecognizer
      didLongPressRange:(EnrichedTextPressableRange *)range;

@end

/*
 * Recognizes a press on a link or a mention: it begins on the touch down, and
 * ends with a tap when the touch is lifted on the range, or with a long press
 * when the touch is held.
 *
 * As it begins on the touch down, the gesture recognizers of the views below
 * (e.g. a tap on the message, of react-native-gesture-handler) can't
 * recognize the touch too, unless they recognize along with it (a scroll).
 */
@interface EnrichedTextPressRecognizer : UIGestureRecognizer

@property(nonatomic, weak, nullable) id<EnrichedTextPressRecognizerDelegate>
    pressDelegate;

@property(nonatomic, readonly, nullable)
    EnrichedTextPressableRange *pressedRange;

@end

NS_ASSUME_NONNULL_END
