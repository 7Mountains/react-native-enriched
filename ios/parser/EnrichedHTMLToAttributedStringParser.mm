#import "EnrichedHTMLToAttributedStringParser.h"
#import "EnrichedHTMLDocumentReader.h"
#import "EnrichedHTMLToAttributedStringParserUtils.h"
#import "EnrichedParserStyleRegistry.h"
#import "StylesStack.h"

#import "Strings.h"
#import <libxml/HTMLparser.h>
#import <libxml/tree.h>

#include <cstring>
#include <string>
#include <vector>

@implementation EnrichedHTMLToAttributedStringParser {
  NSMutableString *_plain;

  StyleStack _styleStack;
  NSDictionary *_defaultTypingAttributes;
  EnrichedParserStyleRegistry *_registry;
  NSArray<id> *_paragraphModifiers;

  std::vector<StyleContext> _styleContexts;
  std::vector<StyleContext> _paragraphModifierStyleContexts;

  // The collapsed white space of the text nodes
  std::string _collapsedText;
}

- (instancetype)initWithStyles:
                    (NSDictionary<NSNumber *, id<BaseStyleProtocol>> *)styles
             defaultAttributes:
                 (NSDictionary<NSAttributedStringKey, id> *)defaultAttributes {
  if (!(self = [super init]))
    return nil;

  _defaultTypingAttributes = defaultAttributes ?: @{};
  _plain = [NSMutableString new];

  _registry = [EnrichedParserStyleRegistry registryForStyles:styles];
  _paragraphModifiers = _registry.paragraphModifiers;

  return self;
}

- (NSMutableAttributedString *)parseToAttributedString:(NSString *)html {
  const char *cHtml = html.UTF8String ?: "";
  return [self parseToAttributedStringFromUTF8:cHtml length:strlen(cHtml)];
}

- (NSMutableAttributedString *)parseToAttributedStringFromUTF8:
                                   (const char *)html
                                                        length:(size_t)length {
  if (length == 0) {
    return [[NSMutableAttributedString alloc]
        initWithString:@""
            attributes:_defaultTypingAttributes];
  }

  htmlDocPtr doc = EnrichedReadHTMLDocument(html, length);

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

  for (const StyleContext &styleContext : _paragraphModifierStyleContexts) {
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

  id<BaseStyleProtocol> style = [_registry styleForTag:tagChar];
  BOOL isBlock = isBlockTag(tagChar);
  BOOL isTopLevelLast = isLastRenderable && isTopLevelNode(cur);

  NSDictionary *attributes = (style || isBlock || isTopLevelLast)
                                 ? HTMLAttributesFromNodeAndParents(cur)
                                 : nil;

  NSUInteger lengthBefore = _plain.length;

  if (style && [[style class] isSelfClosing]) {
    [self traverseSelfClosing:style attributes:attributes];
    return;
  }

  if (style) {
    _styleStack.push(style, attributes);
  }

  if (cur->children) {
    [self traverseChildren:cur];
  }

  BOOL hasContent = _plain.length > lengthBefore;

  BOOL needsPlaceholder = isListItemTag(tagChar) || isCheckListTag(tagChar);

  if (!hasContent && isBlock && (needsPlaceholder && lengthBefore != 0)) {
    [self appendEmptyBlockPlaceholder];
  }

  if (isBlock) {
    [self collectParagraphModifiersIfNeeded:attributes];
    if (!HTMLIsLastParagraphInBlockContext(
            cur, cur->name, cur->parent ? cur->parent->name : NULL,
            isLastRenderable) &&
        !isLastRenderable) {
      [self appendEmptyLineToBLockTag];
    }
  }

  if (isTopLevelLast) {
    [self collectParagraphModifiersIfNeeded:attributes];
    return;
  }

  if (style) {
    _styleStack.pop(style);
  }
}

- (void)traverseTextNode:(xmlNodePtr)node {
  if (!node->content)
    return;

  NSUInteger start = _plain.length;

  // After white space, its leading space is left out as it's made: not cut
  // from it after
  NSUInteger length =
      appendCollapsedWhiteSpace(_plain, (const char *)node->content,
                                [self endsWithWhiteSpace], _collapsedText);
  if (length == 0)
    return;

  NSRange range = NSMakeRange(start, length);
  if (start == 0 && isWhiteSpaceOnly(_plain, range)) {
    [_plain deleteCharactersInRange:range];
    return;
  }

  _styleStack.applyActiveStyles(_styleContexts, range);
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
  [_plain appendString:NewLine];
}

- (void)appendEmptyBlockPlaceholder {
  // ZWS
  [self appendText:ZWS];
}

#pragma mark - Self closing

- (void)traverseSelfClosing:(id<BaseStyleProtocol>)style
                 attributes:(NSDictionary *)attributes {
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
      _paragraphModifierStyleContexts.emplace_back(modifier, paragraphRange,
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
    _paragraphModifierStyleContexts.emplace_back(modifier, paragraphRange,
                                                 attributes);
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

- (BOOL)endsWithWhiteSpace {
  if (_plain.length == 0)
    return NO;

  unichar last = [_plain characterAtIndex:_plain.length - 1];
  return [[NSCharacterSet whitespaceAndNewlineCharacterSet]
      characterIsMember:last];
}

@end
