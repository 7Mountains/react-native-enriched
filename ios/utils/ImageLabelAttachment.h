#import "BaseLabelAttachment.h"

@interface ImageLabelAttachment : BaseLabelAttachment

@property (nonatomic, strong) UIImage *contentImage;
@property (nonatomic) BOOL isLoading;

// layout
@property (nonatomic) CGFloat imageSpacing;
@property (nonatomic) CGFloat imageWidth;
@property (nonatomic) CGFloat imageHeight;
@property (nonatomic, strong) NSString *imageResizeMode;

// corner radii for image
@property (nonatomic) CGFloat imageCornerRadiusTopLeft;
@property (nonatomic) CGFloat imageCornerRadiusTopRight;
@property (nonatomic) CGFloat imageCornerRadiusBottomLeft;
@property (nonatomic) CGFloat imageCornerRadiusBottomRight;

@end
