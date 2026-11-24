#pragma once
#import "BaseStyleProtocol.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// What the html parser finds in its styles: the style of each tag and the
// paragraph modifiers. Built once for the same styles, read on any thread
@interface EnrichedParserStyleRegistry : NSObject

@property(nonatomic, readonly)
    NSArray<id<BaseStyleProtocol>> *paragraphModifiers;

+ (instancetype)registryForStyles:
    (nullable NSDictionary<NSNumber *, id<BaseStyleProtocol>> *)styles;

// Found from the name of an element without making a string of it
- (nullable id<BaseStyleProtocol>)styleForTag:(const char *_Nullable)tag;

@end

NS_ASSUME_NONNULL_END
