#import "EnrichedTextDirection.h"
#import "StyleHeaders.h"

// Strongly right to left, or the marks that make it so: laid out from the
// right of the container
static BOOL IsRightToLeftCharacter(UniChar c) {
  return (c >= 0x0590 && c <= 0x08FF) || (c >= 0xFB1D && c <= 0xFDFF) ||
         (c >= 0xFE70 && c <= 0xFEFF) || c == 0x200F || c == 0x202B ||
         c == 0x202E || c == 0x2067 ||
         // The surrogates of the right to left scripts past the BMP
         (c >= 0xD802 && c <= 0xD803) || (c >= 0xD83A && c <= 0xD83B);
}

BOOL EnrichedIsTextLaidOutAtAnyWidth(NSAttributedString *text) {
  __block BOOL isLeftAligned = YES;
  [text
      enumerateAttribute:NSParagraphStyleAttributeName
                 inRange:NSMakeRange(0, text.length)
                 options:0
              usingBlock:^(id value, NSRange range, BOOL *stop) {
                NSParagraphStyle *style = value;
                if (style == nil) {
                  return;
                }
                BOOL isLeft = style.alignment == NSTextAlignmentNatural ||
                              style.alignment == NSTextAlignmentLeft;
                BOOL isLeftToRight =
                    style.baseWritingDirection == NSWritingDirectionNatural ||
                    style.baseWritingDirection == NSWritingDirectionLeftToRight;
                // Its background is as wide as the container
                BOOL isCodeBlock =
                    [CodeBlockStyle isCodeBlockParagraphStyle:style];
                if (!isLeft || !isLeftToRight || isCodeBlock) {
                  isLeftAligned = NO;
                  *stop = YES;
                }
              }];
  if (!isLeftAligned) {
    return NO;
  }

  CFStringRef string = (__bridge CFStringRef)text.string;
  CFIndex length = CFStringGetLength(string);
  CFStringInlineBuffer buffer;
  CFStringInitInlineBuffer(string, &buffer, CFRangeMake(0, length));
  for (CFIndex i = 0; i < length; i++) {
    if (IsRightToLeftCharacter(
            CFStringGetCharacterFromInlineBuffer(&buffer, i))) {
      return NO;
    }
  }
  return YES;
}
