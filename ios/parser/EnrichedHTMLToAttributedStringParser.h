#pragma once
#import "StyleHeaders.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface EnrichedHTMLToAttributedStringParser : NSObject
- (instancetype)initWithStyles:
                    (NSDictionary<NSNumber *, id<BaseStyleProtocol>> *)
                        stylesDict
             defaultAttributes:(NSDictionary *)defaultAttributes;

- (NSMutableAttributedString *)parseToAttributedString:(NSString *)html;

@end
