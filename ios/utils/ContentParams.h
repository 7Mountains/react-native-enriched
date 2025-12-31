#pragma once
#import <UIKit/UIKit.h>

@interface ContentParams : NSObject
@property(nonatomic, strong, nullable) NSString *type;
@property(nonatomic, strong, nullable) NSString *text;
@property(nonatomic, strong, nullable) NSString *url;
@property(nonatomic, strong, nullable)
    NSDictionary<NSString *, NSString *> *headers;
@property(nonatomic, strong, nullable) NSDictionary<NSString *, id> *attributes;

+ (NSDictionary<NSString *, NSString *> *_Nullable)parseHeaderFromString:
    (NSString *_Nullable)headerString;
@end
