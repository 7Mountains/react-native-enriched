#pragma once
#import <UIKit/UIKit.h>

@interface ContentParams : NSObject
+ (nullable instancetype)paramsFromArgs:(NSArray *_Nonnull)args;
@property(nonatomic, strong, nullable) NSString *type;
@property(nonatomic, strong, nullable) NSString *text;
@property(nonatomic, strong, nullable) NSString *url;
@property(nonatomic, strong, nullable) NSDictionary<NSString *, id> *attributes;
@end
