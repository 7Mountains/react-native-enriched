#pragma once
#import "BaseImageAttachment.h"
#import <UIKit/UIKit.h>

@class MDFParams, MDFStyleProps;

@interface MDFAttachment : BaseImageAttachment
- (instancetype)initWithParams:(MDFParams *)params
                        styles:(MDFStyleProps *)styles;
@end
