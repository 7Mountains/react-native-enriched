#import "InputParser.h"
#import "ColorExtension.h"
#import "EnrichedAttributedStringHTMLSerializer.h"
#import "EnrichedHTMLToAttributedStringParser.h"
#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"

@implementation InputParser {
}

#pragma mark - HTML → attributed

- (NSMutableAttributedString *)
    attributedFromHtml:(NSString *)html
                styles:(NSDictionary<NSNumber *, id> *_Nonnull)styles
     defaultAttributes:(NSDictionary *_Nonnull)defaultAttributes {

  EnrichedHTMLToAttributedStringParser *parser =
      [[EnrichedHTMLToAttributedStringParser alloc]
             initWithStyles:styles
          defaultAttributes:defaultAttributes];

  return [parser parseToAttributedString:html];
}

#pragma mark - Public API
- (NSString *)parseToHtml:(NSAttributedString *)attributedString
                   styles:(NSDictionary<NSNumber *, id> *)styles {
  EnrichedAttributedStringHTMLSerializer *attributedStringHTMLSerializer =
      [[EnrichedAttributedStringHTMLSerializer alloc] initWithStyles:styles];

  return [attributedStringHTMLSerializer
      buildHtmlFromAttributedString:attributedString
                           prettify:NO];
}

- (void)parseToHTMLAsync:(NSAttributedString *)attributedString
                  styles:(NSDictionary<NSNumber *, id> *)styles
                prettify:(BOOL)prettify
              completion:(void (^_Nonnull)(NSString *_Nullable,
                                           NSError *_Nullable))completion {
  EnrichedAttributedStringHTMLSerializer *attributedStringHTMLSerializer =
      [[EnrichedAttributedStringHTMLSerializer alloc] initWithStyles:styles];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                 ^{
                   NSString *html = [attributedStringHTMLSerializer
                       buildHtmlFromAttributedString:attributedString
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
