#import "EnrichedTextClipboardHandler.h"
#import "EnrichedTextInputView.h"
#import "ParagraphAttributesUtils.h"
#import "ParagraphsUtils.h"
#import "Strings.h"
#import "TextInsertionUtils.h"
#import "ZeroWidthSpaceUtils.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@implementation EnrichedTextClipboardHandler {
  __weak EnrichedTextInputView *_input;
}

- (instancetype)initWithInput:(EnrichedTextInputView *)input {
  self = [super init];
  if (self) {
    _input = input;
  }
  return self;
}

- (void)copy {
  NSTextStorage *storage = _input->textView.textStorage;
  NSRange range = _input->textView.selectedRange;
  if (range.length == 0) {
    return;
  }

  NSString *plain = [ZeroWidthSpaceUtils
      stringByRemovingZWS:[storage.string substringWithRange:range]];

  NSAttributedString *substring =
      [_input->textView.textStorage attributedSubstringFromRange:range];

  NSString *html = [_input->parser parseToHtml:substring
                                        styles:_input->stylesDict];

  NSMutableAttributedString *attr =
      [[storage attributedSubstringFromRange:range] mutableCopy];

  [ZeroWidthSpaceUtils removeZWSFromAttributedString:attr];

  NSData *rtf = [attr dataFromRange:NSMakeRange(0, attr.length)
                 documentAttributes:@{
                   NSDocumentTypeDocumentAttribute : NSRTFTextDocumentType
                 }
                              error:nil];

  [UIPasteboard.generalPasteboard
      setItems:@[ @{
        UTTypeUTF8PlainText.identifier : plain ?: @"",
        UTTypeHTML.identifier : html ?: @"",
        UTTypeRTF.identifier : rtf ?: [NSData data]
      } ]];
}

- (void)paste {
  NSAttributedString *inserted =
      [self attributedStringFromPasteboard:UIPasteboard.generalPasteboard];
  if (!inserted || inserted.length == 0)
    return;

  UITextView *textView = _input->textView;
  NSMutableAttributedString *current = textView.textStorage;
  NSRange selectedRange = textView.selectedRange;

  [self handleInsertion:current inserted:inserted selectedRange:selectedRange];
}

- (void)cut {
  [self copy];

  [TextInsertionUtils replaceText:@""
                               at:_input->textView.selectedRange
             additionalAttributes:nil
                            input:_input
                    withSelection:YES];
}

- (NSAttributedString *)attributedStringFromPasteboard:(UIPasteboard *)pb {
  if ([pb.pasteboardTypes containsObject:UTTypeHTML.identifier]) {
    id value = [pb valueForPasteboardType:UTTypeHTML.identifier];
    NSString *html = nil;

    if ([value isKindOfClass:NSData.class]) {
      html = [[NSString alloc] initWithData:value
                                   encoding:NSUTF8StringEncoding];
    } else if ([value isKindOfClass:NSString.class]) {
      html = value;
    }

    if (html.length > 0) {
      return
          [_input->parser attributedFromHtml:html
                                      styles:_input->stylesDict
                           defaultAttributes:_input->defaultTypingAttributes];
    }
  }

  NSArray *types = @[
    UTTypeUTF8PlainText.identifier, UTTypePlainText.identifier,
    UTTypeURL.identifier
  ];

  for (NSString *type in types) {
    if (![pb.pasteboardTypes containsObject:type]) {
      continue;
    }
    NSDictionary *defaultAttributes = _input->defaultTypingAttributes;

    id value = [pb valueForPasteboardType:type];

    if ([value isKindOfClass:NSData.class]) {
      NSString *s = [[NSString alloc] initWithData:value
                                          encoding:NSUTF8StringEncoding];
      return s ? [[NSAttributedString alloc] initWithString:s
                                                 attributes:defaultAttributes]
               : nil;
    }

    if ([value isKindOfClass:NSString.class]) {
      return [[NSAttributedString alloc] initWithString:value
                                             attributes:defaultAttributes];
    }

    if ([value isKindOfClass:NSURL.class]) {
      return [[NSAttributedString alloc] initWithString:[value absoluteString]
                                             attributes:defaultAttributes];
    }
  }

  return nil;
}

- (NSAttributedString *)normalizedInsertedString:(NSAttributedString *)inserted
                           targetParagraphStyles:
                               (NSArray<id<BaseStyleProtocol>> *)targetStyles {

  if (inserted.length == 0) {
    return inserted;
  }

  NSRange firstParagraphRange =
      [inserted.string paragraphRangeForRange:NSMakeRange(0, 0)];

  NSMutableAttributedString *mutableInserted = inserted.mutableCopy;

  NSArray<id<BaseStyleProtocol>> *paragraphStyles =
      [ParagraphAttributesUtils paragraphStylesForInput:_input];

  [mutableInserted beginEditing];

  for (id<BaseStyleProtocol> style in paragraphStyles) {
    [style removeAttributesFromAttributedString:mutableInserted
                                          range:firstParagraphRange];
  }

  for (id<BaseStyleProtocol> style in targetStyles) {
    [style addAttributesInAttributedString:mutableInserted
                                     range:firstParagraphRange
                                attributes:nil];
  }

  [mutableInserted endEditing];

  return mutableInserted;
}

- (BOOL)tryInsertStartingWithReadOnlyParagraph:
            (NSMutableAttributedString *)current
                                      inserted:(NSAttributedString *)inserted
                                 selectedRange:(NSRange)selectedRange
                             attributedNewLine:
                                 (NSAttributedString *)attributedNewLine {
  if (![ParagraphsUtils isReadOnlyParagraphAtLocation:inserted location:0]) {
    return NO;
  }

  NSUInteger start = MIN(selectedRange.location, current.length);

  [current beginEditing];

  if (selectedRange.length > 0) {
    NSRange removalRange =
        NSMakeRange(start, MIN(selectedRange.length, current.length - start));
    [current replaceCharactersInRange:removalRange
                 withAttributedString:[NSAttributedString new]];

    if (current.length == 0) {
      [current insertAttributedString:inserted atIndex:0];
      [current endEditing];

      _input->textView.selectedRange = NSMakeRange(inserted.length, 0);
      return YES;
    }
  }

  NSUInteger insertionLocation = MIN(start, current.length);
  NSRange targetParagraphRange =
      [current.string paragraphRangeForRange:NSMakeRange(insertionLocation, 0)];
  NSUInteger paragraphEnd =
      targetParagraphRange.location + targetParagraphRange.length;

  // `paragraphRangeForRange:` includes the paragraph terminator; insert before
  // it when present.
  NSUInteger insertionIndex = paragraphEnd;
  if (paragraphEnd > 0 &&
      [[NSCharacterSet newlineCharacterSet]
          characterIsMember:[current.string
                                characterAtIndex:paragraphEnd - 1]]) {
    insertionIndex = paragraphEnd - 1;
  }
  NSMutableAttributedString *replacement =
      [[NSMutableAttributedString alloc] init];

  [replacement appendAttributedString:attributedNewLine];
  [replacement appendAttributedString:inserted];

  [current insertAttributedString:replacement atIndex:insertionIndex];
  [current endEditing];

  _input->textView.selectedRange =
      NSMakeRange(insertionIndex + replacement.length, 0);
  return YES;
}

- (void)handleInsertion:(NSMutableAttributedString *)current
               inserted:(NSAttributedString *)inserted
          selectedRange:(NSRange)selectedRange {
  NSUInteger start = selectedRange.location;

  NSDictionary *defaultTypingAttributes = _input->defaultTypingAttributes;
  NSAttributedString *attributedNewLine =
      [[NSAttributedString alloc] initWithString:NewLine
                                      attributes:defaultTypingAttributes];

  NSRange targetParagraphRange =
      [current.string paragraphRangeForRange:NSMakeRange(start, 0)];

  if (targetParagraphRange.length == 0) {
    [current beginEditing];
    [current replaceCharactersInRange:selectedRange
                 withAttributedString:inserted];
    [current endEditing];

    _input->textView.selectedRange = NSMakeRange(start + inserted.length, 0);
    return;
  }

  BOOL targetIsReadOnly = [ParagraphsUtils isReadOnlyParagraphAtLocation:current
                                                                location:start];

  if ([self tryInsertStartingWithReadOnlyParagraph:current
                                          inserted:inserted
                                     selectedRange:selectedRange
                                 attributedNewLine:attributedNewLine]) {
    return;
  }

  if (targetIsReadOnly && selectedRange.length == 0) {
    NSUInteger paragraphEnd =
        targetParagraphRange.location + targetParagraphRange.length;

    NSMutableAttributedString *replacement =
        [[NSMutableAttributedString alloc] init];

    [replacement appendAttributedString:attributedNewLine];
    [replacement appendAttributedString:inserted];

    [current beginEditing];
    [current replaceCharactersInRange:NSMakeRange(paragraphEnd, 0)
                 withAttributedString:replacement];
    [current endEditing];

    _input->textView.selectedRange =
        NSMakeRange(paragraphEnd + replacement.length, 0);
    return;
  }

  NSArray<id<BaseStyleProtocol>> *targetParagraphStyles =
      [ParagraphAttributesUtils
          paragraphStylesForInput:_input
                 attributedString:current
                         location:targetParagraphRange.location];

  NSAttributedString *normalizedInsertString =
      [self normalizedInsertedString:inserted
               targetParagraphStyles:targetParagraphStyles];

  [current beginEditing];
  [current replaceCharactersInRange:selectedRange
               withAttributedString:normalizedInsertString];
  [current endEditing];

  _input->textView.selectedRange =
      NSMakeRange(start + normalizedInsertString.length, 0);
}

@end
