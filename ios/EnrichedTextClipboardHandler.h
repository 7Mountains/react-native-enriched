#pragma once
#import "Foundation/Foundation.h"

@class EnrichedTextInputView;

@interface EnrichedTextClipboardHandler : NSObject

- (instancetype)initWithInput:(EnrichedTextInputView *)input;
- (void)copy;
- (void)pasteWithCapacity:(NSInteger)capacity;
- (void)cut;
- (void)handleInsertion:(NSMutableAttributedString *)current
               inserted:(NSAttributedString *)inserted
          selectedRange:(NSRange)selectedRange;

@end
