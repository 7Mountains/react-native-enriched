#pragma once
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

namespace facebook::react {
struct EnrichedTextInputViewHtmlStyleMdfStruct;
}

@interface MDFStyleProps : NSObject <NSCopying>

- (instancetype _Nonnull)initWithStruct:
    (const facebook::react::EnrichedTextInputViewHtmlStyleMdfStruct &)mdf;

@property(nonatomic, readonly) CGFloat minHeight;

@property(nonatomic, readonly) CGFloat borderRadius;
@property(nonatomic, readonly) CGFloat borderWidth;

@property(nonatomic, readonly) CGFloat borderLeftWidth;

@property(nonatomic, strong, nullable, readonly) UIColor *borderColor;

@property(nonatomic, readonly, nonnull) UIFont *font;

@property(nonatomic, readonly) UIEdgeInsets margin;
@property(nonatomic, readonly) UIEdgeInsets padding;

@property(nonatomic, strong, nullable, readonly) UIColor *textColor;
@property(nonatomic, strong, nullable, readonly) UIColor *backgroundColor;

@property(nonatomic, readonly) CGSize imageSize;

@property(nonatomic, readonly) CGSize imageContainerSize;
@property(nonatomic, readonly) CGFloat imageContainerBorderRadius;

@property(nonatomic, readonly) UIEdgeInsets textContainerMargin;
@property(nonatomic, readonly) UIEdgeInsets textContainerPadding;

@property(nonatomic, strong, readonly, nonnull) NSURL *imageURL;

@end
