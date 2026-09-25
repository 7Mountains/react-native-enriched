#pragma once
#import <Foundation/Foundation.h>

static const NSInteger EnrichedMaxLengthUnlimited = -1;

@interface EnrichedMaxLengthUtils : NSObject
+ (NSInteger)plainLengthOf:(NSString *_Nonnull)text;
+ (NSInteger)capacityForText:(NSString *_Nonnull)text
              replacingRange:(NSRange)range
                   maxLength:(NSInteger)maxLength;
+ (NSUInteger)cutIndexIn:(NSString *_Nonnull)text capacity:(NSInteger)capacity;
+ (NSString *_Nonnull)truncate:(NSString *_Nonnull)text
                    toCapacity:(NSInteger)capacity;
@end
