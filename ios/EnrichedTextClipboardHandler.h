#import "Foundation/Foundation.h"

@class EnrichedTextInputView;

@interface EnrichedTextClipboardHandler : NSObject

- (instancetype)initWithInput:(EnrichedTextInputView *)input;
- (void)copy;
- (void)paste;
- (void)cut;

@end
