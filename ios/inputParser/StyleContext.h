#pragma once

#import <Foundation/Foundation.h>

@protocol BaseStyleProtocol;

@interface StyleContext : NSObject
@property(nonatomic, strong) id<BaseStyleProtocol> style;
@property(nonatomic, strong) NSDictionary<NSString *, NSString *> *attributes;
@end
