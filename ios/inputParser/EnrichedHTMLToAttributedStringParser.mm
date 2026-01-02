#import "EnrichedHTMLToAttributedStringParser.h"
#import "EnrichedHTMLToAttributedStringParserUtils.h"
#import "StylesStack.h"
#import <libxml/HTMLparser.h>
#import <libxml/tree.h>

@implementation EnrichedHTMLToAttributedStringParser {
  NSMutableAttributedString *_result;
  StylesStack *_styleStack;
  NSArray<id> *_paragraphModifiers;
  NSDictionary *_defaultTypingAttributes;
  NSDictionary *_tagsRegistry;
}

- (instancetype)initWithStyles:
                    (NSDictionary<NSNumber *, id<BaseStyleProtocol>> *)styles
             defaultAttributes:
                 (NSDictionary<NSAttributedStringKey, id> *)defaultAttributes {
  if (!(self = [super init]))
    return nil;

  _defaultTypingAttributes = defaultAttributes ?: @{};
  _styleStack = [StylesStack new];

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
  _result = [[NSMutableAttributedString alloc]
      initWithString:@""
          attributes:_defaultTypingAttributes];

  if (html.length == 0) {
    return _result;
  }

  const char *cHtml = html.UTF8String ?: "";

  htmlDocPtr htmlDocumentPtr = htmlReadMemory(
      cHtml, (int)strlen(cHtml), NULL, "UTF-8",
      HTML_PARSE_NOERROR | HTML_PARSE_NOWARNING | HTML_PARSE_RECOVER);

  if (!htmlDocumentPtr)
    return _result;

  [_result beginEditing];

  xmlNodePtr root = xmlDocGetRootElement(htmlDocumentPtr);
  if (root) {
    [self traverseChildren:root];
  }

  xmlFreeDoc(htmlDocumentPtr);
  [_result endEditing];
  return _result;
}

// MARK: - Traversal
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

  NSString *tag = cur->name
                      ? [NSString stringWithUTF8String:(const char *)cur->name]
                            .lowercaseString
                      : @"";

  id<BaseStyleProtocol> style = _tagsRegistry[tag];
  NSDictionary *attributes = HTMLAttributesFromNodeAndParents(cur);

  BOOL isBlock = isBlockTag(tag);

  NSUInteger lengthBefore = _result.length;

  if (style && [[style class] isSelfClosing]) {
    [self traverseSelfClosing:style attributes:attributes tag:tag];
    return;
  }

  if (style) {
    [_styleStack pushStyle:style attributes:attributes];
  }

  if (cur->children) {
    [self traverseChildren:cur];
  }

  BOOL hasContent = _result.length > lengthBefore;

  if (!hasContent && isBlock) {
    // Append ZWS for empty lists/blockquotes
    [self appendEmptyBlockPlaceholder];
  }

  if (style) {
    [_styleStack popStyle:style];
  }

  if (isTopLevelNode(cur) && isLastRenderable) {
    [self applyParagraphModifiersIfNeeded:attributes];
    return;
  }

  if (isBlockTag(tag)) {
    [self applyParagraphModifiersIfNeeded:attributes];
    if (!HTMLIsLastParagraphInBlockContext(
            cur, cur->name, cur->parent ? cur->parent->name : NULL,
            isLastRenderable)) {
      [self appendText:@"\n"];
    }
  }
}

- (void)traverseTextNode:(xmlNodePtr)node {
  if (!node->content)
    return;

  NSString *text = [NSString stringWithUTF8String:(const char *)node->content];
  if (!text)
    return;

  // Collapse whitespace
  NSString *collapsed = collapseWhiteSpaceIfNeeded(text);
  if (collapsed.length == 0)
    return;

  // Skip leading whitespace-only content
  if (_result.length == 0 && isWhiteSpaceOnly(collapsed))
    return;

  // Trim leading space if needed
  if ([self shouldTrimLeadingSpaceForText:collapsed]) {
    collapsed = [collapsed substringFromIndex:1];
  }

  [self appendText:collapsed];
}

- (void)appendEmptyLine {
  [self appendText:@"\n"];
}

- (void)appendText:(NSString *)text {
  NSUInteger start = _result.length;

  [_result appendAttributedString:[[NSAttributedString alloc]
                                      initWithString:text
                                          attributes:_defaultTypingAttributes]];

  NSRange range = NSMakeRange(start, text.length);

  [_styleStack applyStylesToAttributedString:_result range:range];
}

- (void)traverseSelfClosing:(id<BaseStyleProtocol>)style
                 attributes:(NSDictionary *)attributes
                        tag:(NSString *)tag {
  if ([tag isEqualToString:@"br"]) {
    [self appendEmptyLine];
    return;
  }
  BOOL isParagraph = [style.class isParagraphStyle];

  if (isParagraph && _result.length > 0) {
    unichar last = [[_result string] characterAtIndex:_result.length - 1];
    if (last != '\n') {
      [self appendEmptyLine];
    }
  }

  unichar rep = 0xFFFC;
  NSString *placeholder = [NSString stringWithCharacters:&rep length:1];

  NSUInteger start = _result.length;
  [_result appendAttributedString:[[NSAttributedString alloc]
                                      initWithString:placeholder
                                          attributes:_defaultTypingAttributes]];

  NSRange r = NSMakeRange(start, 1);

  [style addAttributesInAttributedString:_result range:r attributes:attributes];
  if (isParagraph) {
    [self appendEmptyLine];
  }
}

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
  if (_result.length == 0)
    return NO;

  if (![text hasPrefix:@" "])
    return NO;

  unichar last = [[_result string] characterAtIndex:_result.length - 1];

  return [[NSCharacterSet whitespaceAndNewlineCharacterSet]
      characterIsMember:last];
}

- (void)appendEmptyBlockPlaceholder {
  NSString *placeholder = @"\u200B";
  [self appendText:placeholder];
}

- (void)applyParagraphModifiersIfNeeded:(NSDictionary *)attributes {
  if (_result.length == 0 || attributes.count == 0)
    return;

  NSRange paragraphRange = [_result.string
      paragraphRangeForRange:NSMakeRange(MAX((NSInteger)_result.length - 1, 0),
                                         0)];

  for (id<BaseStyleProtocol> modifier in _paragraphModifiers) {
    [modifier addAttributesInAttributedString:_result
                                        range:paragraphRange
                                   attributes:attributes];
  }
}

@end
