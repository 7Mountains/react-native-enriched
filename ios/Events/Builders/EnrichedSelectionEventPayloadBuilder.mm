#import "EnrichedSelectionEventPayloadBuilder.h"
#import "StringExtension.h"

using namespace facebook::react;

@implementation EnrichedSelectionEventPayloadBuilder

+ (const EnrichedTextInputViewEventEmitter::OnChangeSelection)buildFromTextView:
    (UITextView *)textView {
  NSRange range = textView.selectedRange;

  NSString *string = textView.textStorage.string;

  NSString *selectedText = [string substringWithRange:range];
  NSRange paragraphRange = [string paragraphRangeForRange:range];

  return {.start = (int)range.location,
          .end = (int)(range.location + range.length),
          .text = [selectedText toCppString],
          .paragraphStart = (int)paragraphRange.location,
          .paragraphEnd =
              (int)(paragraphRange.location + paragraphRange.length)};
}

@end
