#pragma once
#import "StyleHeaders.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface EnrichedHTMLToAttributedStringParser : NSObject <NSXMLParserDelegate>

@property(nonatomic, strong, readonly) NSMutableAttributedString *result;

@property(nonatomic, strong) NSMutableArray *stack;

@property(nonatomic, strong)
    NSDictionary<NSString *, id<BaseStyleProtocol>> *tagRegistry;

@property(nonatomic, strong)
    NSDictionary<NSNumber *, id<BaseStyleProtocol>> *stylesDict;

@property(nonatomic, strong)
    NSDictionary<NSAttributedStringKey, id> *defaultTypingAttributes;
@property(nonatomic, strong) NSMutableArray<NSString *> *tagStack;
@property(nonatomic, copy) NSString *parentTag;

- (instancetype)initWithStyles:
                    (NSDictionary<NSNumber *, id<BaseStyleProtocol>> *)
                        stylesDict
             defaultAttributes:(NSDictionary *)defaultAttributes;

- (NSMutableAttributedString *)parseToAttributedString:(NSString *)html;

@end
