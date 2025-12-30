#import "EnrichedAttributedStringHTMLSerializer.h"
#import "EnrichedAttributedStringHTMLSerializerTagUtils.h"
#import "HtmlNode.h"
#import "ParagraphModifierStyle.h"
#import "StyleHeaders.h"

@implementation EnrichedAttributedStringHTMLSerializer {
  NSDictionary<NSNumber *, id<BaseStyleProtocol>> *_styles;
  NSArray<id<BaseStyleProtocol>> *_inlineStyles;
  NSArray<id<BaseStyleProtocol>> *_paragraphStyles;
  NSArray<id<BaseStyleProtocol>> *_paragraphModificatorStyles;
}

- (instancetype)initWithStyles:(NSDictionary<NSNumber *, id> *)stylesDict {
  self = [super init];
  if (!self)
    return nil;

  _styles = stylesDict ?: @{};

  NSMutableArray *inlineStylesArray = [NSMutableArray array];
  NSMutableArray *paragraphStylesArray = [NSMutableArray array];
  NSMutableArray *paragraphModificatorsArray = [NSMutableArray array];

  for (NSNumber *key in stylesDict.allKeys) {
    id<BaseStyleProtocol> style = stylesDict[key];
    Class cls = style.class;

    BOOL isParagraph = ([cls respondsToSelector:@selector(isParagraphStyle)]) &&
                       [cls isParagraphStyle];

    if (isParagraph) {
      BOOL isParagraphModificatorStyle =
          [cls conformsToProtocol:@protocol(ParagraphModifierStyle)];

      isParagraphModificatorStyle ? [paragraphModificatorsArray addObject:style]
                                  : [paragraphStylesArray addObject:style];
    } else {
      [inlineStylesArray addObject:style];
    }
  }

  _inlineStyles = inlineStylesArray.copy;
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

                        HTMLElement *target =
                            [self nextContainerForParagraphStyle:paragraphStyle
                                                currentContainer:container];

                        [text
                            enumerateAttributesInRange:paragraphRange
                                               options:0
                                            usingBlock:^(
                                                NSDictionary *attrs,
                                                NSRange runRange,
                                                BOOL *__unused stopRun) {
                                              HTMLNode *node = [self
                                                  getInlineStyleNodes:text
                                                                range:runRange
                                                                attrs:attrs
                                                                plain:plain];
                                              [target.children addObject:node];
                                            }];
                      }];

  return root;
}

#pragma mark - Paragraph style detection

- (id<BaseStyleProtocol> _Nullable)
    detectParagraphStyle:(NSAttributedString *)text
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

#pragma mark - Attribute computation (NEW)

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
    Class modifierClass = modifier.class;
    NSAttributedStringKey attributeKey = [modifierClass attributeKey];
    id mvalue = attributeKey ? attrsAtStart[attributeKey] : nil;

    if ([modifierClass
            respondsToSelector:@selector(containerAttributesFromValue:)]) {
      NSDictionary *attrs = [modifierClass containerAttributesFromValue:mvalue];
      if (attrs)
        [result addEntriesFromDictionary:attrs];
    }
  }

  return result;
}

#pragma mark - Container creation

- (HTMLElement *)
    containerForParagraphStyle:(id<BaseStyleProtocol> _Nullable)currentStyle
        previousParagraphStyle:(id<BaseStyleProtocol> _Nullable)previousStyle
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

  Class styleClass = currentStyle.class;
  BOOL hasSubTag = ([styleClass subTagName] != NULL);

  BOOL sameStyle = NO;

  if (currentStyle == previousStyle && previousNode) {
    NSDictionary *currentAttrs =
        [self paragraphAttributesForStyle:currentStyle
                             attrsAtStart:attrsAtStart];

    NSDictionary *previousAttrs = previousNode.attributes ?: @{};

    sameStyle = [currentAttrs isEqualToDictionary:previousAttrs];
  }

  if (sameStyle && hasSubTag)
    return previousNode;

  HTMLElement *outer = [HTMLElement new];
  outer.tag = [styleClass tagName];
  outer.selfClosing = [styleClass isSelfClosing];

  NSDictionary *attrs = [self paragraphAttributesForStyle:currentStyle
                                             attrsAtStart:attrsAtStart];
  if (attrs.count > 0)
    outer.attributes = attrs;

  [rootNode.children addObject:outer];
  return outer;
}

#pragma mark - Sub containers

- (HTMLElement *)nextContainerForParagraphStyle:
                     (id<BaseStyleProtocol> _Nullable)style
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
    Class styleClass = style.class;
    NSAttributedStringKey key = [styleClass attributeKey];
    id value = key ? attrsAtStart[key] : nil;

    NSDictionary *attrs =
        [styleClass respondsToSelector:@selector(containerAttributesFromValue:)]
            ? [styleClass containerAttributesFromValue:value]
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

  HTMLTextNode *textNode = [HTMLTextNode new];
  textNode.source = plain;
  textNode.range = range;

  HTMLNode *currentNode = textNode;

  for (id<BaseStyleProtocol> styleObject in _inlineStyles) {
    Class styleClass = styleObject.class;
    NSAttributedStringKey key = [styleClass attributeKey];
    id value = attrs[key];
    // very specific case since we have to manage different colors.
    // Maybe we can avoid it in the future
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

#pragma mark - HTML rendering

- (void)createHtmlFromNode:(HTMLNode *)node
                      into:(NSMutableData *)buffer
                   pretify:(BOOL)pretify {
  if ([node isKindOfClass:[HTMLTextNode class]]) {
    HTMLTextNode *t = (HTMLTextNode *)node;
    appendEscapedRange(buffer, t.source, t.range);
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

  appendOpenTag(buffer, element.tag, element.attributes ?: nullptr,
                addNewLineBefore);

  for (HTMLNode *child in element.children)
    [self createHtmlFromNode:child into:buffer pretify:pretify];

  if (addNewLineAfter)
    appendC(buffer, NewLine);

  appendCloseTag(buffer, element.tag);
}

@end
