#import "AlignmentConverter.h"
#import "EnrichedParagraphStyle.h"
#import "EnrichedTextInputView.h"
#import "HtmlAttributeNames.h"
#import "OccurenceUtils.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"

@implementation ParagraphAlignmentStyle {
  EnrichedTextInputView *_input;
}

#pragma mark - Init

- (instancetype)initWithInput:(id)input {
  self = [super init];
  _input = (EnrichedTextInputView *)input;
  return self;
}

+ (StyleType)getStyleType {
  return ParagraphAlignment;
}

+ (BOOL)isParagraphStyle {
  return YES;
}

+ (const char *)tagName {
  return nullptr;
}
+ (const char *)subTagName {
  return nullptr;
}

+ (NSAttributedStringKey)attributeKey {
  return NSParagraphStyleAttributeName;
}

+ (BOOL)isSelfClosing {
  return NO;
}

#pragma mark - Serialization

+ (NSDictionary<NSString *, NSString *> *)containerAttributesFromValue:
    (id)value {
  if (![value isKindOfClass:[NSParagraphStyle class]])
    return nil;

  NSTextAlignment alignment = ((NSParagraphStyle *)value).alignment;
  if (alignment == NSTextAlignmentNatural)
    return nil;

  return @{
    AlignmentAttributeName : [AlignmentConverter stringFromAlignment:alignment]
  };
}

#pragma mark - List helpers

- (NSTextList *)listFromStyle:(NSParagraphStyle *)style {
  return style.textLists.firstObject;
}

- (BOOL)sameList:(NSParagraphStyle *)a other:(NSParagraphStyle *)b {
  return [[self listFromStyle:a].markerFormat
      isEqualToString:[self listFromStyle:b].markerFormat];
}

#pragma mark - Range helpers

- (NSRange)paragraphRangeForRange:(NSRange)range {
  return [_input->textView.textStorage.string paragraphRangeForRange:range];
}

- (BOOL)rangeTouchesList:(NSRange)range {
  NSTextStorage *storage = _input->textView.textStorage;

  __block BOOL touches = NO;
  [storage enumerateAttribute:NSParagraphStyleAttributeName
                      inRange:range
                      options:0
                   usingBlock:^(id value, NSRange r, BOOL *stop) {
                     auto listMarker = [self listFromStyle:value].markerFormat;
                     if (listMarker == NSTextListMarkerDisc ||
                         listMarker == NSTextListMarkerDecimal) {
                       touches = YES;
                       *stop = YES;
                     }
                   }];
  return touches;
}

- (NSParagraphStyle *)paragraphStyleAtRange:(NSRange)range
                                    storage:(NSTextStorage *)storage {
  if (storage.length == 0)
    return nil;
  NSUInteger index = MIN(range.location, storage.length - 1);
  return [storage attribute:NSParagraphStyleAttributeName
                    atIndex:index
             effectiveRange:nil];
}

#pragma mark - Expand list

- (NSRange)expandRangeToFullList:(NSRange)range {
  NSTextStorage *storage = _input->textView.textStorage;
  NSString *text = storage.string;
  if (text.length == 0)
    return range;

  NSRange base = [text paragraphRangeForRange:range];
  NSParagraphStyle *baseStyle = [self paragraphStyleAtRange:base
                                                    storage:storage];

  NSTextList *baseList = [self listFromStyle:baseStyle];
  if (!baseList)
    return base;

  NSInteger start = base.location;
  NSInteger end = NSMaxRange(base);

  // go up
  while (start > 0) {
    NSRange prev = [text paragraphRangeForRange:NSMakeRange(start - 1, 0)];
    NSParagraphStyle *style = [self paragraphStyleAtRange:prev storage:storage];
    if (![self sameList:style other:baseStyle])
      break;
    start = prev.location;
  }

  // go down
  while (end < text.length) {
    NSRange next = [text paragraphRangeForRange:NSMakeRange(end, 0)];
    NSParagraphStyle *style = [self paragraphStyleAtRange:next storage:storage];
    if (![self sameList:style other:baseStyle])
      break;
    end = NSMaxRange(next);
  }

  return NSMakeRange(start, end - start);
}

#pragma mark - Apply alignment

- (void)applyAlignment:(NSTextAlignment)alignment inRange:(NSRange)range {
  NSTextStorage *storage = _input->textView.textStorage;
  NSString *text = storage.string;
  if (range.location == NSNotFound || text.length == 0)
    return;

  [storage beginEditing];

  [text enumerateSubstringsInRange:range
                           options:NSStringEnumerationByParagraphs
                        usingBlock:^(NSString *sub, NSRange paragraph,
                                     NSRange range, BOOL *stop) {
                          NSParagraphStyle *current =
                              [self paragraphStyleAtRange:paragraph
                                                  storage:storage];

                          EnrichedParagraphStyle *style =
                              current ? [current mutableCopy]
                                      : [EnrichedParagraphStyle new];

                          style.alignment = alignment;

                          [storage addAttribute:NSParagraphStyleAttributeName
                                          value:style
                                          range:paragraph];
                        }];

  [storage endEditing];
}

- (void)updateTypingAlignment:(NSTextAlignment)alignment {
  NSMutableDictionary *typing = [_input->textView.typingAttributes mutableCopy]
                                    ?: [NSMutableDictionary new];

  EnrichedParagraphStyle *style =
      [typing[NSParagraphStyleAttributeName] mutableCopy]
          ?: [EnrichedParagraphStyle new];

  style.alignment = alignment;
  typing[NSParagraphStyleAttributeName] = style;

  _input->textView.typingAttributes = typing;
}

#pragma mark - Main entry point

- (void)applyStyle:(NSRange)range alignment:(NSTextAlignment)alignment {
  NSRange paragraphRange = [self paragraphRangeForRange:range];

  if ([self rangeTouchesList:paragraphRange]) {
    paragraphRange = [self expandRangeToFullList:paragraphRange];
  }

  [self applyAlignment:alignment inRange:paragraphRange];
  [self updateTypingAlignment:alignment];
}

#pragma mark - Required overrides

- (void)applyStyle:(NSRange)range {
  // alignment uses applyStyle:alignment:
}

#pragma mark - Enter handling

- (BOOL)handleEnterPressInRange:(NSRange)range
                replacementText:(NSString *)text {

  if ([self detectStyle:_input->textView.selectedRange] && text.length > 0 &&
      [[NSCharacterSet newlineCharacterSet]
          characterIsMember:[text characterAtIndex:text.length - 1]]) {

    [TextInsertionUtils replaceText:text
                                 at:range
               additionalAttributes:nil
                              input:_input
                      withSelection:YES];

    NSRange newParagraph = [_input->textView.textStorage.string
        paragraphRangeForRange:_input->textView.selectedRange];

    [_input->textView.textStorage beginEditing];
    [_input->textView.textStorage removeAttribute:NSParagraphStyleAttributeName
                                            range:newParagraph];
    [_input->textView.textStorage endEditing];

    return YES;
  }

  return NO;
}

#pragma mark - Style detection

- (BOOL)styleCondition:(id)value range:(NSRange)range {
  NSParagraphStyle *style = (NSParagraphStyle *)value;
  return value != nil && style.alignment != NSTextAlignmentNatural;
}

- (BOOL)detectStyle:(NSRange)range {
  if (range.length >= 1) {
    return [OccurenceUtils detect:NSParagraphStyleAttributeName
                        withInput:_input
                          inRange:range
                    withCondition:^BOOL(id value, NSRange r) {
                      return [self styleCondition:value range:r];
                    }];
  } else {
    return [OccurenceUtils detect:NSParagraphStyleAttributeName
                        withInput:_input
                          atIndex:range.location
                    checkPrevious:YES
                    withCondition:^BOOL(id value, NSRange r) {
                      return [self styleCondition:value range:r];
                    }];
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:NSParagraphStyleAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id value, NSRange r) {
                 return [self styleCondition:value range:r];
               }];
}

- (NSArray<StylePair *> *)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:NSParagraphStyleAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id value, NSRange r) {
                 return [self styleCondition:value range:r];
               }];
}

- (void)addAttributes:(NSRange)range {
}
- (void)removeAttributes:(NSRange)range {
}

- (void)addAttributesInAttributedString:(NSMutableAttributedString *)string
                                  range:(NSRange)range
                             attributes:(NSDictionary<NSString *, NSString *> *)
                                            attributes {
  NSString *alignmentString = attributes[AlignmentAttributeName];
  if (!alignmentString) {
    return;
  }

  NSTextAlignment alignment =
      [AlignmentConverter alignmentFromString:alignmentString];

  NSParagraphStyle *current = [string attribute:NSParagraphStyleAttributeName
                                        atIndex:range.location
                                 effectiveRange:nil];

  EnrichedParagraphStyle *mutableParagraphStyle =
      current ? [current mutableCopy] : [EnrichedParagraphStyle new];

  mutableParagraphStyle.alignment = alignment;

  [string addAttribute:NSParagraphStyleAttributeName
                 value:mutableParagraphStyle
                 range:range];
}

- (void)addTypingAttributes {
  // no-op
}

- (void)removeTypingAttributes {
  // no-op
}

@end
