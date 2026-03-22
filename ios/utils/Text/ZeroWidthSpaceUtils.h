#import <UIKit/UIKit.h>
#pragma once

@interface ZeroWidthSpaceUtils : NSObject
+ (void)handleZeroWidthSpacesInInput:(id)input;
+ (BOOL)handleBackspaceInRange:(NSRange)range
               replacementText:(NSString *)text
                         input:(id)input;
+ (NSUInteger)actualIndexFromVisibleIndex:(NSInteger)visibleIndex
                                     text:(NSString *)text;
@end
