#pragma once
#import <UIKit/UIKit.h>

@interface ParagraphsUtils : NSObject
+ (NSArray *)getSeparateParagraphsRangesIn:(UITextView *)textView
                                     range:(NSRange)range;
+ (NSArray<NSValue *> *)getSeparateParagraphsRangesInAttributedString:
                            (NSAttributedString *)attributedString
                                                                range:(NSRange)
                                                                          range;
+ (NSArray *)getNonNewlineRangesIn:(UITextView *)textView range:(NSRange)range;
+ (BOOL)isReadOnlyParagraphAtLocation:(NSAttributedString *)attributedString
                             location:(NSUInteger)location;
+ (NSInteger)paragraphsCountInTextView:(UITextView *)textView;
+ (BOOL)isReplacingNewlineInRange:(NSRange)range
                             text:(NSString *)text
                       inTextView:(UITextView *)textView;
+ (NSInteger)incomingParagraphsCountFromString:(NSString *)text;
@end
