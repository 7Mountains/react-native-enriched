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
                                                               prettify:NO];
}

- (void)parseToHTMLAsync:(BOOL)prettify
              completion:(void (^_Nonnull)(NSString *_Nullable,
                                           NSError *_Nullable))completion {
  NSAttributedString *snapshot = [[NSAttributedString alloc]
      initWithAttributedString:self->_input->textView.textStorage];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                 ^{
                   NSString *html = [self->_attributedStringHTMLSerializer
                       buildHtmlFromAttributedString:snapshot
                                            prettify:prettify];

                   dispatch_async(dispatch_get_main_queue(), ^{
                     if (completion) {
                       completion(html, nil);
                     }
                   });
                 });
}

- (BOOL)isHtmlString:(NSString *)string {
  return string != nil && [string hasPrefix:@"<html>"];
}

@end
