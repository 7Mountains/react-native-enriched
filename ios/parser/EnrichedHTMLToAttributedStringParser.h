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

// The html as UTF-8, read without a copy
- (NSMutableAttributedString *)parseToAttributedStringFromUTF8:
                                   (const char *)html
                                                        length:(size_t)length;

@end
