#import <UIKit/UIKit.h>

@interface AlignmentConverter : NSObject
+ (NSTextAlignment)alignmentFromString:(NSString *)string;
@end


@implementation AlignmentConverter

+ (NSTextAlignment)alignmentFromString:(NSString *)string {
    if (!string) return NSTextAlignmentNatural;

    NSString *lower = string.lowercaseString;

    if ([lower isEqualToString:@"left"]) {
        return NSTextAlignmentLeft;
    }

    if ([lower isEqualToString:@"right"]) {
        return NSTextAlignmentRight;
    }

    if ([lower isEqualToString:@"center"]) {
        return NSTextAlignmentCenter;
    }

    if ([lower isEqualToString:@"default"]) {
        return NSTextAlignmentNatural;
    }

    return NSTextAlignmentNatural;
}

@end
