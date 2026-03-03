#pragma once
#import <UIKit/UIKit.h>

@class EnrichedTextInputView;

@interface SelectionUtils : NSObject
+ (UIColor *_Nullable)effectiveForegroundColorForSelectionInTextView:
    (UITextView *_Nonnull)input;
+ (NSTextAlignment)effectiveParagraphAlignmentForSelectionInTextView:
    (UITextView *_Nonnull)input;
@end
