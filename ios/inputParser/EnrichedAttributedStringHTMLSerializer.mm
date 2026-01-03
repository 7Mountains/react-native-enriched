#import "EnrichedAttributedStringHTMLSerializer.h"
#import "EnrichedAttributedStringHTMLSerializerTagUtils.h"
#import "HtmlNode.h"
#import "ParagraphModifierStyle.h"
#import "StyleHeaders.h"

@implementation EnrichedAttributedStringHTMLSerializer {
  NSDictionary<NSNumber *, id<BaseStyleProtocol>> *_styles;
  NSDictionary<NSString *, id<BaseStyleProtocol>> *_inlineStylesByAttributeKeys;
  NSArray<id<BaseStyleProtocol>> *_paragraphStyles;
  NSArray<id<BaseStyleProtocol>> *_paragraphModificatorStyles;
}

- (instancetype)initWithStyles:(NSDictionary<NSNumber *, id> *)stylesDict {
  self = [super init];
  if (!self)
    return nil;

  _styles = stylesDict ?: @{};

  NSMutableDictionary<NSString *, id<BaseStyleProtocol>>
      *inlineStylesByAttributeKeys = [NSMutableDictionary new];
  NSMutableArray *paragraphStylesArray = [NSMutableArray array];
  NSMutableArray *paragraphModificatorsArray = [NSMutableArray array];

  for (NSNumber *key in stylesDict.allKeys) {
    id<BaseStyleProtocol> style = stylesDict[key];
    Class cls = style.class;

    BOOL isParagraph = [cls isParagraphStyle];

    if (isParagraph) {
      BOOL isParagraphModificatorStyle =
          [cls conformsToProtocol:@protocol(ParagraphModifierStyle)];

      isParagraphModificatorStyle ? [paragraphModificatorsArray addObject:style]
                                  : [paragraphStylesArray addObject:style];
    } else {
      inlineStylesByAttributeKeys [[style.class attributeKey]] = style;
    }
  }

  _inlineStylesByAttributeKeys = inlineStylesByAttributeKeys.copy;
  _paragraphStyles = paragraphStylesArray.copy;
  _paragraphModificatorStyles = paragraphModificatorsArray.copy;

  return self;
}

#pragma mark - Public

- (NSString *)buildHtmlFromAttributedString:(NSAttributedString *)text
                                    pretify:(BOOL)pretify {
  if (text.length == 0)
    return DefaultHtmlValue;

  HTMLElement *root = [self buildRootNodeFromAttributedString:text];

  NSMutableData *buffer = [NSMutableData data];
  [self createHtmlFromNode:root into:buffer pretify:pretify];

  return [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
}

#pragma mark - Root building

- (HTMLElement *)buildRootNodeFromAttributedString:(NSAttributedString *)text {
  NSString *plain = text.string;

  HTMLElement *root = [HTMLElement new];
  root.tag = HtmlTagHTML;

  HTMLElement *br = [HTMLElement new];
  br.tag = HtmlTagBR;
  br.selfClosing = YES;

  __block id<BaseStyleProtocol> previousParagraphStyle = nil;
  __block HTMLElement *previousNode = nil;

  [plain
      enumerateSubstringsInRange:NSMakeRange(0, plain.length)
                         options:NSStringEnumerationByParagraphs
                      usingBlock:^(NSString *_Nullable substring,
                                   NSRange paragraphRange,
                                   NSRange __unused enclosingRange,
                                   BOOL *__unused stop) {
                        @autoreleasepool {

                          if (paragraphRange.length == 0) {
                            [root.children addObject:br];
                            previousParagraphStyle = nil;
                            previousNode = nil;
                            return;
                          }

                          NSDictionary *attrsAtStart =
                              [text attributesAtIndex:paragraphRange.location
                                       effectiveRange:nil];

                          id<BaseStyleProtocol> paragraphStyle =
                              [self detectParagraphStyle:text
                                          paragraphRange:paragraphRange
                                            attrsAtStart:attrsAtStart];

                          HTMLElement *container = [self
                              containerForParagraphStyle:paragraphStyle
                                  previousParagraphStyle:previousParagraphStyle
                                            previousNode:previousNode
                                                rootNode:root
                                            attrsAtStart:attrsAtStart];

                          previousParagraphStyle = paragraphStyle;
                          previousNode = container;

                          HTMLElement *target = [self
                              nextContainerForParagraphStyle:paragraphStyle
                                            currentContainer:container];

                          [text
                              enumerateAttributesInRange:paragraphRange
                                                 options:0
                                              usingBlock:^(
                                                  NSDictionary *attrs,
                                                  NSRange runRange,
                                                  BOOL *__unused stopRun) {
                                                @autoreleasepool {
                                                  HTMLNode *node = [self
                                                      getInlineStyleNodes:text
                                                                    range:
                                                                        runRange
                                                                    attrs:attrs
                                                                    plain:
                                                                        plain];
                                                  [target.children
                                                      addObject:node];
                                                }
                                              }];
                        }
                      }];

  return root;
}

#pragma mark - Paragraph style detection

- (id<BaseStyleProtocol>)detectParagraphStyle:(NSAttributedString *)text
                               paragraphRange:(NSRange)paragraphRange
                                 attrsAtStart:(NSDictionary *)attrsAtStart {

  for (id<BaseStyleProtocol> paragraphStyle in _paragraphStyles) {
    Class cls = paragraphStyle.class;
    NSAttributedStringKey key = [cls attributeKey];
    id value = attrsAtStart[key];

    if (value && [paragraphStyle styleCondition:value range:paragraphRange]) {
      return paragraphStyle;
    }
  }
  return nil;
}

#pragma mark - Paragraph attributes

- (NSDictionary *)paragraphAttributesForStyle:(id<BaseStyleProtocol>)style
                                 attrsAtStart:(NSDictionary *)attrsAtStart {

  NSMutableDictionary *result = [NSMutableDictionary new];

  if (!style)
    return result;

  Class cls = style.class;
  NSAttributedStringKey key = [cls attributeKey];
  id value = key ? attrsAtStart[key] : nil;

  if (value && [cls respondsToSelector:@selector(getParametersFromValue:)]) {
    NSDictionary *base = [cls getParametersFromValue:value];
    if (base)
      [result addEntriesFromDictionary:base];
  }

  for (id<BaseStyleProtocol> modifier in _paragraphModificatorStyles) {
    Class mcls = modifier.class;
    NSAttributedStringKey mkey = [mcls attributeKey];
    id mvalue = mkey ? attrsAtStart[mkey] : nil;

    if ([mcls respondsToSelector:@selector(containerAttributesFromValue:)]) {
      NSDictionary *attrs = [mcls containerAttributesFromValue:mvalue];
      if (attrs)
        [result addEntriesFromDictionary:attrs];
    }
  }

  return result;
}

#pragma mark - Containers

- (HTMLElement *)containerForParagraphStyle:(id<BaseStyleProtocol>)currentStyle
                     previousParagraphStyle:(id<BaseStyleProtocol>)previousStyle
                               previousNode:(HTMLElement *)previousNode
                                   rootNode:(HTMLElement *)rootNode
                               attrsAtStart:(NSDictionary *)attrsAtStart {

  if (!currentStyle) {
    HTMLElement *outer = [HTMLElement new];
    outer.tag = HtmlParagraphTag;
    [self applyParagraphModifiersToElement:outer attrsAtStart:attrsAtStart];
    [rootNode.children addObject:outer];
    return outer;
  }

  Class cls = currentStyle.class;
  BOOL hasSubTag = ([cls subTagName] != NULL);

  BOOL sameStyle = NO;
  if (currentStyle == previousStyle && previousNode) {
    NSDictionary *currentAttrs =
        [self paragraphAttributesForStyle:currentStyle
                             attrsAtStart:attrsAtStart];
    NSDictionary *prevAttrs = previousNode.attributes ?: @{};
    sameStyle = [currentAttrs isEqualToDictionary:prevAttrs];
  }

  if (sameStyle && hasSubTag)
    return previousNode;

  HTMLElement *outer = [HTMLElement new];
  outer.tag = [cls tagName];
  outer.selfClosing = [cls isSelfClosing];

  NSDictionary *attrs = [self paragraphAttributesForStyle:currentStyle
                                             attrsAtStart:attrsAtStart];
  if (attrs.count)
    outer.attributes = attrs;

  [rootNode.children addObject:outer];
  return outer;
}

#pragma mark - Sub containers

- (HTMLElement *)nextContainerForParagraphStyle:(id<BaseStyleProtocol>)style
                               currentContainer:(HTMLElement *)container {
  if (!style)
    return container;

  const char *subTag = [style.class subTagName];
  if (!subTag)
    return container;

  HTMLElement *inner = [HTMLElement new];
  inner.tag = subTag;
  [container.children addObject:inner];
  return inner;
}

#pragma mark - Modifiers

- (void)applyParagraphModifiersToElement:(HTMLElement *)element
                            attrsAtStart:(NSDictionary *)attrsAtStart {

  for (id<BaseStyleProtocol> style in _paragraphModificatorStyles) {
    Class cls = style.class;
    NSAttributedStringKey key = [cls attributeKey];
    id value = key ? attrsAtStart[key] : nil;

    NSDictionary *attrs =
        [cls respondsToSelector:@selector(containerAttributesFromValue:)]
            ? [cls containerAttributesFromValue:value]
            : nil;

    if (!attrs)
      continue;

    NSMutableDictionary *merged = element.attributes
                                      ? [element.attributes mutableCopy]
                                      : [NSMutableDictionary new];

    [merged addEntriesFromDictionary:attrs];
    element.attributes = merged;
  }
}

#pragma mark - Inline styles

- (HTMLNode *)getInlineStyleNodes:(NSAttributedString *)text
                            range:(NSRange)range
                            attrs:(NSDictionary *)attrs
                            plain:(NSString *)plain {

  @autoreleasepool {
    HTMLTextNode *textNode = [HTMLTextNode new];
    textNode.source = plain;
    textNode.range = range;

    HTMLNode *currentNode = textNode;
    for (NSString *key in _inlineStylesByAttributeKeys) {
      auto styleObject = _inlineStylesByAttributeKeys[key];
      auto styleClass = styleObject.class;
      id value = attrs[key];
      if (!value)
        continue;

      BOOL isColorStyle = [styleClass getStyleType] == Colored;

      BOOL hasStyle =
          isColorStyle
              ? [(ColorStyle *)styleObject styleConditionWithAttributes:attrs
                                                                  range:range]
              : [styleObject styleCondition:value range:range];

      if (!hasStyle)
        continue;

      HTMLElement *wrap = [HTMLElement new];
      wrap.tag = [styleClass tagName];
      wrap.attributes =
          [styleClass respondsToSelector:@selector(getParametersFromValue:)]
              ? [styleClass getParametersFromValue:value]
              : nil;
      wrap.selfClosing = [styleClass isSelfClosing];
      [wrap.children addObject:currentNode];
      currentNode = wrap;
    }

    return currentNode;
  }
}

#pragma mark - HTML rendering

- (void)createHtmlFromNode:(HTMLNode *)node
                      into:(NSMutableData *)buffer
                   pretify:(BOOL)pretify {

  if ([node isKindOfClass:[HTMLTextNode class]]) {
    HTMLTextNode *textNode = (HTMLTextNode *)node;
    appendEscapedRange(buffer, textNode.source, textNode.range);
    return;
  }

  if (![node isKindOfClass:[HTMLElement class]])
    return;

  HTMLElement *element = (HTMLElement *)node;

  BOOL addNewLineBefore = pretify && isBlockTag(element.tag);
  BOOL addNewLineAfter = pretify && needsNewLineAfter(element.tag);

  if (element.selfClosing) {
    appendSelfClosingTag(buffer, element.tag, element.attributes,
                         addNewLineBefore);
    return;
  }

  appendOpenTag(buffer, element.tag, element.attributes ?: nil,
                addNewLineBefore);

  for (HTMLNode *child in element.children) {
    [self createHtmlFromNode:child into:buffer pretify:pretify];
  }

  if (addNewLineAfter)
    appendC(buffer, NewLine);

  appendCloseTag(buffer, element.tag);
}

@end
