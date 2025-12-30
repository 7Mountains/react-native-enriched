#pragma once
#import <UIKit/UIKit.h>

@interface MentionParams : NSObject

@property(nonatomic, copy) NSString *_Nonnull text;
@property(nonatomic, copy) NSString *_Nonnull indicator;
@property(nonatomic, copy)
    NSDictionary<NSString *, id> *_Nullable extraAttributes;

+ (nullable instancetype)fromAttributes:
    (NSDictionary<NSString *, id> *_Nullable)attributes;

- (BOOL)isEqualToMentionParams:(MentionParams *)other;

@end
