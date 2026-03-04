#pragma once
#import "BaseImageAttachment.h"

@class ContentParams, ContentStyleProps;

@interface ImageLabelAttachment : BaseImageAttachment

- (instancetype)initWithParams:(ContentParams *)params
                        styles:(ContentStyleProps *)styles;

@end
