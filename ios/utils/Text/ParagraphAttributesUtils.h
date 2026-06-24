#import <UIKit/UIKit.h>
#pragma once

@class EnrichedTextInputView;
@protocol BaseStyleProtocol;

@interface ParagraphAttributesUtils : NSObject
+ (NSArray<id<BaseStyleProtocol>> *)paragraphStylesForInput:
    (EnrichedTextInputView *)input;
+ (NSArray<id<BaseStyleProtocol>> *)paragraphStylesForInput:
                                        (EnrichedTextInputView *)input
                                                      range:(NSRange)range;
+ (NSArray<id<BaseStyleProtocol>> *)
    paragraphStylesForInput:(EnrichedTextInputView *)input
           attributedString:(NSAttributedString *)string
                   location:(NSUInteger)location;
+ (NSArray<id<BaseStyleProtocol>> *)
    paragraphStylesForInput:(EnrichedTextInputView *)input
           attributedString:(NSAttributedString *)string
                      range:(NSRange)range;
+ (BOOL)handleBackspaceInRange:(NSRange)range
               replacementText:(NSString *)text
                         input:(id)input;
+ (BOOL)handleParagraphStylesMergeOnBackspace:(NSRange)range
                              replacementText:(NSString *)text
                                        input:(id)input;
+ (BOOL)handleResetTypingAttributesOnBackspace:(NSRange)range
                               replacementText:(NSString *)text
                                         input:(id)input;
+ (BOOL)isParagraphEmpty:(NSRange)range inString:(NSString *)string;

@end
