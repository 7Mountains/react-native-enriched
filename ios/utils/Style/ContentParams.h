#pragma once
#import <UIKit/UIKit.h>

@interface ContentParams : NSObject
+ (nullable instancetype)paramsFromArgs:(NSArray *_Nonnull)args;
@property(nonatomic, strong, nullable) NSString *type;
@property(nonatomic, strong, nullable) NSString *title;
@property(nonatomic, strong, nullable) NSString *url;
@property(nonatomic, strong, nullable) NSString *descriptionText;
@property(nonatomic, strong, nullable) NSDictionary<NSString *, id> *attributes;

- (NSDictionary<NSString *, NSString *> *_Nullable)toDictionary;

@end
