#import "EnrichedHeadingLevel.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface EnrichedParagraphStyle
    : NSMutableParagraphStyle <NSCopying, NSMutableCopying>

@property(nonatomic) EnrichedHeadingLevel headingLevel;

@end

NS_ASSUME_NONNULL_END
