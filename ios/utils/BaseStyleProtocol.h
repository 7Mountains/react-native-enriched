#pragma once
#import "StylePair.h"
#import "StyleTypeEnum.h"

@protocol BaseStyleProtocol <NSObject>
+ (StyleType)getStyleType;
+ (BOOL)isParagraphStyle;
+ (const char *_Nonnull)tagName;
+ (const char *_Nullable)subTagName;
+ (NSAttributedStringKey _Nonnull)attributeKey;
+ (BOOL)isSelfClosing;
- (BOOL)styleCondition:(id _Nullable)value range:(NSRange)range;
- (instancetype _Nonnull)initWithInput:(id _Nonnull)input;
- (void)applyStyle:(NSRange)range;
- (void)addAttributes:(NSRange)range;
- (void)
    addAttributesInAttributedString:(NSMutableAttributedString *_Nonnull)string
                              range:(NSRange)range
                         attributes:
                             (NSDictionary<NSString *, NSString *> *_Nullable)
                                 attributes;
- (void)removeAttributes:(NSRange)range;
- (void)addTypingAttributes;
- (void)removeTypingAttributes;
- (BOOL)detectStyle:(NSRange)range;
- (BOOL)anyOccurence:(NSRange)range;
- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range;
@end
