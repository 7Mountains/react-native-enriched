#pragma once

#import "EnrichedBorderStyle.h"

@interface RichImageLabelView : UIView

// container
@property(nonatomic) CGFloat minHeight;
@property(nonatomic) UIEdgeInsets padding;
@property(nonatomic) CGFloat cornerRadius;
@property(nonatomic, strong) UIColor *containerBackgroundColor;
@property(nonatomic, strong) UIColor *containerBorderColor;
@property(nonatomic) CGFloat containerBorderWidth;
@property(nonatomic) CGFloat containerCornerRadius;
@property(nonatomic) EnrichedBorderStyle borderStyle;

// text container
@property(nonatomic) UIEdgeInsets textPadding;
@property(nonatomic) UIEdgeInsets textMargin;

// border left layer
@property(nonatomic, assign) CGFloat borderLeftWidth;
@property(nonatomic, strong) UIColor *borderLeftColor;

// image container
@property(nonatomic) CGSize imageContainerSize;
@property(nonatomic, strong) UIColor *imageContainerColor;
@property(nonatomic) CGFloat imageContainerCornerRadius;

// image
@property(nonatomic, strong) UIImage *image;
@property(nonatomic) CGSize imageSize;
@property(nonatomic) UIViewContentMode imageContentMode;

// title
@property(nonatomic, strong) NSAttributedString *titleText;

// description
@property(nonatomic, strong) NSAttributedString *descriptionText;

@property(nonatomic, strong) NSAttributedString *subTitleText;

@property(nonatomic, strong) NSAttributedString *subDescriptionText;

@end
