#import <UIKit/UIKit.h>
@class EnrichedTextInputView;

@interface ContentHitTestUtils : NSObject

+ (CGRect)contentRectAtGlyphIndex:(NSUInteger)glyphIndex
                          inInput:(EnrichedTextInputView *)input;

+ (NSInteger)hitTestContentAtPoint:(CGPoint)pt
                           inInput:(EnrichedTextInputView *)input;

@end
