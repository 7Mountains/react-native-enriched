#pragma once
#import "EnrichedTextViewClipboardDelegate.h"
#import "EnrichedTextViewLayoutDelegate.h"
#import <UIkit/UIKit.h>

@interface InputTextView : UITextView
@property(nonatomic, weak) id<EnrichedTextViewClipboardDelegate>
    clipboardDelegate;
@property(nonatomic, weak) id<EnrichedTextViewLayoutDelegate> layoutDelegate;
@property(nonatomic, copy, nullable) NSString *placeholderText;
@property(nonatomic, strong, nullable) UIColor *placeholderColor;
- (void)updatePlaceholderVisibility;
@end
