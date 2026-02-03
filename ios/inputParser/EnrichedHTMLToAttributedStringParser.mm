#import "EnrichedHTMLToAttributedStringParser.h"
#import "EnrichedHTMLToAttributedStringParserUtils.h"
#import "StylesStack.h"

#import "Strings.h"
#import <libxml/HTMLparser.h>
#import <libxml/tree.h>

#include <vector>

@implementation EnrichedHTMLToAttributedStringParser {
  NSMutableString *_plain;

  StyleStack _styleStack;
  NSDictionary *_defaultTypingAttributes;
  NSDictionary *_tagsRegistry;
  NSArray<id> *_paragraphModifiers;

  std::vector<StyleContext> _styleContexts;
  std::vector<StyleContext> _paragraphModifierSpans;
}

- (instancetype)initWithStyles:
                    (NSDictionary<NSNumber *, id<BaseStyleProtocol>> *)styles
             defaultAttributes:
                 (NSDictionary<NSAttributedStringKey, id> *)defaultAttributes {
  if (!(self = [super init]))
    return nil;

  _defaultTypingAttributes = defaultAttributes ?: @{};

  NSMutableDictionary *tags = [NSMutableDictionary dictionary];
  NSMutableArray<id> *paragraphModifiers = [NSMutableArray new];

  [styles enumerateKeysAndObjectsUsingBlock:^(
              NSNumber *key, id<BaseStyleProtocol> style, BOOL *stop) {
    const char *tagName = [[style class] tagName];
    if (!tagName && [style.class isParagraphStyle]) {
      [paragraphModifiers addObject:style];
    }
    if (tagName) {
      NSString *tag = [NSString stringWithUTF8String:tagName];
      tags[tag] = style;
    }
  }];

  _tagsRegistry = tags.copy;
  _paragraphModifiers = paragraphModifiers.copy;

  return self;
}

- (NSMutableAttributedString *)parseToAttributedString:(NSString *)html {
  _plain = [NSMutableString new];
  _styleContexts.clear();
  _paragraphModifierSpans.clear();

  if (html.length == 0) {
    return [[NSMutableAttributedString alloc]
        initWithString:@""
            attributes:_defaultTypingAttributes];
  }

  const char *cHtml = html.UTF8String ?: "";

  htmlDocPtr doc = htmlReadMemory(cHtml, (int)strlen(cHtml), NULL, "UTF-8",
                                  HTML_PARSE_NOERROR | HTML_PARSE_NOWARNING |
                                      HTML_PARSE_RECOVER);

  if (!doc) {
    return [[NSMutableAttributedString alloc]
        initWithString:@""
            attributes:_defaultTypingAttributes];
  }

  xmlNodePtr root = xmlDocGetRootElement(doc);
  if (root) {
    [self traverseChildren:root];
  }

  xmlFreeDoc(doc);

  NSMutableAttributedString *result = [[NSMutableAttributedString alloc]
      initWithString:_plain
          attributes:_defaultTypingAttributes];

  [result beginEditing];

  for (const StyleContext &styleApplication : _styleContexts) {
    [styleApplication.style
        addAttributesInAttributedString:result
                                  range:styleApplication.range
                             attributes:styleApplication.attributes];
  }

  for (const StyleContext &styleContext : _paragraphModifierSpans) {
    [styleContext.style
        addAttributesInAttributedString:result
                                  range:styleContext.range
                             attributes:styleContext.attributes];
  }

  [result endEditing];
  return result;
}

#pragma mark - Traversal

- (void)traverseChildren:(xmlNodePtr)parent {
  for (xmlNodePtr cur = parent->children; cur; cur = cur->next) {
    xmlNodePtr nextRenderable = nextRenderableSibling(cur);
    BOOL isLastRenderable = (nextRenderable == NULL);
    [self traverseNode:cur isLastRenderable:isLastRenderable];
  }
}

- (void)traverseNode:(xmlNodePtr)cur isLastRenderable:(BOOL)isLastRenderable {
  if (cur->type == XML_TEXT_NODE) {
    [self traverseTextNode:cur];
    return;
  }

  if (cur->type != XML_ELEMENT_NODE) {
    return;
  }

  const char *tagChar = (const char *)cur->name;

  // <br> handling
  if (isBrTag(tagChar)) {
    [_plain appendString:NewLine];
    return;
  }

  NSString *tag = tagChar ? [NSString stringWithUTF8String:tagChar] : @"";

  id<BaseStyleProtocol> style = _tagsRegistry[tag];
  NSDictionary *attributes = HTMLAttributesFromNodeAndParents(cur);

  BOOL isBlock = isBlockTag(tagChar);

  NSUInteger lengthBefore = _plain.length;

  if (style && [[style class] isSelfClosing]) {
    [self traverseSelfClosing:style attributes:attributes tag:tag];
    return;
  }

  if (style) {
    _styleStack.push(style, attributes);
  }

  if (cur->children) {
    [self traverseChildren:cur];
  }

  BOOL hasContent = _plain.length > lengthBefore;

  if (!hasContent && isBlock) {
    [self appendEmptyBlockPlaceholder];
  }

  if (isBlockTag(tagChar)) {
    [self collectParagraphModifiersIfNeeded:attributes];
    if (!HTMLIsLastParagraphInBlockContext(
            cur, cur->name, cur->parent ? cur->parent->name : NULL,
            isLastRenderable) &&
        !isLastRenderable) {
      [self appendEmptyLineToBLockTag];
    }
  }

  if (style) {
    _styleStack.pop(style);
  }

  if (isTopLevelNode(cur) && isLastRenderable) {
    [self collectParagraphModifiersIfNeeded:attributes];
    return;
  }
}

- (void)traverseTextNode:(xmlNodePtr)node {
  if (!node->content)
    return;

  NSString *text = [NSString stringWithUTF8String:(const char *)node->content];
  if (!text)
    return;

  NSString *collapsed = collapseWhiteSpaceIfNeeded(text);
  if (collapsed.length == 0)
    return;

  if (_plain.length == 0 && isWhiteSpaceOnly(collapsed))
    return;

  if ([self shouldTrimLeadingSpaceForText:collapsed]) {
    collapsed = [collapsed substringFromIndex:1];
  }

  [self appendText:collapsed];
}

- (void)appendText:(NSString *)text {
  if (text.length == 0)
    return;

  NSUInteger start = _plain.length;
  [_plain appendString:text];

  NSRange range = NSMakeRange(start, text.length);

  _styleStack.applyActiveStyles(_styleContexts, range);
}

- (void)appendEmptyLineToBLockTag {
  NSUInteger start = _plain.length;
  [_plain appendString:NewLine];

  NSRange newlineRange = NSMakeRange(start, 1);

  _styleStack.applyActiveParagraphStyles(_styleContexts, newlineRange);
}

- (void)appendEmptyBlockPlaceholder {
  // ZWS
  [self appendText:ZWS];
}

#pragma mark - Self closing

- (void)traverseSelfClosing:(id<BaseStyleProtocol>)style
                 attributes:(NSDictionary *)attributes
                        tag:(NSString *)tag {
  const BOOL isBlock = [style.class isParagraphStyle];

  // if it's a block tag close previous style
  if (isBlock && _plain.length > 0) {
    unichar last = [_plain characterAtIndex:_plain.length - 1];
    if (last != NewLineUnsinedChar) {
      [self appendEmptyLineToBLockTag];
    }
  }

  const NSUInteger start = _plain.length;
  [_plain appendString:ORC];

  const NSRange inlineRange = NSMakeRange(start, 1);

  _styleContexts.emplace_back(style, inlineRange, attributes);

  if (isBlock) {
    NSRange paragraphRange = [_plain
        paragraphRangeForRange:NSMakeRange(MAX((NSInteger)_plain.length - 1, 0),
                                           0)];

    for (id<BaseStyleProtocol> modifier in _paragraphModifiers) {
      _paragraphModifierSpans.emplace_back(modifier, paragraphRange,
                                           attributes);
    }

    [self appendEmptyLineToBLockTag];
  }
}

#pragma mark - Paragraph modifiers (collect only)

- (void)collectParagraphModifiersIfNeeded:(NSDictionary *)attributes {
  if (_plain.length == 0 || attributes.count == 0)
    return;
  NSRange paragraphRange = [_plain
      paragraphRangeForRange:NSMakeRange(MAX((NSInteger)_plain.length - 1, 0),
                                         0)];

  for (id<BaseStyleProtocol> modifier in _paragraphModifiers) {
    StyleContext styleContext(modifier, paragraphRange, attributes);
    _paragraphModifierSpans.push_back(styleContext);
  }
}

#pragma mark - Helpers
- (xmlNodePtr)nextRenderableSibling:(xmlNodePtr)node {
  for (xmlNodePtr next = node->next; next; next = next->next) {
    if (next->type == XML_ELEMENT_NODE) {
      return next;
    }

    if (next->type == XML_TEXT_NODE && next->content) {
      NSString *text =
          [NSString stringWithUTF8String:(const char *)next->content];
      if ([[text stringByTrimmingCharactersInSet:
                     NSCharacterSet.whitespaceAndNewlineCharacterSet] length] >
          0) {
        return next;
      }
    }
  }
  return NULL;
}

- (BOOL)shouldTrimLeadingSpaceForText:(NSString *)text {
  if (_plain.length == 0)
    return NO;
  if (![text hasPrefix:@" "])
    return NO;

  unichar last = [_plain characterAtIndex:_plain.length - 1];
  return [[NSCharacterSet whitespaceAndNewlineCharacterSet]
      characterIsMember:last];
}

@end
