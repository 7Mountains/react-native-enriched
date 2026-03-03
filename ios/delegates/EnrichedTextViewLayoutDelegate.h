#pragma once
#import <UIKit/UIKit.h>

@protocol EnrichedTextViewLayoutDelegate <NSObject>

- (void)sizeDidChange:(CGSize)newSize;

@end
