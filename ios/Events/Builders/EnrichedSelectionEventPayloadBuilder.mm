#import "EnrichedSelectionEventPayloadBuilder.h"
#import "StringExtension.h"

using namespace facebook::react;

@implementation EnrichedSelectionEventPayloadBuilder

+ (const EnrichedTextInputViewEventEmitter::OnChangeSelection)buildFromTextView:
    (UITextView *)textView {
  NSRange range = textView.selectedRange;

  NSString *text = [textView.textStorage.string substringWithRange:range];

  return {.start = (int)range.location,
          .end = (int)(range.location + range.length),
          .text = [text toCppString]};
}

@end
