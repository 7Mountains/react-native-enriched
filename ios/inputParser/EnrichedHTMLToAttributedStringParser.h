#pragma once
#import "StyleHeaders.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface EnrichedHTMLToAttributedStringParser : NSObject

@property(nonatomic, strong, readonly) NSMutableAttributedString *result;
@property(nonatomic, strong)
    NSDictionary<NSString *, id<BaseStyleProtocol>> *tagsRegistry;

@property(nonatomic, strong)
    NSDictionary<NSAttributedStringKey, id> *defaultTypingAttributes;

- (instancetype)initWithStyles:
                    (NSDictionary<NSNumber *, id<BaseStyleProtocol>> *)
                        stylesDict
             defaultAttributes:(NSDictionary *)defaultAttributes;

- (NSMutableAttributedString *)parseToAttributedString:(NSString *)html;

@end
