#import <UIKit/UIKit.h>
#pragma once

@class EnrichedTextInputView;
@protocol BaseStyleProtocol;

@interface ZWSAdjustedRange : NSObject
@property(nonatomic, assign, readonly) NSRange range;
@property(nonatomic, assign, readonly) NSInteger offsetDelta;
- (instancetype)initWithRange:(NSRange)range offsetDelta:(NSInteger)offsetDelta;
@end

@interface ZeroWidthSpaceUtils : NSObject
+ (void)handleZeroWidthSpacesInInput:(id)input;
+ (NSString *)stringByRemovingZWS:(NSString *)string;
+ (void)removeZWSFromAttributedString:(NSMutableAttributedString *)string;
+ (ZWSAdjustedRange *)rangeByEnsuringEmptyParagraphHasZWS:(NSRange)range
                                                    input:(id)input;
+ (BOOL)handleBackspaceInRange:(NSRange)range
               replacementText:(NSString *)text
                         input:(id)input;
+ (NSUInteger)actualIndexFromVisibleIndex:(NSInteger)visibleIndex
                                     text:(NSString *)text;
+ (NSArray<id<BaseStyleProtocol>> *)ZWSStylesForInput:
    (EnrichedTextInputView *)input;
@end
