#pragma once
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

namespace facebook::react {
struct EnrichedTextInputViewHtmlStyleMdfStruct;
}

@interface MDFStyleProps : NSObject <NSCopying>

- (instancetype _Nonnull)initWithStruct:
    (const facebook::react::EnrichedTextInputViewHtmlStyleMdfStruct &)mdf;

@property(nonatomic, readonly) CGFloat height;
@property(nonatomic, copy, readonly) NSString *_Nullable imageUri;

@property(nonatomic, readonly) CGFloat borderRadius;
@property(nonatomic, readonly) CGFloat borderWidth;

@property(nonatomic, readonly) CGFloat stripeWidth;

@property(nonatomic, strong, nullable, readonly) UIColor *borderColor;

@property(nonatomic, readonly, nonnull) UIFont *font;

@property(nonatomic, readonly) CGFloat marginLeft;
@property(nonatomic, readonly) CGFloat marginRight;
@property(nonatomic, readonly) CGFloat marginTop;
@property(nonatomic, readonly) CGFloat marginBottom;

@property(nonatomic, readonly) CGFloat paddingLeft;
@property(nonatomic, readonly) CGFloat paddingRight;
@property(nonatomic, readonly) CGFloat paddingTop;
@property(nonatomic, readonly) CGFloat paddingBottom;

@property(nonatomic, strong, nullable, readonly) UIColor *textColor;
@property(nonatomic, strong, nullable, readonly) UIColor *backgroundColor;

@property(nonatomic, readonly) CGFloat imageWidth;
@property(nonatomic, readonly) CGFloat imageHeight;

@property(nonatomic, readonly) CGFloat imageBorderRadius;

@property(nonatomic, readonly) CGFloat imageContainerWidth;
@property(nonatomic, readonly) CGFloat imageContainerHeight;

@end
