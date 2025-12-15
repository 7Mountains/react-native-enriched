#import <UIKit/UIKit.h>
@class EnrichedTextInputView;

@interface DividerHitTestUtils : NSObject

+ (CGRect)dividerRectAtGlyphIndex:(NSUInteger)glyphIndex
                          inInput:(EnrichedTextInputView *)input;

+ (NSInteger)hitTestDividerAtPoint:(CGPoint)pt
                           inInput:(EnrichedTextInputView *)input;

@end
