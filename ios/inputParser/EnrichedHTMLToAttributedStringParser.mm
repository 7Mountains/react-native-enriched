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

#pragma mark - StyleRun

@interface StyleRun : NSObject
@property(nonatomic) NSRange range;
@property(nonatomic, strong) id<BaseStyleProtocol> style;
@property(nonatomic, strong) NSDictionary *attributes;
@end

@implementation StyleRun
@end

#pragma mark - Parser

@implementation EnrichedHTMLToAttributedStringParser {
  NSMutableString *_plainText;
  NSMutableArray<StyleRun *> *_runs;
  NSMutableArray<ActiveStyle *> *_activeStyles;
}

#pragma mark - Init

- (instancetype)initWithStyles:
                    (NSDictionary<NSNumber *, id<BaseStyleProtocol>> *)styles
             defaultAttributes:
                 (NSDictionary<NSAttributedStringKey, id> *)defaultAttributes {
  if (!(self = [super init])) {
    return nil;
  }

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
  _plainText = [NSMutableString new];
  _runs = [NSMutableArray new];
  [_activeStyles removeAllObjects];

  const char *cHtml = html.UTF8String ?: "";

  htmlDocPtr doc = htmlReadMemory(cHtml, (int)strlen(cHtml), NULL, "UTF-8",
                                  HTML_PARSE_NOERROR | HTML_PARSE_NOWARNING |
                                      HTML_PARSE_RECOVER);

  if (doc) {
    xmlNodePtr root = xmlDocGetRootElement(doc);
    if (root) {
      [self traverseChildren:root];
    }
    xmlFreeDoc(doc);
  }

  NSMutableAttributedString *result = [[NSMutableAttributedString alloc]
      initWithString:_plainText
          attributes:_defaultTypingAttributes];

  [result beginEditing];
  for (StyleRun *run in _runs) {
    if (run.range.length == 0)
      continue;
    [run.style addAttributesInAttributedString:result
                                         range:run.range
                                    attributes:run.attributes];
  }
  [result endEditing];

  return result;
}

#pragma mark - Traversal

- (void)traverseChildren:(xmlNodePtr)parent {
  for (xmlNodePtr cur = parent->children; cur; cur = cur->next) {
    xmlNodePtr nextRenderable = [self nextRenderableSibling:cur];
    BOOL isLastRenderable = (nextRenderable == NULL);
    [self traverseNode:cur isLastRenderable:isLastRenderable];
  }
}

- (void)traverseNode:(xmlNodePtr)currentNodePointer
    isLastRenderable:(BOOL)isLastRenderable {
  if (currentNodePointer->type == XML_TEXT_NODE) {
    [self handleTextNode:currentNodePointer];
    return;
  }

  if (currentNodePointer->type != XML_ELEMENT_NODE) {
    return;
  }

  NSString *tag =
      currentNodePointer->name
          ? [NSString
                stringWithUTF8String:(const char *)currentNodePointer->name]
                .lowercaseString
          : @"";

  NSString *parentTag =
      (currentNodePointer->parent && currentNodePointer->parent->name)
          ? [NSString
                stringWithUTF8String:(const char *)currentNodePointer->parent->
                                     name]
                .lowercaseString
          : @"";

  id<BaseStyleProtocol> style = self.tagRegistry[tag];
  BOOL isSelfClosing = style && [[style class] isSelfClosing];
  NSDictionary *attributes = [self attributesFromNode:currentNodePointer];

  if (style) {
    if (isSelfClosing) {
      [self emitSelfClosing:style attributes:attributes tag:tag];
      return;
    } else {
      [self pushStyle:style attributes:attributes];
    }
  }

  if (currentNodePointer->children) {
    [self traverseChildren:currentNodePointer];
  }

  if (style && !isSelfClosing) {
    [self popStyle:style];
  }

  if ([self isTopLevelNode:currentNodePointer] && isLastRenderable) {
    return;
  }

  if ([self isBlockTag:tag] &&
      ![self isLastParagraphInBlockContext:currentNodePointer
                                       tag:tag
                                 parentTag:parentTag
                                    isLast:isLastRenderable]) {
    [self appendText:@"\n"];
  }
}

#pragma mark - Text handling

- (void)handleTextNode:(xmlNodePtr)node {
  if (!node->content)
    return;

  NSString *text = [NSString stringWithUTF8String:(const char *)node->content];
  if (!text)
    return;

  NSString *collapsed = [self collapseHTMLWhitespace:text];
  if (collapsed.length == 0)
    return;

  if (_plainText.length == 0) {
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

  if (_plainText.length > 0) {
    unichar last = [_plainText characterAtIndex:_plainText.length - 1];
    if ([[NSCharacterSet whitespaceAndNewlineCharacterSet]
            characterIsMember:last] &&
        [collapsed hasPrefix:@" "]) {
      collapsed = [collapsed substringFromIndex:1];
    }
  }

  [self appendText:collapsed];
}

#pragma mark - Append text / runs

- (void)appendText:(NSString *)text {
  if (text.length == 0)
    return;

  NSUInteger start = _plainText.length;
  [_plainText appendString:text];

  NSRange range = NSMakeRange(start, text.length);

  for (ActiveStyle *a in _activeStyles) {
    StyleRun *run = [StyleRun new];
    run.range = range;
    run.style = a.style;
    run.attributes = a.attributes;
    [_runs addObject:run];
  }
}

- (void)emitSelfClosing:(id<BaseStyleProtocol>)style
             attributes:(NSDictionary *)attributes
                    tag:(NSString *)tag {
  if ([tag isEqualToString:@"br"]) {
    [self appendText:@"\n"];
    return;
  }

  unichar rep = 0xFFFC;
  NSString *ph = [NSString stringWithCharacters:&rep length:1];

  NSUInteger start = _plainText.length;
  [_plainText appendString:ph];

  NSRange r = NSMakeRange(start, 1);

  for (ActiveStyle *a in _activeStyles) {
    StyleRun *run = [StyleRun new];
    run.range = r;
    run.style = a.style;
    run.attributes = a.attributes;
    [_runs addObject:run];
  }

  StyleRun *own = [StyleRun new];
  own.range = r;
  own.style = style;
  own.attributes = attributes ?: nullptr;
  [_runs addObject:own];
}

#pragma mark - Style stack

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

#pragma mark - Helpers (без изменений)

- (NSString *)collapseHTMLWhitespace:(NSString *)text {
  if (text.length == 0)
    return text;

  NSMutableString *out = [NSMutableString stringWithCapacity:text.length];

  BOOL lastWasWhitespace = NO;

  for (NSUInteger i = 0; i < text.length; i++) {
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
      @"h6", @"blockquote", @"checklist", @"codeblock"
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
