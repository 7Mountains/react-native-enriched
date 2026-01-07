#import <Foundation/Foundation.h>
#import <libxml/tree.h>

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

NSString *collapseWhiteSpace(NSString *text);

NSString *collapseWhiteSpaceIfNeeded(NSString *text);

BOOL isWhiteSpaceOnly(NSString *text);

BOOL HTMLIsLastParagraphInBlockContext(xmlNodePtr node, const xmlChar *tag,
                                       const xmlChar *parentTag, BOOL isLast);

BOOL xmlTextNodeHasRenderableContent(xmlNodePtr node);

xmlNodePtr _Nullable nextRenderableSibling(xmlNodePtr node);

bool isBrTag(const char *tagName);

NS_ASSUME_NONNULL_END
