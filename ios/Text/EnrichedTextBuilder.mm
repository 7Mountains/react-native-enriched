#import "EnrichedTextBuilder.h"
#import "EnrichedHTMLToAttributedStringParser.h"
#import "EnrichedPreparedText.h"
#import "EnrichedTextParseHost.h"
#import "EnrichedTextStyleCache.h"
#import "EnrichedUTF8.h"
#import "InputConfig.h"

#include <cstring>
#include <string>

using namespace facebook::react;

@implementation EnrichedTextBuilder

// The html of the text, as long as `NSString` reads it (see
// `EnrichedValidUTF8Length`)
static bool htmlLength(const std::string &text, size_t *length) {
  return strncmp(text.c_str(), "<html>", 6) == 0 &&
         EnrichedValidUTF8Length(text.c_str(), length);
}

+ (EnrichedPreparedText *)preparedTextWithProps:
                              (const EnrichedTextViewProps &)props
                             fontSizeMultiplier:(CGFloat)fontSizeMultiplier {
  EnrichedTextStyle style =
      EnrichedTextStyleForProps(props, fontSizeMultiplier);
  InputConfig *config = style.config;
  NSDictionary<NSAttributedStringKey, id> *attributes = style.attributes;

  const std::string &source = props.text;
  NSMutableAttributedString *text = nil;
  size_t length = 0;

  // Parsed from the bytes of the props: not decoded to a string and encoded
  // back
  if (htmlLength(source, &length)) {
    EnrichedTextParseHost *host =
        [EnrichedTextParseHost hostForCurrentThreadWithConfig:config
                                      defaultTypingAttributes:attributes];
    @try {
      EnrichedHTMLToAttributedStringParser *parser =
          [[EnrichedHTMLToAttributedStringParser alloc]
                 initWithStyles:host.stylesDict
              defaultAttributes:attributes];
      text = [parser parseToAttributedStringFromUTF8:source.c_str()
                                              length:length];
    } @catch (NSException *exception) {
      NSLog(@"[EnrichedText] Error parsing HTML: %@", exception.reason);
    }
  }

  if (text == nil) {
    NSString *string = [NSString stringWithUTF8String:source.c_str()] ?: @"";
    text = [[NSMutableAttributedString alloc] initWithString:string
                                                  attributes:attributes];
  }

  // The last paragraph doesn't end with an empty line
  while (text.length > 0 &&
         [text.string characterAtIndex:text.length - 1] == '\n') {
    [text deleteCharactersInRange:NSMakeRange(text.length - 1, 1)];
  }

  // Immutable: the view and the measurement read it on different threads
  return [[EnrichedPreparedText alloc] initWithText:[text copy] config:config];
}

+ (void)configureTextContainer:(NSTextContainer *)textContainer
          maximumNumberOfLines:(NSInteger)maximumNumberOfLines
                 lineBreakMode:(NSLineBreakMode)lineBreakMode {
  textContainer.lineFragmentPadding = 0;
  textContainer.maximumNumberOfLines = MAX(maximumNumberOfLines, 0);
  textContainer.lineBreakMode =
      maximumNumberOfLines > 0 ? lineBreakMode : NSLineBreakByWordWrapping;
}

@end

NSLineBreakMode
EnrichedNSLineBreakModeFromEllipsizeMode(const std::string &ellipsizeMode) {
  if (ellipsizeMode == "head") {
    return NSLineBreakByTruncatingHead;
  }
  if (ellipsizeMode == "middle") {
    return NSLineBreakByTruncatingMiddle;
  }
  if (ellipsizeMode == "clip") {
    return NSLineBreakByClipping;
  }
  return NSLineBreakByTruncatingTail;
}
