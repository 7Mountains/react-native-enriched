#pragma once
#import "EnrichedBorderStyle.h"
#import <UIKit/UIKit.h>
#import <folly/dynamic.h>

typedef NS_ENUM(NSInteger, ContentImageResizeMode) {
  ContentImageResizeModeCover,
  ContentImageResizeModeContain,
  ContentImageResizeModeStretch,
};

@interface ContentStyleProps : NSObject

@property(nonatomic, strong) UIColor *backgroundColor;
@property(nonatomic, strong) UIColor *textColor;
@property(nonatomic, strong) UIColor *borderColor;

@property(nonatomic) CGFloat borderWidth;
@property(nonatomic) CGFloat borderRadius;
@property(nonatomic) EnrichedBorderStyle borderStyle;

@property(nonatomic) UIEdgeInsets padding;
@property(nonatomic) UIEdgeInsets margin;

@property(nonatomic) UIEdgeInsets textContainerPadding;
@property(nonatomic) UIEdgeInsets textContainerMargin;

@property(nonatomic) CGSize imageSize;
@property(nonatomic) CGSize imageContainerSize;
@property(nonatomic) ContentImageResizeMode imageResizeMode;

@property(nonatomic, strong) UIFont *titleFont;
@property(nonatomic, strong) UIColor *titleColor;
@property(nonatomic) UIEdgeInsets titleMargin;

@property(nonatomic, strong) UIFont *descriptionFont;
@property(nonatomic, strong) UIColor *descriptionColor;
@property(nonatomic) UIEdgeInsets descriptionMargin;

@property(nonatomic, strong) UIFont *subTitleFont;
@property(nonatomic, strong) UIColor *subTitleColor;
@property(nonatomic) UIEdgeInsets subtitleMargin;

@property(nonatomic, strong) UIFont *subDescriptionFont;
@property(nonatomic, strong) UIColor *subdescriptionColor;
@property(nonatomic) UIEdgeInsets subdescriptionMargin;

@property(nonatomic) CGFloat minHeight;

@property(nonatomic, strong) NSURL *fallbackImageURL;

+ (instancetype)styleFromDynamic:(folly::dynamic)dynamic
                     defaultFont:(UIFont *)defaultFont;

+ (NSDictionary<NSString *, ContentStyleProps *> *)
    singleStylesFromDynamic:(folly::dynamic)dynamic
                defaultFont:(UIFont *)defaultFont;

+ (NSDictionary<NSString *, ContentStyleProps *> *)
    stylesFromDynamicMap:(folly::dynamic)dynamic
             defaultFont:(UIFont *)defaultFont;

@end
