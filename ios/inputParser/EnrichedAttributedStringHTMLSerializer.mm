#import "EnrichedAttributedStringHTMLSerializer.h"
#import "EnrichedAttributedStringHTMLSerializerTagUtils.h"
#import "HtmlNode.h"
#import "ParagraphModifierStyle.h"
#import "Strings.h"
#import "StyleDescriptor.h"
#import "StyleHeaders.h"
#import "objc/runtime.h"
#include "vector"

@implementation EnrichedAttributedStringHTMLSerializer {
  std::vector<StyleDescriptor> _inlineStyleDescriptors;
  std::vector<StyleDescriptor> _paragraphStyleDescriptors;
  std::vector<StyleDescriptor> _modifierStyleDescriptors;
}

- (instancetype)initWithStyles:(NSDictionary<NSNumber *, id> *)stylesDict {
  self = [super init];
  if (!self)
    return nil;

  [self buildAllStyleDescriptors:stylesDict];

  return self;
}

- (void)buildAllStyleDescriptors:(NSDictionary<NSNumber *, id> *)stylesDict {
  _inlineStyleDescriptors.clear();
  _paragraphStyleDescriptors.clear();
  _modifierStyleDescriptors.clear();

  SEL conditionSEL = @selector(styleCondition:range:);
  SEL conditionWithAttributesSEL = @selector(styleConditionWithAttributes:
                                                                    range:);
  SEL paramsSEL = @selector(getParametersFromValue:);
  SEL modifierParamsSEL = @selector(containerAttributesFromValue:);

  for (id<BaseStyleProtocol> style in stylesDict.allValues) {
    Class cls = object_getClass(style);

    StyleDescriptor descriptor{};
    descriptor.styleObject = style;
    descriptor.attributeKey = [cls attributeKey];
    descriptor.tagName = [cls tagName];
    descriptor.subTagName = [cls subTagName];
    descriptor.selfClosing = [cls isSelfClosing];

    BOOL isParagraph = [cls isParagraphStyle];
    BOOL isModifier =
        isParagraph &&
        [cls conformsToProtocol:@protocol(ParagraphModifierStyle)];
    if ([style respondsToSelector:conditionWithAttributesSEL]) {
      descriptor.conditionWithAttributesSEL = conditionWithAttributesSEL;
      descriptor.conditionWithAttributesIMP = class_getMethodImplementation(
          object_getClass(style), descriptor.conditionWithAttributesSEL);
    } else {
      descriptor.conditionSEL = conditionSEL;
      descriptor.conditionIMP = class_getMethodImplementation(
          object_getClass(style), descriptor.conditionSEL);
    }

    if ([cls respondsToSelector:paramsSEL]) {
      descriptor.getParaimsSEL = paramsSEL;
      descriptor.getParamsIMP = (IMP)[cls methodForSelector:paramsSEL];
    } else if (isModifier && [cls respondsToSelector:modifierParamsSEL]) {
      descriptor.getParaimsSEL = modifierParamsSEL;
      descriptor.getParamsIMP = (IMP)[cls methodForSelector:modifierParamsSEL];
    } else {
      descriptor.getParaimsSEL = NULL;
      descriptor.getParamsIMP = NULL;
    }

    if (!isParagraph) {
      _inlineStyleDescriptors.push_back(descriptor);
    } else if (isModifier) {
      _modifierStyleDescriptors.push_back(descriptor);
    } else {
      _paragraphStyleDescriptors.push_back(descriptor);
    }
  }
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

  __block const StyleDescriptor *previousParagraphDescriptor = nil;
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
                            previousParagraphDescriptor = nil;
                            previousNode = nil;
                            return;
                          }

                          NSDictionary *attrsAtStart =
                              [text attributesAtIndex:paragraphRange.location
                                       effectiveRange:nil];

                          const StyleDescriptor *paragraphDescriptor =
                              [self detectParagraphDescriptor:text
                                               paragraphRange:paragraphRange
                                                 attrsAtStart:attrsAtStart];

                          HTMLElement *container = [self
                              containerForParagraphDescriptor:
                                  paragraphDescriptor
                                  previousParagraphDescriptor:
                                      previousParagraphDescriptor
                                                 previousNode:previousNode
                                                     rootNode:root
                                                 attrsAtStart:attrsAtStart];

                          previousParagraphDescriptor = paragraphDescriptor;
                          previousNode = container;

                          HTMLElement *target = [self
                              nextContainerForParagraphDescritpro:
                                  paragraphDescriptor
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
                                                [target.children
                                                    addObject:node];
                                              }];
                        }
                      }];

  return root;
}

#pragma mark - Paragraph style detection

- (const StyleDescriptor *)detectParagraphDescriptor:(NSAttributedString *)text
                                      paragraphRange:(NSRange)paragraphRange
                                        attrsAtStart:
                                            (NSDictionary *)attrsAtStart {

  for (auto &d : _paragraphStyleDescriptors) {
    id value = d.attributeKey ? attrsAtStart[d.attributeKey] : nil;
    if (!value)
      continue;

    CondIMP fn = (CondIMP)d.conditionIMP;
    if (fn(d.styleObject, d.conditionSEL, value, paragraphRange))
      return &d;
  }
  return nullptr;
}

#pragma mark - Paragraph attributes

- (NSDictionary *)
    paragraphAttributesForDescriptor:(const StyleDescriptor *)styleDescriptor
                        attrsAtStart:(NSDictionary *)attrsAtStart {

  NSMutableDictionary *result = [NSMutableDictionary new];

  if (styleDescriptor && styleDescriptor->getParamsIMP) {
    id value = styleDescriptor->attributeKey
                   ? attrsAtStart[styleDescriptor->attributeKey]
                   : nil;

    if (value) {
      typedef NSDictionary *(*ParamsIMP)(id, SEL, id);
      ParamsIMP fn = (ParamsIMP)styleDescriptor->getParamsIMP;

      NSDictionary *base = fn(styleDescriptor->styleObject,
                              styleDescriptor->getParaimsSEL, value);

      if (base)
        [result addEntriesFromDictionary:base];
    }
  }

  for (const StyleDescriptor &modifierDescriptor : _modifierStyleDescriptors) {
    if (!modifierDescriptor.getParamsIMP)
      continue;

    id value = modifierDescriptor.attributeKey
                   ? attrsAtStart[modifierDescriptor.attributeKey]
                   : nil;
    if (!value)
      continue;

    typedef NSDictionary *(*ParamsIMP)(id, SEL, id);
    ParamsIMP fn = (ParamsIMP)modifierDescriptor.getParamsIMP;

    NSDictionary *attrs = fn(modifierDescriptor.styleObject,
                             modifierDescriptor.getParaimsSEL, value);

    if (attrs)
      [result addEntriesFromDictionary:attrs];
  }

  return result;
}

#pragma mark - Containers

- (HTMLElement *)containerForParagraphDescriptor:
                     (const StyleDescriptor *)paragraphDescriptor
                     previousParagraphDescriptor:
                         (const StyleDescriptor *)previousParagraphDescriptor
                                    previousNode:(HTMLElement *)previousNode
                                        rootNode:(HTMLElement *)rootNode
                                    attrsAtStart:(NSDictionary *)attrsAtStart {

  if (!paragraphDescriptor) {
    HTMLElement *outer = [HTMLElement new];
    outer.tag = HtmlParagraphTag;
    [self applyParagraphModifiersToElement:outer attrsAtStart:attrsAtStart];
    [rootNode.children addObject:outer];
    return outer;
  }

  BOOL hasSubTag = paragraphDescriptor->subTagName != NULL;

  BOOL sameStyle = NO;
  if (paragraphDescriptor == previousParagraphDescriptor && previousNode) {
    NSDictionary *currentAttrs =
        [self paragraphAttributesForDescriptor:paragraphDescriptor
                                  attrsAtStart:attrsAtStart];
    NSDictionary *prevAttrs = previousNode.attributes ?: @{};
    sameStyle = [currentAttrs isEqualToDictionary:prevAttrs];
  }

  if (sameStyle && hasSubTag)
    return previousNode;

  HTMLElement *outer = [HTMLElement new];
  outer.tag = paragraphDescriptor->tagName;
  outer.selfClosing = paragraphDescriptor->selfClosing;

  NSDictionary *attrs =
      [self paragraphAttributesForDescriptor:paragraphDescriptor
                                attrsAtStart:attrsAtStart];
  if (attrs.count)
    outer.attributes = attrs;

  [rootNode.children addObject:outer];
  return outer;
}

#pragma mark - Sub containers

- (HTMLElement *)nextContainerForParagraphDescritpro:
                     (const StyleDescriptor *)paragraphDescriptor
                                    currentContainer:(HTMLElement *)container {
  if (!paragraphDescriptor)
    return container;

  const char *subTag = paragraphDescriptor->subTagName;
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

  for (const StyleDescriptor &modifierStyleDescriptor :
       _modifierStyleDescriptors) {
    id value = modifierStyleDescriptor.attributeKey
                   ? attrsAtStart[modifierStyleDescriptor.attributeKey]
                   : nil;
    if (!value || !modifierStyleDescriptor.getParamsIMP)
      continue;

    typedef NSDictionary *(*ParamsIMP)(id, SEL, id);
    ParamsIMP fn = (ParamsIMP)modifierStyleDescriptor.getParamsIMP;

    NSDictionary *attrs = fn(modifierStyleDescriptor.styleObject,
                             modifierStyleDescriptor.getParaimsSEL, value);

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

  for (const StyleDescriptor &d : _inlineStyleDescriptors) {
    id value = attrs[d.attributeKey];
    if (!value)
      continue;

    if (d.conditionWithAttributesIMP) {
      CondWithAttributesIMP conditionFn =
          (CondWithAttributesIMP)d.conditionWithAttributesIMP;

      if (!conditionFn(d.styleObject, d.conditionWithAttributesSEL, attrs,
                       range))
        continue;
    } else {
      CondIMP fn = (CondIMP)d.conditionIMP;

      if (!fn(d.styleObject, d.conditionSEL, value, range))
        continue;
    }

    HTMLElement *wrap = [HTMLElement new];
    wrap.tag = d.tagName;
    wrap.selfClosing = d.selfClosing;

    if (d.getParamsIMP) {
      typedef NSDictionary *(*ParamsIMP)(id, SEL, id);
      ParamsIMP pfn = (ParamsIMP)d.getParamsIMP;
      wrap.attributes = pfn(d.styleObject, d.getParaimsSEL, value);
    }

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
    appendC(buffer, NewLineChar);

  appendCloseTag(buffer, element.tag);
}

@end
