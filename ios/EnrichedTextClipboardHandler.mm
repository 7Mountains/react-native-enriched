#import "EnrichedTextClipboardHandler.h"
#import "EnrichedTextInputView.h"
#import "ParagraphsUtils.h"
#import "Strings.h"
#import "TextInsertionUtils.h"
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

  NSString *plain = [[storage.string substringWithRange:range]
      stringByReplacingOccurrencesOfString:ZWS
                                withString:@""];

  NSString *html = [_input->parser parseToHtmlFromRange:range];

  NSMutableAttributedString *attr =
      [[storage attributedSubstringFromRange:range] mutableCopy];

  [attr.mutableString replaceOccurrencesOfString:ZWS
                                      withString:@""
                                         options:0
                                           range:NSMakeRange(0, attr.length)];

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

  if (selectedRange.length == current.length) {
    [current setAttributedString:inserted];
    textView.selectedRange = NSMakeRange(inserted.length, 0);
    return;
  }

  if (selectedRange.length > 0) {

    NSUInteger insertionLocation = selectedRange.location;

    [current beginEditing];
    [current deleteCharactersInRange:selectedRange];
    [current endEditing];

    NSRange collapsedRange = NSMakeRange(insertionLocation, 0);

    [self handleInsertion:current
                  iserted:inserted
            selectedRange:collapsedRange];

    return;
  }

  [self handleInsertion:current iserted:inserted selectedRange:selectedRange];
}

- (NSArray<id<BaseStyleProtocol>> *)paragraphStylesForFirstParagraphInString:
    (NSAttributedString *)string {

  if (string.length == 0)
    return @[];

  NSRange firstParagraphRange =
      [string.string paragraphRangeForRange:NSMakeRange(0, 0)];

  return [self
      findParagraphStylesInAttributedStringAtLocation:string
                                             location:(int)firstParagraphRange
                                                          .location];
}

- (NSArray<id<BaseStyleProtocol>> *)
    findParagraphStylesInAttributedStringAtLocation:
        (NSAttributedString *)attributedString
                                           location:(int)location {

  if (!attributedString || attributedString.length == 0) {
    return @[];
  }

  NSArray<id<BaseStyleProtocol>> *paragraphStyles =
      [_input->stylesDict.allValues
          filteredArrayUsingPredicate:[NSPredicate
                                          predicateWithBlock:^BOOL(
                                              id<BaseStyleProtocol> obj,
                                              NSDictionary *_) {
                                            return [obj.class isParagraphStyle];
                                          }]];

  NSRange paragraphRange =
      [attributedString.string paragraphRangeForRange:NSMakeRange(location, 0)];

  if (paragraphRange.length == 0) {
    return @[];
  }

  NSMutableArray *result = [NSMutableArray array];

  for (id<BaseStyleProtocol> style in paragraphStyles) {

    NSAttributedStringKey key = [style.class attributeKey];

    id attributes = [attributedString attribute:key
                                        atIndex:paragraphRange.location
                          longestEffectiveRange:nil
                                        inRange:paragraphRange];

    if ([style styleCondition:attributes range:paragraphRange]) {
      [result addObject:style];
    }
  }

  return result.copy;
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
      return [_input->parser attributedFromHtml:html];
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

  NSArray *paragraphStyles = [_input->stylesDict.allValues
      filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(
                                                   id<BaseStyleProtocol> obj,
                                                   NSDictionary *_) {
        return [obj.class isParagraphStyle];
      }]];

  for (id<BaseStyleProtocol> style in paragraphStyles) {
    [style removeAttributesFromAttributedString:mutableInserted
                                          range:firstParagraphRange];
  }

  for (id<BaseStyleProtocol> style in targetStyles) {
    [style addAttributesInAttributedString:mutableInserted
                                     range:firstParagraphRange
                                attributes:nil];
  }

  return mutableInserted;
}

- (void)handleInsertion:(NSMutableAttributedString *)current
                iserted:(NSAttributedString *)inserted
          selectedRange:(NSRange)selectedRange {
  NSUInteger start = selectedRange.location;

  BOOL targetIsReadOnly = [ParagraphsUtils isReadOnlyParagraphAtLocation:current
                                                                location:start];
  BOOL insertedIsReadOnly =
      [ParagraphsUtils isReadOnlyParagraphAtLocation:inserted location:0];

  NSDictionary *defaultTypingAttributes = _input->defaultTypingAttributes;
  NSAttributedString *attributedNewLine =
      [[NSAttributedString alloc] initWithString:NewLine
                                      attributes:defaultTypingAttributes];

  NSRange targetParagraphRange =
      [current.string paragraphRangeForRange:NSMakeRange(start, 0)];

  if (targetParagraphRange.length == 0) {
    [current insertAttributedString:inserted
                            atIndex:targetParagraphRange.location];
    _input->textView.selectedRange =
        NSMakeRange(current.length + inserted.length, 0);
    return;
  }

  if ((targetIsReadOnly || insertedIsReadOnly) && selectedRange.length == 0) {
    NSInteger paragraphEnd =
        targetParagraphRange.location + targetParagraphRange.length;
    [current beginEditing];
    [current insertAttributedString:attributedNewLine atIndex:paragraphEnd];
    [current insertAttributedString:inserted atIndex:paragraphEnd + 1];
    [current endEditing];
    _input->textView.selectedRange =
        NSMakeRange(paragraphEnd + inserted.length + 1, 0);
    return;
  }

  NSArray<id<BaseStyleProtocol>> *targetParagraphStyles = [self
      findParagraphStylesInAttributedStringAtLocation:current
                                             location:(int)targetParagraphRange
                                                          .location];

  NSAttributedString *normalizedInsertString =
      [self normalizedInsertedString:inserted
               targetParagraphStyles:targetParagraphStyles];

  [current beginEditing];
  [current insertAttributedString:normalizedInsertString
                          atIndex:selectedRange.location];
  [current endEditing];
  _input->textView.selectedRange = NSMakeRange(start + inserted.length, 0);
}

@end
