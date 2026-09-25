#import "EnrichedParagraphStyle.h"
#import "EnrichedTextInputView.h"
#import "FontExtension.h"
#import "OccurenceUtils.h"
#import "ParagraphsUtils.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"

static EnrichedParagraphStyle *mutableEnrichedParagraphStyle(id value) {
  if ([value isKindOfClass:[EnrichedParagraphStyle class]]) {
    return [value mutableCopy];
  }

  EnrichedParagraphStyle *style = [EnrichedParagraphStyle new];
  if ([value isKindOfClass:[NSParagraphStyle class]]) {
    [style setParagraphStyle:value];
  }
  return style;
}

@implementation HeadingStyleBase {
  UIFont *_cachedFont;
}

// mock values since H1/2/3/4/5/6Style classes anyway are used
+ (StyleType)getStyleType {
  return None;
}
- (CGFloat)getHeadingFontSize {
  return 0;
}
- (BOOL)isHeadingBold {
  return false;
}

+ (const char *)subTagName {
  return nil;
}

+ (NSAttributedStringKey)attributeKey {
  return NSParagraphStyleAttributeName;
}

+ (BOOL)isSelfClosing {
  return NO;
}

+ (EnrichedHeadingLevel)headingLevel {
  return EnrichedHeadingNone;
}

- (EnrichedTextInputView *)typedInput {
  return (EnrichedTextInputView *)input;
}

- (instancetype)initWithInput:(id)input {
  self = [super init];
  self->input = input;
  return self;
}

// the range will already be the full paragraph/s range
// but if the paragraph is empty it still is of length 0
- (void)applyStyle:(NSRange)range {
  BOOL isStylePresent = [self detectStyle:range];
  if (range.length >= 1) {
    isStylePresent ? [self removeAttributes:range] : [self addAttributes:range];
  } else {
    isStylePresent ? [self removeTypingAttributes] : [self addTypingAttributes];
  }
}

// the range will already be the proper full paragraph/s range
- (void)addAttributes:(NSRange)range {
  [self addAttributes:range withTypingAttributes:YES];
}

- (UIFont *)getHeadingFont:(UIFont *)font {
  if (_cachedFont) {
    return _cachedFont;
  }

  UIFont *newFont = [font copyWithFontSize:[self getHeadingFontSize]];
  if ([self isHeadingBold]) {
    [newFont setBold];
  }

  _cachedFont = newFont;

  return _cachedFont;
}

- (void)addAttributes:(NSRange)range
    withTypingAttributes:(BOOL)withTypingAttributes {

  EnrichedTextInputView *input = [self typedInput];
  NSMutableAttributedString *attributedString = input->textView.textStorage;

  [attributedString beginEditing];

  CGFloat fontSize = [self getHeadingFontSize];
  BOOL isHeadingBold = [self isHeadingBold];

  NSArray *paragraphs =
      [ParagraphsUtils getSeparateParagraphsRangesIn:input->textView
                                               range:range];

  for (NSValue *value in paragraphs) {
    NSMutableDictionary *newAttrs = [NSMutableDictionary new];
    NSRange paragraphRange = value.rangeValue;

    [attributedString
        enumerateAttributesInRange:paragraphRange
                           options:0
                        usingBlock:^(
                            NSDictionary<NSAttributedStringKey, id> *attrs,
                            NSRange subRange, BOOL *stop) {
                          EnrichedParagraphStyle *baseParagraphStyle =
                              mutableEnrichedParagraphStyle(
                                  attrs[NSParagraphStyleAttributeName]);
                          baseParagraphStyle.headingLevel =
                              [self.class headingLevel];
                          newAttrs[NSParagraphStyleAttributeName] =
                              baseParagraphStyle;

                          UIFont *font = attrs[NSFontAttributeName];
                          if (font != nil) {
                            UIFont *newFont = [font copyWithFontSize:fontSize];
                            if (isHeadingBold) {
                              newFont = [newFont setBold];
                            }
                            newAttrs[NSFontAttributeName] = newFont;
                          }
                          [attributedString addAttributes:newAttrs
                                                    range:subRange];
                        }];
  }

  [attributedString endEditing];

  if (withTypingAttributes) {
    [self addTypingAttributes];
  }
}

- (void)addAttributesInAttributedString:
            (NSMutableAttributedString *)attributedString
                                  range:(NSRange)range
                             attributes:(NSDictionary<NSString *, NSString *>
                                             *_Nullable)attributes {
  EnrichedTextInputView *input = [self typedInput];
  UIFont *newFont =
      [self getHeadingFont:input->defaultTypingAttributes[NSFontAttributeName]];
  EnrichedParagraphStyle *paragraphStyle = mutableEnrichedParagraphStyle(
      input->defaultTypingAttributes[NSParagraphStyleAttributeName]);
  paragraphStyle.headingLevel = [self.class headingLevel];
  NSDictionary *newAttributes = @{
    NSParagraphStyleAttributeName : paragraphStyle,
    NSFontAttributeName : newFont
  };
  [attributedString addAttributes:newAttributes range:range];
}

// will always be called on empty paragraphs so only typing attributes can be
// changed
- (void)addTypingAttributes {
  UITextView *textView = [self typedInput]->textView;
  NSMutableDictionary *newTypingAttributes =
      textView.typingAttributes.mutableCopy;
  UIFont *currentFontAttr = (UIFont *)newTypingAttributes[NSFontAttributeName];
  EnrichedParagraphStyle *paragraphStyle = mutableEnrichedParagraphStyle(
      newTypingAttributes[NSParagraphStyleAttributeName]);
  if (currentFontAttr != nullptr) {
    UIFont *newFont =
        [currentFontAttr copyWithFontSize:[self getHeadingFontSize]];
    if ([self isHeadingBold]) {
      newFont = [newFont setBold];
    }
    newTypingAttributes[NSFontAttributeName] = newFont;
    paragraphStyle.headingLevel = [self.class headingLevel];
    newTypingAttributes[NSParagraphStyleAttributeName] = paragraphStyle;
    textView.typingAttributes = newTypingAttributes;
  }
}

- (void)removeAttributesFromAttributedString:(NSMutableAttributedString *)string
                                       range:(NSRange)range {
  NSArray *paragraphs =
      [ParagraphsUtils getSeparateParagraphsRangesInAttributedString:string
                                                               range:range];
  CGFloat fontSize = [[[self typedInput]->config primaryFontSize] floatValue];
  for (NSValue *value in paragraphs) {
    NSRange paragraphRange = [value rangeValue];
    [string enumerateAttribute:NSParagraphStyleAttributeName
                       inRange:paragraphRange
                       options:0
                    usingBlock:^(id _Nullable value, NSRange range,
                                 BOOL *_Nonnull stop) {
                      EnrichedParagraphStyle *paragraphStyle =
                          mutableEnrichedParagraphStyle(value);
                      paragraphStyle.headingLevel = EnrichedHeadingNone;
                      [string addAttribute:NSParagraphStyleAttributeName
                                     value:paragraphStyle
                                     range:range];
                    }];
    [string enumerateAttribute:NSFontAttributeName
                       inRange:paragraphRange
                       options:0
                    usingBlock:^(id _Nullable value, NSRange range,
                                 BOOL *_Nonnull stop) {
                      UIFont *newFont =
                          [(UIFont *)value copyWithFontSize:fontSize];
                      if ([self isHeadingBold]) {
                        newFont = [newFont removeBold];
                      }
                      [string addAttribute:NSFontAttributeName
                                     value:newFont
                                     range:range];
                    }];
  }
}

- (NSDictionary<NSAttributedStringKey, id> *)typingAttributesByRemovingHeading:
    (NSDictionary<NSAttributedStringKey, id> *)typingAttributes {
  NSMutableDictionary<NSAttributedStringKey, id> *newTypingAttributes =
      typingAttributes.mutableCopy;
  UIFont *currentFont = newTypingAttributes[NSFontAttributeName];

  if (currentFont != nullptr) {
    UIFont *newFont = [currentFont
        copyWithFontSize:[[[self typedInput]->config primaryFontSize]
                             floatValue]];
    if ([self isHeadingBold]) {
      newFont = [newFont removeBold];
    }
    newTypingAttributes[NSFontAttributeName] = newFont;
  }

  EnrichedParagraphStyle *paragraphStyle = mutableEnrichedParagraphStyle(
      newTypingAttributes[NSParagraphStyleAttributeName]);
  paragraphStyle.headingLevel = EnrichedHeadingNone;
  newTypingAttributes[NSParagraphStyleAttributeName] = paragraphStyle;

  return newTypingAttributes.copy;
}

// we need to remove the style from the whole paragraph
- (void)removeAttributes:(NSRange)range {
  EnrichedTextInputView *input = [self typedInput];
  NSTextStorage *textStorage = input->textView.textStorage;

  [textStorage beginEditing];
  [self removeAttributesFromAttributedString:textStorage range:range];
  [textStorage endEditing];

  input->textView.typingAttributes =
      [self typingAttributesByRemovingHeading:input->textView.typingAttributes];
}

- (void)removeTypingAttributes {
  // all the heading still needs to be removed because this function may be
  // called in conflicting styles logic typing attributes already get removed in
  // there as well
  [self removeAttributes:[self typedInput]->textView.selectedRange];
}

- (BOOL)styleCondition:(id _Nullable)value range:(NSRange)range {
  return [value isKindOfClass:[EnrichedParagraphStyle class]] &&
         ((EnrichedParagraphStyle *)value).headingLevel ==
             [self.class headingLevel];
}

- (BOOL)detectStyle:(NSRange)range {
  if (range.length >= 1) {
    return [OccurenceUtils detect:NSParagraphStyleAttributeName
                        withInput:input
                          inRange:range
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value range:range];
                    }];
  } else {
    return [OccurenceUtils detect:NSParagraphStyleAttributeName
                        withInput:[self typedInput]
                          atIndex:range.location
                    checkPrevious:YES
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value range:range];
                    }];
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:NSParagraphStyleAttributeName
                   withInput:[self typedInput]
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value range:range];
               }];
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:NSParagraphStyleAttributeName
                   withInput:[self typedInput]
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value range:range];
               }];
}

// used to make sure headings dont persist after a newline is placed
- (BOOL)handleNewlinesInRange:(NSRange)range replacementText:(NSString *)text {
  EnrichedTextInputView *input = [self typedInput];
  NSRange selectedRange = input->textView.selectedRange;
  // in a heading and a new text ends with a newline
  if ([self detectStyle:selectedRange] && text.length > 0 &&
      [[NSCharacterSet newlineCharacterSet]
          characterIsMember:[text characterAtIndex:text.length - 1]]) {
    NSDictionary<NSAttributedStringKey, id> *newParagraphTypingAttributes =
        [self
            typingAttributesByRemovingHeading:input->textView.typingAttributes];

    // do the replacement manually
    [TextInsertionUtils replaceText:text
                                 at:range
               additionalAttributes:nullptr
                              input:input
                      withSelection:YES];

    // Newline characters start the non-heading paragraph, but keep the active
    // inline styles and the input's configured default attributes.
    [input->textView.textStorage beginEditing];
    for (NSUInteger index = 0; index < text.length; index++) {
      if ([[NSCharacterSet newlineCharacterSet]
              characterIsMember:[text characterAtIndex:index]]) {
        [input->textView.textStorage
            addAttributes:newParagraphTypingAttributes
                    range:NSMakeRange(range.location + index, 1)];
      }
    }
    [input->textView.textStorage endEditing];

    input->textView.typingAttributes = newParagraphTypingAttributes;
    return YES;
  }
  return NO;
}

// Backspacing a line after a heading "into" a heading will not result in the
// text not receiving heading font attributes.
// Hence, we fix these attributes then.
- (BOOL)handleBackspaceInRange:(NSRange)range replacementText:(NSString *)text {
  EnrichedTextInputView *input = [self typedInput];
  // Must be a backspace.
  if (text.length != 0) {
    return NO;
  }
  // Backspace must have removed a newline character.
  NSString *removedString =
      [input->textView.textStorage.string substringWithRange:range];
  if ([removedString
          rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]]
          .location == NSNotFound) {
    return NO;
  }

  // Heading style must have been present in a paragraph before the backspaced
  // range.
  NSRange paragraphBeforeBackspaceRange = [input->textView.textStorage.string
      paragraphRangeForRange:NSMakeRange(range.location, 0)];
  if (![self detectStyle:paragraphBeforeBackspaceRange]) {
    return NO;
  }

  // Manually do the replacing.
  [TextInsertionUtils replaceText:text
                               at:range
             additionalAttributes:nullptr
                            input:input
                    withSelection:YES];
  // Reapply attributes at the beginning of the backspaced range (it will cover
  // the whole paragraph properly).
  [self addAttributes:NSMakeRange(range.location, 0) withTypingAttributes:NO];

  return YES;
}

@end
