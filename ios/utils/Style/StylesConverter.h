#pragma once
#import "StyleTypeEnum.h"

@interface StylesConverter : NSObject

+ (StyleType)styleTypeFromString:(NSString *)type;

+ (NSString *)styleNameFromType:(StyleType)type;

@end
