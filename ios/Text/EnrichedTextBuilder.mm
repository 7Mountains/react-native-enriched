#import "EnrichedTextBuilder.h"
#import "EnrichedPreparedText.h"
#import "EnrichedTextConfigBuilder.h"
#import "EnrichedTextParseHost.h"
#import "EnrichedTypingAttributesBuilder.h"
#import "InputConfig.h"
#import "InputParser.h"
#import "StringExtension.h"
#include <react/renderer/core/PropsParserContext.h>
#include <react/renderer/core/RawValue.h>
#include <react/utils/ContextContainer.h>

using namespace facebook::react;

@implementation EnrichedTextBuilder

static const Float kDefaultFontSize = 14;

// The props of the input the config and the typing attributes are built from
static void fillInputProps(EnrichedTextInputViewProps &inputProps,
                           const EnrichedTextViewProps &props,
                           CGFloat fontSizeMultiplier) {
  if (props.htmlStyle.isObject()) {
    ContextContainer contextContainer;
    PropsParserContext context{-1, contextContainer};
    fromRawValue(context, RawValue(props.htmlStyle), inputProps.htmlStyle);
  }

  Float scale = props.allowFontScaling ? fontSizeMultiplier : 1;

  auto &htmlStyle = inputProps.htmlStyle;
  for (Float *headingFontSize :
       {&htmlStyle.h1.fontSize, &htmlStyle.h2.fontSize, &htmlStyle.h3.fontSize,
        &htmlStyle.h4.fontSize, &htmlStyle.h5.fontSize,
        &htmlStyle.h6.fontSize}) {
    *headingFontSize *= scale;
  }

  inputProps.color = props.color;
  inputProps.fontSize =
      (props.fontSize > 0 ? props.fontSize : kDefaultFontSize) * scale;
  inputProps.lineHeight = props.lineHeight * scale;
  inputProps.fontFamily = props.fontFamily;
  inputProps.fontWeight = props.fontWeight;
  inputProps.fontStyle = props.fontStyle;
}

+ (EnrichedPreparedText *)preparedTextWithProps:
                              (const EnrichedTextViewProps &)props
                             fontSizeMultiplier:(CGFloat)fontSizeMultiplier {
  static const EnrichedTextInputViewProps defaultProps{};
  EnrichedTextInputViewProps inputProps;
  fillInputProps(inputProps, props, fontSizeMultiplier);

  // As the input on its first mount: the props differing from the defaults
  InputConfig *config =
      [EnrichedTextConfigBuilder makeConfigFromProps:inputProps
                                        oldViewProps:defaultProps
                                      previousConfig:nil]
          ?: [[InputConfig alloc] init];

  NSDictionary<NSAttributedStringKey, id> *attributes =
      [EnrichedTypingAttributesBuilder buildWithConfig:config props:inputProps];

  NSString *source = [NSString fromCppString:props.text] ?: @"";
  NSMutableAttributedString *text = nil;
  InputParser *parser = [[InputParser alloc] init];

  if ([parser isHtmlString:source]) {
    EnrichedTextParseHost *host =
        [[EnrichedTextParseHost alloc] initWithConfig:config
                              defaultTypingAttributes:attributes];
    @try {
      text = [parser attributedFromHtml:source
                                 styles:host.stylesDict
                      defaultAttributes:attributes];
    } @catch (NSException *exception) {
      NSLog(@"[EnrichedText] Error parsing HTML: %@", exception.reason);
    }
  }

  if (text == nil) {
    text = [[NSMutableAttributedString alloc] initWithString:source
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

+ (CGSize)sizeOfText:(NSAttributedString *)text
      constrainedToWidth:(CGFloat)width
    maximumNumberOfLines:(NSInteger)maximumNumberOfLines
           lineBreakMode:(NSLineBreakMode)lineBreakMode {
  CGFloat containerWidth = isfinite(width) ? width : CGFLOAT_MAX;

  NSTextStorage *textStorage =
      [[NSTextStorage alloc] initWithAttributedString:text];
  NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
  NSTextContainer *textContainer = [[NSTextContainer alloc]
      initWithSize:CGSizeMake(containerWidth, CGFLOAT_MAX)];

  [self configureTextContainer:textContainer
          maximumNumberOfLines:maximumNumberOfLines
                 lineBreakMode:lineBreakMode];

  [layoutManager addTextContainer:textContainer];
  [textStorage addLayoutManager:layoutManager];
  [layoutManager ensureLayoutForTextContainer:textContainer];

  CGRect usedRect = [layoutManager usedRectForTextContainer:textContainer];

  // The widest line, as React Native's <Text>: a short text doesn't take the
  // whole width
  return CGSizeMake(MIN(ceil(usedRect.size.width), containerWidth),
                    ceil(usedRect.size.height));
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
