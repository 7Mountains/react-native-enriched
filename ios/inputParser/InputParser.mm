#import "InputParser.h"
#import "ColorExtension.h"
#import "EnrichedAttributedStringHTMLSerializer.h"
#import "EnrichedHTMLToAttributedStringParser.h"
#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"

@implementation InputParser {
  EnrichedTextInputView *_input;
  EnrichedAttributedStringHTMLSerializer *_attributedStringHTMLSerializer;
}

- (instancetype)initWithInput:(id)input {
  self = [super init];
  if (!self)
    return nil;

  _input = (EnrichedTextInputView *)input;
  _attributedStringHTMLSerializer =
      [[EnrichedAttributedStringHTMLSerializer alloc]
          initWithStyles:_input->stylesDict];

  return self;
}

#pragma mark - HTML → attributed

- (NSMutableAttributedString *)attributedFromHtml:(NSString *)html {

  EnrichedHTMLToAttributedStringParser *parser =
      [[EnrichedHTMLToAttributedStringParser alloc]
             initWithStyles:_input->stylesDict
          defaultAttributes:_input->defaultTypingAttributes];

  return [parser parseToAttributedString:html];
}

#pragma mark - Public API
- (NSString *)parseToHtmlFromRange:(NSRange)range {
  NSAttributedString *sub =
      [_input->textView.textStorage attributedSubstringFromRange:range];

  return [_attributedStringHTMLSerializer buildHtmlFromAttributedString:sub
                                                                pretify:NO];
}

- (void)parseToHtmlFromRangeAsync:(NSRange)range
                       completion:(void (^)(NSString *html))completion {
  NSAttributedString *snapshot =
      [_input->textView.textStorage attributedSubstringFromRange:range];

  NSAttributedString *safeCopy = [snapshot copy];

  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    NSString *html = [self->_attributedStringHTMLSerializer
        buildHtmlFromAttributedString:safeCopy
                              pretify:NO];

    if (completion) {
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(html);
      });
    }
  });
}

- (void)replaceWholeFromHtml:(NSString *)html
    notifyAnyTextMayHaveBeenModified:(BOOL)notify {
  NSMutableAttributedString *inserted = [self attributedFromHtml:html];

  NSTextStorage *storage = _input->textView.textStorage;

  [storage beginEditing];
  [storage setAttributedString:inserted];
  [storage endEditing];

  if (notify) {
    [_input anyTextMayHaveBeenModified];
  }
}

- (void)replaceFromHtml:(NSString *)html range:(NSRange)range {
  NSMutableAttributedString *inserted = [self attributedFromHtml:html];

  NSTextStorage *storage = _input->textView.textStorage;

  if (range.location > storage.length)
    range.location = storage.length;
  if (NSMaxRange(range) > storage.length)
    range.length = storage.length - range.location;

  [storage beginEditing];
  [storage replaceCharactersInRange:range withAttributedString:inserted];
  [storage endEditing];

  _input->textView.typingAttributes = _input->defaultTypingAttributes;

  [_input anyTextMayHaveBeenModified];
}

- (void)insertFromHtml:(NSString *)html location:(NSInteger)location {
  NSMutableAttributedString *attributedString = [self attributedFromHtml:html];

  NSTextStorage *storage = _input->textView.textStorage;

  if (location > storage.length)
    location = storage.length;

  [storage beginEditing];
  [storage insertAttributedString:attributedString atIndex:location];
  [storage endEditing];

  _input->textView.selectedRange =
      NSMakeRange(location + attributedString.length, 0);
  _input->textView.typingAttributes = _input->defaultTypingAttributes;

  [_input anyTextMayHaveBeenModified];
}

@end
