#import "EnrichedKeyPressEventPayloadBuilder.h"
#import "StringExtension.h"

using namespace facebook::react;

@implementation EnrichedKeyPressEventPayloadBuilder

+ (const EnrichedTextInputViewEventEmitter::OnInputKeyPress)
    buildFromTextView:(UITextView *)textView
                  key:(NSString *)key {
  NSRange range = textView.selectedRange;

  NSString *text = [textView.textStorage.string substringWithRange:range];

  return {.key = [key toCppString],
          .selection = {
              .start = (int)range.location,
              .end = (int)(range.location + range.length),
          }};
}

@end
