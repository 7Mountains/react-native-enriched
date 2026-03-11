#pragma once
#import <UIKit/UIKit.h>

@interface MDFParams : NSObject

+ (nullable instancetype)fromdDictionary:
    (NSDictionary<NSString *, NSString *> *_Nullable)dictionary;

@property(nonatomic, strong, nonnull) NSString *label;
@property(nonatomic, strong, nonnull) NSString *identification;
@property(nonatomic, strong, nonnull) NSString *tintColor;
@property(nonatomic, strong, nullable)
    NSDictionary<NSString *, id> *extraAttributes;

- (NSDictionary<NSString *, NSString *> *_Nonnull)toDictionary;

@end
