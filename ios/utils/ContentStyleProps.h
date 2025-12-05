#pragma once
#import <UIKit/UIKit.h>
#import <folly/dynamic.h>

@interface ContentStyleProps : NSObject

@property UIColor *borderColor;
@property CGFloat borderWidth;
@property NSString *borderStyle;
@property CGFloat borderRadius;
@property CGFloat fontSize;
@property NSString *fontWeight;

@property UIColor *textColor;
@property UIColor *backgroundColor;

@property CGFloat paddingTop;
@property CGFloat paddingBottom;
@property CGFloat paddingRight;
@property CGFloat paddingLeft;

@property CGFloat marginTop;
@property CGFloat marginBottom;
@property CGFloat marginRight;
@property CGFloat marginLeft;

@property (nonatomic) CGFloat imageBorderRadius;
@property (nonatomic) CGFloat imageBorderRadiusTopLeft;
@property (nonatomic) CGFloat imageBorderRadiusTopRight;
@property (nonatomic) CGFloat imageBorderRadiusBottomLeft;
@property (nonatomic) CGFloat imageBorderRadiusBottomRight;
@property (nonatomic) CGFloat imageWidth;
@property (nonatomic) CGFloat imageHeight;
@property (nonatomic) NSString* imageResizeMode;

@property (nonatomic, strong) NSString *fallbackImageURI;

+ (ContentStyleProps *)fromFolly:(folly::dynamic)folly;
+ (NSDictionary *)getSinglePropsFromFollyDynamic:(folly::dynamic)folly;
+ (NSDictionary *)getComplexPropsFromFollyDynamic:(folly::dynamic)folly;

@end
