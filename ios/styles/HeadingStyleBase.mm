#import "EnrichedParagraphStyle.h"
#import "EnrichedTextInputView.h"
#import "FontExtension.h"
#import "OccurenceUtils.h"
#import "ParagraphsUtils.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"

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
    NSRange paragraphRange = value.rangeValue;

    [attributedString
        enumerateAttributesInRange:paragraphRange
                           options:0
                        usingBlock:^(
                            NSDictionary<NSAttributedStringKey, id> *attrs,
                            NSRange subRange, BOOL *stop) {
                          NSMutableDictionary *newAttrs = [attrs mutableCopy];

                          EnrichedParagraphStyle *baseParagraphStyle =
                              [attrs[NSParagraphStyleAttributeName]
                                  mutableCopy];

                          if (baseParagraphStyle) {
                            baseParagraphStyle.headingLevel =
                                [self.class headingLevel];
                            newAttrs[NSParagraphStyleAttributeName] =
                                baseParagraphStyle;
                          }

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
  EnrichedParagraphStyle *paragraphStyle =
      [input->defaultTypingAttributes[NSParagraphStyleAttributeName]
          mutableCopy];
  paragraphStyle.headingLevel = [self.class headingLevel];
  [attributedString addAttributes:@{
    NSParagraphStyleAttributeName : paragraphStyle,
    NSFontAttributeName : newFont
  }
                            range:range];
}

// will always be called on empty paragraphs so only typing attributes can be
// changed
- (void)addTypingAttributes {
  NSMutableDictionary *newTypingAttributes =
      [[self typedInput]->textView.typingAttributes mutableCopy];
  UIFont *currentFontAttr = (UIFont *)newTypingAttributes[NSFontAttributeName];
  EnrichedParagraphStyle *paragraphStyle =
      [newTypingAttributes[NSParagraphStyleAttributeName] mutableCopy];
  if (currentFontAttr != nullptr && paragraphStyle != nullptr) {
    UIFont *newFont =
        [currentFontAttr copyWithFontSize:[self getHeadingFontSize]];
    if ([self isHeadingBold]) {
      newFont = [newFont setBold];
    }
    newTypingAttributes[NSFontAttributeName] = newFont;
    paragraphStyle.headingLevel = [self.class headingLevel];
    newTypingAttributes[NSParagraphStyleAttributeName] = paragraphStyle;
    [self typedInput]->textView.typingAttributes = newTypingAttributes;
  }
}

// we need to remove the style from the whole paragraph
- (void)removeAttributes:(NSRange)range {
  NSArray *paragraphs =
      [ParagraphsUtils getSeparateParagraphsRangesIn:[self typedInput]->textView
                                               range:range];

  EnrichedTextInputView *input = [self typedInput];

  [input->textView.textStorage beginEditing];
  for (NSValue *value in paragraphs) {
    NSRange paragraphRange = [value rangeValue];
    [input->textView.textStorage
        enumerateAttribute:NSParagraphStyleAttributeName
                   inRange:paragraphRange
                   options:0
                usingBlock:^(id _Nullable value, NSRange range,
                             BOOL *_Nonnull stop) {
                  EnrichedParagraphStyle *paragraphStyle =
                      [(EnrichedParagraphStyle *)value mutableCopy];
                  paragraphStyle.headingLevel = EnrichedHeadingNone;
                  [input->textView.textStorage
                      addAttribute:NSParagraphStyleAttributeName
                             value:paragraphStyle
                             range:range];
                }];
    [input->textView.textStorage
        enumerateAttribute:NSFontAttributeName
                   inRange:paragraphRange
                   options:0
                usingBlock:^(id _Nullable value, NSRange range,
                             BOOL *_Nonnull stop) {
                  UIFont *newFont = [(UIFont *)value
                      copyWithFontSize:[[[self typedInput]->config
                                               primaryFontSize] floatValue]];
                  if ([self isHeadingBold]) {
                    newFont = [newFont removeBold];
                  }
                  [input->textView.textStorage addAttribute:NSFontAttributeName
                                                      value:newFont
                                                      range:range];
                }];
  }
  [[self typedInput]->textView.textStorage endEditing];

  // typing attributes still need to be removed
  UIFont *currentFontAttr =
      (UIFont *)[self typedInput]
          ->textView.typingAttributes[NSFontAttributeName];
  if (currentFontAttr != nullptr) {
    NSMutableDictionary *newTypingAttrs =
        [[self typedInput]->textView.typingAttributes mutableCopy];
    UIFont *newFont = [currentFontAttr
        copyWithFontSize:[[[self typedInput]->config primaryFontSize]
                             floatValue]];
    if ([self isHeadingBold]) {
      newFont = [newFont removeBold];
    }
    newTypingAttrs[NSFontAttributeName] = newFont;

    EnrichedParagraphStyle *paragraphStyle =
        [newTypingAttrs[NSParagraphStyleAttributeName] mutableCopy];
    paragraphStyle.headingLevel = EnrichedHeadingNone;
    newTypingAttrs[NSParagraphStyleAttributeName] = paragraphStyle;

    [self typedInput]->textView.typingAttributes = newTypingAttrs;
  }
}

- (void)removeTypingAttributes {
  // all the heading still needs to be removed because this function may be
  // called in conflicting styles logic typing attributes already get removed in
  // there as well
  [self removeAttributes:[self typedInput]->textView.selectedRange];
}

- (BOOL)styleCondition:(id _Nullable)value range:(NSRange)range {
  EnrichedParagraphStyle *paragraphStyle = (EnrichedParagraphStyle *)value;
  return paragraphStyle != nullptr &&
         paragraphStyle.headingLevel == [self.class headingLevel];
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
  // in a heading and a new text ends with a newline
  if ([self detectStyle:[self typedInput]->textView.selectedRange] &&
      text.length > 0 &&
      [[NSCharacterSet newlineCharacterSet]
          characterIsMember:[text characterAtIndex:text.length - 1]]) {
    // do the replacement manually
    [TextInsertionUtils replaceText:text
                                 at:range
               additionalAttributes:nullptr
                              input:[self typedInput]
                      withSelection:YES];
    // remove the attribtues at the new selection
    [self removeAttributes:[self typedInput]->textView.selectedRange];
    return YES;
  }
  return NO;
}

// Backspacing a line after a heading "into" a heading will not result in the
// text not receiving heading font attributes.
// Hence, we fix these attributes then.
- (BOOL)handleBackspaceInRange:(NSRange)range replacementText:(NSString *)text {
  // Must be a backspace.
  if (text.length != 0) {
    return NO;
  }
  // Backspace must have removed a newline character.
  NSString *removedString =
      [[self typedInput]->textView.textStorage.string substringWithRange:range];
  if ([removedString
          rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]]
          .location == NSNotFound) {
    return NO;
  }

  // Heading style must have been present in a paragraph before the backspaced
  // range.
  NSRange paragraphBeforeBackspaceRange =
      [[self typedInput]->textView.textStorage.string
          paragraphRangeForRange:NSMakeRange(range.location, 0)];
  if (![self detectStyle:paragraphBeforeBackspaceRange]) {
    return NO;
  }

  // Manually do the replacing.
  [TextInsertionUtils replaceText:text
                               at:range
             additionalAttributes:nullptr
                            input:[self typedInput]
                    withSelection:YES];
  // Reapply attributes at the beginning of the backspaced range (it will cover
  // the whole paragraph properly).
  [self addAttributes:NSMakeRange(range.location, 0) withTypingAttributes:NO];

  return YES;
}

@end
