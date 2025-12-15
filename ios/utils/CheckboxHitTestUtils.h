#import <UIKit/UIKit.h>

@class EnrichedTextInputView;

@interface CheckboxHitTestUtils : NSObject

+ (CGRect)checkboxRectAtGlyphIndex:(NSUInteger)glyphIndex
                           inInput:(EnrichedTextInputView *)input;

+ (NSInteger)hitTestCheckboxAtPoint:(CGPoint)pt
                            inInput:(EnrichedTextInputView *)input;

@end
