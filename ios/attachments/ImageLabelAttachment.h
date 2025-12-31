#import "BaseLabelAttachment.h"

@class ContentParams, ContentStyleProps;

@interface ImageLabelAttachment : MediaAttachment

- (instancetype)initWithParams:(ContentParams *)params
                        styles:(ContentStyleProps *)styles;

@end
