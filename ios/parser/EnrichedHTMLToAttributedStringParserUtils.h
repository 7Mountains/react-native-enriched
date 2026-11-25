#pragma once
#import <Foundation/Foundation.h>
#import <libxml/tree.h>

#include <string>

NS_ASSUME_NONNULL_BEGIN

@protocol BaseStyleProtocol;

NSDictionary<NSString *, NSString *> *
HTMLAttributesFromNodeAndParents(xmlNodePtr node);

BOOL isTopLevelNode(xmlNodePtr node);

NSSet<NSValue *> *
MakeBlockTags(NSDictionary<NSNumber *, id<BaseStyleProtocol>> *styles);

extern const char *_Nonnull const kBlockTags[];

bool isBlockTag(const char *tag);

BOOL isHTMLWhitespace(unsigned char c);

// Appends the text with its white space collapsed to single spaces, without
// its leading space when `dropsLeadingSpace`. `buffer` holds the collapsed
// text, reused between the calls. Returns the length appended
NSUInteger appendCollapsedWhiteSpace(NSMutableString *text, const char *utf8,
                                     BOOL dropsLeadingSpace,
                                     std::string &buffer);

BOOL isWhiteSpaceOnly(NSString *text, NSRange range);

BOOL HTMLIsLastParagraphInBlockContext(xmlNodePtr node, const xmlChar *tag,
                                       const xmlChar *parentTag, BOOL isLast);

BOOL xmlTextNodeHasRenderableContent(xmlNodePtr node);

xmlNodePtr _Nullable nextRenderableSibling(xmlNodePtr node);

bool isBrTag(const char *tagName);

bool isParagraphTag(const char *tagName);

bool isListItemTag(const char *tagName);

bool isCheckListTag(const char *tagName);

NS_ASSUME_NONNULL_END
