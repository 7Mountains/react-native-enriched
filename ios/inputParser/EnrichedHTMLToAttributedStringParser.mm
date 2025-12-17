#import "EnrichedHTMLToAttributedStringParser.h"
#import <libxml/HTMLparser.h>
#import <libxml/tree.h>

#pragma mark - ActiveStyle

@interface ActiveStyle : NSObject
@property(nonatomic, strong) id<BaseStyleProtocol> style;
@property(nonatomic, strong) NSDictionary<NSString *, NSString *> *attributes;
@end

@implementation ActiveStyle
@end

#pragma mark - Parser
@implementation EnrichedHTMLToAttributedStringParser {
  NSMutableAttributedString *_result;
  NSMutableArray<ActiveStyle *> *_activeStyles;
}

#pragma mark - Init

- (instancetype)initWithStyles:
                    (NSDictionary<NSNumber *, id<BaseStyleProtocol>> *)styles
             defaultAttributes:
                 (NSDictionary<NSAttributedStringKey, id> *)defaultAttributes {
  if (!(self = [super init]))
    return nil;

  _defaultTypingAttributes = defaultAttributes ?: @{};
  _activeStyles = [NSMutableArray new];

  NSMutableDictionary *tags = [NSMutableDictionary dictionary];

  [styles enumerateKeysAndObjectsUsingBlock:^(
              NSNumber *key, id<BaseStyleProtocol> style, BOOL *stop) {
    NSString *tag = [[NSString stringWithUTF8String:[[style class] tagName]]
        lowercaseString];
    tags[tag] = style;
  }];

  _tagRegistry = tags.copy;
  return self;
}

#pragma mark - Public API

- (NSMutableAttributedString *)parseToAttributedString:(NSString *)html {
  _result = [[NSMutableAttributedString alloc]
      initWithString:@""
          attributes:_defaultTypingAttributes];
  [_result beginEditing];
  const char *cHtml = html.UTF8String ?: "";

  htmlDocPtr doc = htmlReadMemory(cHtml, (int)strlen(cHtml), NULL, "UTF-8",
                                  HTML_PARSE_NOERROR | HTML_PARSE_NOWARNING |
                                      HTML_PARSE_RECOVER);

  if (!doc)
    return _result;

  xmlNodePtr root = xmlDocGetRootElement(doc);
  if (root) {
    [self traverseChildren:root];
  }

  xmlFreeDoc(doc);
  [_result endEditing];
  return _result;
}

#pragma mark - Traversal

- (void)traverseChildren:(xmlNodePtr)parent {
  for (xmlNodePtr cur = parent->children; cur; cur = cur->next) {

    xmlNodePtr nextRenderable = [self nextRenderableSibling:cur];
    BOOL isLastRenderable = (nextRenderable == NULL);

    [self traverseNode:cur isLastRenderable:isLastRenderable];
  }
}

- (void)traverseNode:(xmlNodePtr)cur isLastRenderable:(BOOL)isLastRenderable {
  if (cur->type == XML_TEXT_NODE) {
    [self handleTextNode:cur];
    return;
  }

  if (cur->type != XML_ELEMENT_NODE) {
    return;
  }

  NSString *tag = cur->name
                      ? [NSString stringWithUTF8String:(const char *)cur->name]
                            .lowercaseString
                      : @"";

  NSString *parentTag =
      (cur->parent && cur->parent->name)
          ? [NSString stringWithUTF8String:(const char *)cur->parent->name]
                .lowercaseString
          : @"";

  id<BaseStyleProtocol> style = self.tagRegistry[tag];
  BOOL isSelfClosing = style && [[style class] isSelfClosing];
  NSDictionary *attributes = [self attributesFromNode:cur];

  if (style) {
    if (isSelfClosing) {
      [self emitSelfClosing:style attributes:attributes tag:tag];
      return;
    } else {
      [self pushStyle:style attributes:attributes];
    }
  }

  if (cur->children) {
    [self traverseChildren:cur];
  }

  if (style && !isSelfClosing) {
    [self popStyle:style];
  }

  if ([self isTopLevelNode:cur] && isLastRenderable) {
    return;
  }

  if ([self isBlockTag:tag] &&
      ![self isLastParagraphInBlockContext:cur
                                       tag:tag
                                 parentTag:parentTag
                                    isLast:isLastRenderable]) {
    [self appendText:@"\n"];
  }
}

- (NSString *)collapseHTMLWhitespace:(NSString *)text {
  if (text.length == 0)
    return text;

  NSMutableString *out = [NSMutableString stringWithCapacity:text.length];

  BOOL lastWasWhitespace = NO;

  NSUInteger len = text.length;
  for (NSUInteger i = 0; i < len; i++) {
    unichar c = [text characterAtIndex:i];

    BOOL isWhitespace = (c == ' ' || c == '\n' || c == '\t' || c == '\r' ||
                         c == '\f' || c == 0x00A0);

    if (isWhitespace) {
      if (!lastWasWhitespace) {
        [out appendString:@" "];
        lastWasWhitespace = YES;
      }
    } else {
      [out appendFormat:@"%C", c];
      lastWasWhitespace = NO;
    }
  }

  return out;
}

#pragma mark - Text

- (void)handleTextNode:(xmlNodePtr)node {
  if (!node->content)
    return;

  NSString *text = [NSString stringWithUTF8String:(const char *)node->content];
  if (!text)
    return;

  NSString *collapsed = [self collapseHTMLWhitespace:text];
  if (collapsed.length == 0)
    return;

  if (_result.length == 0) {
    NSCharacterSet *ws = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    BOOL onlyWhitespace = YES;

    for (NSUInteger i = 0; i < collapsed.length; i++) {
      if (![ws characterIsMember:[collapsed characterAtIndex:i]]) {
        onlyWhitespace = NO;
        break;
      }
    }

    if (onlyWhitespace) {
      return;
    }
  }

  if (_result.length > 0) {
    unichar lastChar = [[_result string] characterAtIndex:_result.length - 1];
    if ([[NSCharacterSet whitespaceAndNewlineCharacterSet]
            characterIsMember:lastChar] &&
        [collapsed hasPrefix:@" "]) {
      collapsed = [collapsed substringFromIndex:1];
    }
  }

  [self appendText:collapsed];
}

#pragma mark - Style Stack

- (void)pushStyle:(id<BaseStyleProtocol>)style
       attributes:(NSDictionary *)attributes {
  ActiveStyle *a = [ActiveStyle new];
  a.style = style;
  a.attributes = attributes ?: @{};
  [_activeStyles addObject:a];
}

- (void)popStyle:(id<BaseStyleProtocol>)style {
  for (NSInteger i = _activeStyles.count - 1; i >= 0; i--) {
    if (_activeStyles[i].style == style) {
      [_activeStyles removeObjectAtIndex:i];
      return;
    }
  }
}

#pragma mark - Output

- (void)appendText:(NSString *)text {
  NSUInteger start = _result.length;

  [_result appendAttributedString:[[NSAttributedString alloc]
                                      initWithString:text
                                          attributes:_defaultTypingAttributes]];

  NSRange range = NSMakeRange(start, text.length);

  for (ActiveStyle *a in _activeStyles) {
    [a.style addAttributesInAttributedString:_result
                                       range:range
                                  attributes:a.attributes];
  }
}

- (void)emitSelfClosing:(id<BaseStyleProtocol>)style
             attributes:(NSDictionary *)attributes
                    tag:(NSString *)tag {
  if ([tag isEqualToString:@"br"]) {
    [self appendText:@"\n"];
    return;
  }
  BOOL isParagraph = [style.class isParagraphStyle];

  if (isParagraph && _result.length > 0) {
    unichar last = [[_result string] characterAtIndex:_result.length - 1];
    if (last != '\n') {
      [self appendText:@"\n"];
    }
  }

  unichar rep = 0xFFFC;
  NSString *placeholder = [NSString stringWithCharacters:&rep length:1];

  NSUInteger start = _result.length;
  [_result appendAttributedString:[[NSAttributedString alloc]
                                      initWithString:placeholder
                                          attributes:_defaultTypingAttributes]];

  NSRange r = NSMakeRange(start, 1);

  for (ActiveStyle *activeStyle in _activeStyles) {
    [activeStyle.style addAttributesInAttributedString:_result
                                                 range:r
                                            attributes:activeStyle.attributes];
  }

  [style addAttributesInAttributedString:_result range:r attributes:attributes];
  if (isParagraph) {
    [self appendText:@"\n"];
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

- (NSDictionary *)attributesFromNode:(xmlNodePtr)node {
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];

  for (xmlAttrPtr attr = node->properties; attr; attr = attr->next) {
    if (!attr->children || !attr->children->content)
      continue;

    NSString *key = [NSString stringWithUTF8String:(const char *)attr->name];
    NSString *val =
        [NSString stringWithUTF8String:(const char *)attr->children->content];

    if (key && val)
      dict[key] = val;
  }

  return dict;
}

- (BOOL)isBlockTag:(NSString *)tag {
  static NSSet *blockTags;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    blockTags = [NSSet setWithArray:@[
      @"p", @"div", @"ul", @"ol", @"li", @"h1", @"h2", @"h3", @"h4", @"h5",
      @"h6", @"blockquote", @"checklist", @"codeblock", @"hr"
    ]];
  });

  return [blockTags containsObject:tag];
}

- (BOOL)isLastParagraphInBlockContext:(xmlNodePtr)node
                                  tag:(NSString *)tag
                            parentTag:(NSString *)parentTag
                               isLast:(BOOL)isLast {
  if (!isLast)
    return NO;

  if ([tag isEqualToString:@"p"]) {
    return [parentTag isEqualToString:@"blockquote"] ||
           [parentTag isEqualToString:@"codeblock"];
  }

  if ([tag isEqualToString:@"li"]) {
    return
        [parentTag isEqualToString:@"ol"] || [parentTag isEqualToString:@"ul"];
  }

  return NO;
}

- (BOOL)isTopLevelNode:(xmlNodePtr)node {
  if (!node || !node->parent)
    return NO;

  if (node->parent->type == XML_DOCUMENT_NODE)
    return YES;

  NSString *parent =
      node->parent->name
          ? [NSString stringWithUTF8String:(const char *)node->parent->name]
                .lowercaseString
          : @"";

  return [parent isEqualToString:@"html"] || [parent isEqualToString:@"body"];
}

@end
