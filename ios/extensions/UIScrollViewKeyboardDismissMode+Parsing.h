#pragma once
#import <UIKit/UIKit.h>

@interface UIScrollView (KeyboardDismissModeParsing)

+ (UIScrollViewKeyboardDismissMode)fromString:(NSString *)value;

@end