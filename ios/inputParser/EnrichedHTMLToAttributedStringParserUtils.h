#import <Foundation/Foundation.h>
#import <libxml/tree.h>

NS_ASSUME_NONNULL_BEGIN

static inline NSDictionary<NSString *, NSString *> *
HTMLAttributesFromNode(xmlNodePtr node) {
  if (!node || !node->properties)
    return @{};

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

static inline BOOL isTopLevelNode(xmlNodePtr node) {
  if (!node || !node->parent)
    return NO;

  if (node->parent->type == XML_DOCUMENT_NODE)
    return YES;

  const xmlChar *parentName = node->parent->name;
  if (!parentName)
    return NO;

  return xmlStrEqual(parentName, BAD_CAST "html") ||
         xmlStrEqual(parentName, BAD_CAST "body");
}

static inline NSSet<NSValue *> *
MakeBlockTags(NSDictionary<NSNumber *, id<BaseStyleProtocol>> *styles) {
  NSMutableSet<NSValue *> *tags = [NSMutableSet set];

  [styles enumerateKeysAndObjectsUsingBlock:^(
              NSNumber *key, id<BaseStyleProtocol> style, BOOL *stop) {
    if (![[style class] isParagraphStyle])
      return;

    // tagName (container or paragraph)
    const char *tag = [[style class] tagName];
    if (tag) {
      [tags addObject:[NSValue valueWithPointer:(const void *)tag]];
    }

    // subTagName (paragraph inside container)
    if ([[style class] respondsToSelector:@selector(subTagName)]) {
      const char *sub = [[style class] subTagName];
      if (sub) {
        [tags addObject:[NSValue valueWithPointer:(const void *)sub]];
      }
    }
  }];

  return tags.copy;
}

static inline BOOL isBlockTag(NSString *tag) {
  static NSSet<NSString *> *blockTags;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    blockTags = [NSSet setWithArray:@[
      @"p", @"div", @"ul", @"ol", @"li", @"h1", @"h2", @"h3", @"h4", @"h5",
      @"h6", @"blockquote", @"checklist", @"codeblock", @"hr"
    ]];
  });

  return [blockTags containsObject:tag];
}

static inline BOOL isHTMLWhitespace(unsigned char c) {
  return c == ' ' || c == '\n' || c == '\t' || c == '\r' || c == '\f';
}

static inline NSString *collapseWhiteSpace(NSString *text) {
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

static inline BOOL isWhiteSpaceOnly(NSString *text) {
  NSCharacterSet *ws = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  for (NSUInteger i = 0; i < text.length; i++) {
    if (![ws characterIsMember:[text characterAtIndex:i]]) {
      return NO;
    }
  }
  return YES;
}

static inline BOOL HTMLIsLastParagraphInBlockContext(xmlNodePtr node,
                                                     const xmlChar *tag,
                                                     const xmlChar *parentTag,
                                                     BOOL isLast) {
  if (!isLast || !tag || !parentTag)
    return NO;

  if (xmlStrEqual(tag, BAD_CAST "p")) {
    return xmlStrEqual(parentTag, BAD_CAST "blockquote") ||
           xmlStrEqual(parentTag, BAD_CAST "codeblock");
  }

  if (xmlStrEqual(tag, BAD_CAST "li")) {
    return xmlStrEqual(parentTag, BAD_CAST "ol") ||
           xmlStrEqual(parentTag, BAD_CAST "ul");
  }

  return NO;
}

static inline BOOL xmlTextNodeHasRenderableContent(xmlNodePtr node) {
  if (!node || node->type != XML_TEXT_NODE || !node->content)
    return NO;

  const xmlChar *c = node->content;
  for (; *c; c++) {
    switch (*c) {
    case ' ':
    case '\n':
    case '\t':
    case '\r':
    case '\f':
      continue;
    default:
      return YES;
    }
  }
  return NO;
}

static inline xmlNodePtr __nullable nextRenderableSibling(xmlNodePtr node) {
  for (xmlNodePtr next = node->next; next; next = next->next) {
    if (next->type == XML_ELEMENT_NODE)
      return next;

    if (xmlTextNodeHasRenderableContent(next))
      return next;
  }
  return NULL;
}

NS_ASSUME_NONNULL_END
