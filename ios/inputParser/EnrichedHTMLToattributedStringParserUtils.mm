#import "EnrichedHTMLToAttributedStringParserUtils.h"
#import "BaseStyleProtocol.h"

NSDictionary<NSString *, NSString *> *
HTMLAttributesFromNodeAndParents(xmlNodePtr node) {
  if (!node)
    return nullptr;

  NSMutableDictionary *result = [NSMutableDictionary dictionary];

  for (xmlNodePtr n = node; n; n = n->parent) {
    if (n->type != XML_ELEMENT_NODE)
      continue;

    for (xmlAttrPtr attr = n->properties; attr; attr = attr->next) {
      if (!attr->children || !attr->children->content)
        continue;

      NSString *key = [NSString stringWithUTF8String:(const char *)attr->name];
      NSString *val =
          [NSString stringWithUTF8String:(const char *)attr->children->content];

      if (key && val && !result[key]) {
        result[key] = val;
      }
    }
  }

  return result;
}

BOOL isTopLevelNode(xmlNodePtr node) {
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

NSSet<NSValue *> *
MakeBlockTags(NSDictionary<NSNumber *, id<BaseStyleProtocol>> *styles) {
  NSMutableSet<NSValue *> *tags = [NSMutableSet set];

  [styles enumerateKeysAndObjectsUsingBlock:^(
              NSNumber *key, id<BaseStyleProtocol> style, BOOL *stop) {
    if (![[style class] isParagraphStyle])
      return;

    const char *tag = [[style class] tagName];
    if (tag) {
      [tags addObject:[NSValue valueWithPointer:(const void *)tag]];
    }

    if ([[style class] respondsToSelector:@selector(subTagName)]) {
      const char *sub = [[style class] subTagName];
      if (sub) {
        [tags addObject:[NSValue valueWithPointer:(const void *)sub]];
      }
    }
  }];

  return tags.copy;
}

const char *const kBlockTags[] = {
    "p",  "ul", "ol", "li",        "blockquote", "h1", "h2",   "h3",
    "h4", "h5", "h6", "checklist", "codeblock",  "hr", nullptr};

bool isBlockTag(const char *tag) {
  if (!tag)
    return false;
  for (int i = 0; kBlockTags[i]; ++i) {
    if (strcmp(kBlockTags[i], tag) == 0)
      return true;
  }
  return false;
}

BOOL isHTMLWhitespace(unsigned char c) {
  return c == ' ' || c == '\n' || c == '\t' || c == '\r' || c == '\f';
}

NSString *collapseWhiteSpace(NSString *text) {
  CFIndex len = CFStringGetLength((CFStringRef)text);
  if (len == 0)
    return text;

  CFMutableStringRef out = CFStringCreateMutable(kCFAllocatorDefault, len);

  CFStringInlineBuffer buffer;
  CFStringInitInlineBuffer((CFStringRef)text, &buffer, CFRangeMake(0, len));

  BOOL lastWasWhitespace = NO;

  for (CFIndex i = 0; i < len; i++) {
    unichar c = CFStringGetCharacterFromInlineBuffer(&buffer, i);

    BOOL isWhitespace = (c == ' ' || c == '\n' || c == '\t' || c == '\r' ||
                         c == '\f' || c == 0x00A0);

    if (isWhitespace) {
      if (!lastWasWhitespace) {
        UniChar space = ' ';
        CFStringAppendCharacters(out, &space, 1);
        lastWasWhitespace = YES;
      }
    } else {
      CFStringAppendCharacters(out, &c, 1);
      lastWasWhitespace = NO;
    }
  }

  return CFBridgingRelease(out);
}

NSString *collapseWhiteSpaceIfNeeded(NSString *text) {
  if (text.length == 0)
    return text;

  static NSCharacterSet *ws;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    ws = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  });

  if ([text rangeOfCharacterFromSet:ws].location == NSNotFound)
    return text;

  return collapseWhiteSpace(text);
}

BOOL isWhiteSpaceOnly(NSString *text) {
  NSCharacterSet *ws = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  for (NSUInteger i = 0; i < text.length; i++) {
    if (![ws characterIsMember:[text characterAtIndex:i]]) {
      return NO;
    }
  }
  return YES;
}

BOOL HTMLIsLastParagraphInBlockContext(xmlNodePtr node, const xmlChar *tag,
                                       const xmlChar *parentTag, BOOL isLast) {
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

BOOL xmlTextNodeHasRenderableContent(xmlNodePtr node) {
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

xmlNodePtr nextRenderableSibling(xmlNodePtr node) {
  for (xmlNodePtr next = node->next; next; next = next->next) {
    if (next->type == XML_ELEMENT_NODE)
      return next;

    if (xmlTextNodeHasRenderableContent(next))
      return next;
  }
  return NULL;
}

bool isBrTag(const char *tagName) {
  return tagName && tagName[0] == 'b' && tagName[1] == 'r' &&
         tagName[2] == '\0';
}
