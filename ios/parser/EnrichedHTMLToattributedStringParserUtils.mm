#import "EnrichedHTMLToAttributedStringParserUtils.h"
#import "BaseStyleProtocol.h"
#include <vector>

NSDictionary<NSString *, NSString *> *
HTMLAttributesFromNodeAndParents(xmlNodePtr node) {
  if (!node)
    return nullptr;

  BOOL hasAttributes = NO;
  for (xmlNodePtr n = node; n; n = n->parent) {
    if (n->type == XML_ELEMENT_NODE && n->properties) {
      hasAttributes = YES;
      break;
    }
  }
  if (!hasAttributes)
    return @{};

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

inline bool charEqualsIgnoreCase(char actual, char expected) {
  return actual == expected ||
         actual == static_cast<char>(expected - 'a' + 'A');
}

bool isParagraphTag(const char *tagName) {
  return tagName && tagName[1] == '\0' && charEqualsIgnoreCase(tagName[0], 'p');
}

bool isListItemTag(const char *tagName) {
  return tagName && charEqualsIgnoreCase(tagName[0], 'l') &&
         charEqualsIgnoreCase(tagName[1], 'i') && tagName[2] == '\0';
}

bool isCheckListTag(const char *tagName) {
  return tagName && charEqualsIgnoreCase(tagName[0], 'c') &&
         charEqualsIgnoreCase(tagName[1], 'h') &&
         charEqualsIgnoreCase(tagName[2], 'e') &&
         charEqualsIgnoreCase(tagName[3], 'c') &&
         charEqualsIgnoreCase(tagName[4], 'k') &&
         charEqualsIgnoreCase(tagName[5], 'l') &&
         charEqualsIgnoreCase(tagName[6], 'i') &&
         charEqualsIgnoreCase(tagName[7], 's') &&
         charEqualsIgnoreCase(tagName[8], 't') && tagName[9] == '\0';
}

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

static inline BOOL isCollapsibleWhiteSpace(const unsigned char *c) {
  return *c == ' ' || *c == '\n' || *c == '\t' || *c == '\r' || *c == '\f';
}

static inline BOOL isNoBreakSpace(const unsigned char *c) {
  return c[0] == 0xC2 && c[1] == 0xA0;
}

NSString *_Nullable collapsedWhiteSpaceString(const char *utf8,
                                              BOOL dropsLeadingSpace) {
  const unsigned char *src = (const unsigned char *)utf8;

  BOOL needsCollapse = NO;
  BOOL lastWasSpace = NO;
  size_t len = 0;
  for (; src[len]; len++) {
    if (src[len] == ' ') {
      if (lastWasSpace) {
        needsCollapse = YES;
      }
      lastWasSpace = YES;
    } else if (isCollapsibleWhiteSpace(src + len) ||
               isNoBreakSpace(src + len)) {
      needsCollapse = YES;
    } else {
      lastWasSpace = NO;
    }
  }

  if (!needsCollapse)
    return [NSString stringWithUTF8String:dropsLeadingSpace && src[0] == ' '
                                              ? utf8 + 1
                                              : utf8];

  std::vector<char> out(len + 1);
  size_t o = 0;
  lastWasSpace = NO;
  for (size_t i = 0; i < len; i++) {
    BOOL isWhitespace = isCollapsibleWhiteSpace(src + i);
    if (!isWhitespace && isNoBreakSpace(src + i)) {
      isWhitespace = YES;
      i++;
    }

    if (isWhitespace) {
      if (!lastWasSpace) {
        if (!(dropsLeadingSpace && o == 0)) {
          out[o++] = ' ';
        }
        lastWasSpace = YES;
      }
    } else {
      out[o++] = (char)src[i];
      lastWasSpace = NO;
    }
  }
  out[o] = '\0';

  return [NSString stringWithUTF8String:out.data()];
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
