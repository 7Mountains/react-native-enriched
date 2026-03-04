#import "MDFAttachment.h"
#import "AttachmentUtils.h"
#import "ColorExtension.h"
#import "MDFParams.h"
#import "MDFStyleProps.h"

@implementation MDFAttachment {
  NSAttributedString *_labelText;

  UIColor *_tintColor;
  UIColor *_backgroundColor;
  UIColor *_textColor;

  CGFloat _cornerRadius;
  UIColor *_borderColor;
  CGFloat _borderWidth;

  UIEdgeInsets _margin;
  UIEdgeInsets _inset;

  CGFloat _imageWidth;
  CGFloat _imageHeight;
  CGFloat _imageBorderRadius;

  CGFloat _stripeWidth;

  CGFloat _imageContainerWidth;
  CGFloat _imageContainerHeight;
}

#pragma mark - Init

- (instancetype)initWithParams:(MDFParams *)params
                        styles:(MDFStyleProps *)styles {

  self = [super init];
  if (!self)
    return nil;

  self.height = styles.height + styles.marginTop + styles.marginBottom;

  self.needsRedraw = YES;

  _tintColor = [UIColor colorFromString:params.tintColor];
  _backgroundColor = styles.backgroundColor;
  _textColor = styles.textColor ?: UIColor.labelColor;
  _borderColor = styles.borderColor;
  _borderWidth = styles.borderWidth;

  _cornerRadius = styles.borderRadius;

  _margin = UIEdgeInsetsMake(styles.marginTop, styles.marginLeft,
                             styles.marginBottom, styles.marginRight);

  _inset = UIEdgeInsetsMake(styles.paddingTop, styles.paddingLeft,
                            styles.paddingBottom, styles.paddingRight);

  _imageWidth = styles.imageWidth;
  _imageHeight = styles.imageHeight;
  _imageBorderRadius = styles.imageBorderRadius;

  _stripeWidth = styles.stripeWidth;

  _imageContainerWidth = styles.imageContainerWidth;
  _imageContainerHeight = styles.imageContainerHeight;

  UIFont *font = styles.font ?: [UIFont systemFontOfSize:14];

  _labelText = [[NSAttributedString alloc]
      initWithString:params.label
          attributes:@{
            NSFontAttributeName : font,
            NSForegroundColorAttributeName : _textColor
          }];

  [self loadImageAsyncWithURI:styles.imageUri];

  return self;
}

- (void)drawContentInBounds:(CGRect)bounds context:(CGContextRef)ctx {

  CGRect contentRect = ContentRect(bounds, _margin);
  CGRect innerRect = UIEdgeInsetsInsetRect(contentRect, _inset);

  DrawRoundedBackground(contentRect, _cornerRadius, _backgroundColor);
  [self drawBorderInRect:contentRect context:ctx];

  CGRect imageContainerRect = [self drawImageContainerRectInRect:innerRect];

  [self drawImageInRect:imageContainerRect];

  CGFloat textStartX = CGRectGetMaxX(imageContainerRect) + 8;

  [self drawTextInContainerRect:innerRect startX:textStartX];
}

- (void)drawImageInRect:(CGRect)containerRect {
  if (!self.image) {
    return;
  }

  CGRect imageRect = CGRectMake(
      containerRect.origin.x + (_imageContainerWidth - _imageWidth) / 2,
      containerRect.origin.y + (_imageContainerHeight - _imageHeight) / 2,
      _imageWidth, _imageHeight);

  [self.image drawInRect:imageRect];
}

- (void)drawBorderInRect:(CGRect)rect context:(CGContextRef)ctx {

  // border
  if (_borderWidth > 0 && _borderColor) {
    CGRect borderRect =
        CGRectInset(rect, _borderWidth * 0.5, _borderWidth * 0.5);

    UIBezierPath *border =
        [UIBezierPath bezierPathWithRoundedRect:borderRect
                                   cornerRadius:_cornerRadius];

    border.lineWidth = _borderWidth;

    [_borderColor setStroke];
    [border stroke];
  }

  // stripe
  if (_tintColor && _stripeWidth > 0) {

    UIBezierPath *clipPath =
        [UIBezierPath bezierPathWithRoundedRect:rect
                                   cornerRadius:_cornerRadius];

    CGContextSaveGState(ctx);

    CGContextAddPath(ctx, clipPath.CGPath);
    CGContextClip(ctx);

    CGRect stripeRect = CGRectMake(rect.origin.x, rect.origin.y, _stripeWidth,
                                   rect.size.height);

    CGContextSetFillColorWithColor(ctx, _tintColor.CGColor);
    CGContextFillRect(ctx, stripeRect);

    CGContextRestoreGState(ctx);
  }
}

- (void)drawTextInContainerRect:(CGRect)containerRect startX:(CGFloat)startX {
  CGSize textSize = [_labelText size];

  CGFloat textY = containerRect.origin.y +
                  (containerRect.size.height - textSize.height) / 2;

  [_labelText drawAtPoint:CGPointMake(startX, textY)];
}

- (CGRect)drawImageContainerRectInRect:(CGRect)rect {
  CGFloat startX = rect.origin.x + _stripeWidth;

  CGRect imageContainerRect = CenterRectVertically(
      rect, _imageContainerWidth, _imageContainerHeight, startX);

  if (_tintColor) {
    UIBezierPath *container =
        [UIBezierPath bezierPathWithRoundedRect:imageContainerRect
                                   cornerRadius:_imageBorderRadius];
    [_tintColor setFill];
    [container fill];
  }

  if (self.image) {
    [self drawImageInRect:imageContainerRect];
  }

  return imageContainerRect;
}

@end
