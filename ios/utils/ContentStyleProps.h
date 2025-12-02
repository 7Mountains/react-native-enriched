#pragma once
#import <UIKit/UIKit.h>
#import <folly/dynamic.h>

@interface ContentStyleProps : NSObject

@property UIColor *backgroundColor;
@property UIColor *borderColor;
@property CGFloat borderWidth;
@property NSString *borderStyle;
@property CGFloat borderRadius;
@property UIColor *textColor;
@property CGFloat paddingTop;
@property CGFloat paddingBottom;
@property CGFloat paddingRight;
@property CGFloat paddingLeft;
@property CGFloat marginTop;
@property CGFloat marginBottom;
@property CGFloat marginRight;
@property CGFloat marginLeft;

+ (ContentStyleProps *)fromFolly:(folly::dynamic)folly;
+ (NSDictionary *)getSinglePropsFromFollyDynamic:(folly::dynamic)folly;
+ (NSDictionary *)getComplexPropsFromFollyDynamic:(folly::dynamic)folly;

@end
