#pragma once
#import "Foundation/Foundation.h"

@class EnrichedTextInputView;

@interface EnrichedTextClipboardHandler : NSObject

- (instancetype)initWithInput:(EnrichedTextInputView *)input;
- (void)copy;
- (void)paste;
- (void)cut;
- (void)handleInsertion:(NSMutableAttributedString *)current
                iserted:(NSAttributedString *)inserted
          selectedRange:(NSRange)selectedRange;

@end
