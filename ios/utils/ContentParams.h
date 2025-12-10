#pragma once
#import <UIKit/UIKit.h>

@interface ContentParams : NSObject

@property NSString *type;
@property NSString *text;
@property NSString *url;
@property NSDictionary<NSString *, NSString *> *headers;
@property NSString *attributes;

+ (NSDictionary<NSString *, NSString *> *)parseHeaderFromString:
    (NSString *)headerString;

@end
