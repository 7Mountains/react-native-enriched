#pragma once
#import "MediaAttachment.h"
#import <UIKit/UIKit.h>

@class MDFParams, MDFStyleProps;

@interface MDFAttachment : MediaAttachment
- (instancetype)initWithParams:(MDFParams *)params
                        styles:(MDFStyleProps *)styles;
@end
