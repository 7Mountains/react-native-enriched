#pragma once
#import <Foundation/Foundation.h>

@protocol EnrichedStyleHost;

@interface EnrichedTextStyleFactory : NSObject

+ (NSDictionary<NSNumber *, id> *)makeStylesWithInput:
    (id<EnrichedStyleHost>)input;
+ (NSDictionary<NSNumber *, NSArray<NSNumber *> *> *)makeConflictingStyles;
+ (NSDictionary<NSNumber *, NSArray<NSNumber *> *> *)makeBlockingStyles;
+ (NSDictionary<NSNumber *, id> *)
    filterStyles:(NSDictionary<NSNumber *, id> *)allowedStyles
           names:(NSArray<NSString *> *)names;

@end
