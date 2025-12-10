#import "ImageLabelAttachment.h"
#import "ImageLayoutUtils.h"

@implementation ImageLabelAttachment

- (instancetype)init {
  self = [super init];
  if (!self)
    return nil;

  _imageSpacing = 8.0;
  _imageWidth = 0;
  _imageHeight = 0;
  _imageResizeMode = @"cover";

  _isLoading = NO;
  _contentImage = nil;

  _imageCornerRadiusTopLeft = 0;
  _imageCornerRadiusTopRight = 0;
  _imageCornerRadiusBottomLeft = 0;
  _imageCornerRadiusBottomRight = 0;

  return self;
}

#pragma mark - RENDERER

- (UIImage *)renderAttachmentInSize:(CGSize)containerSize {

  CGSize textSize = [self textSize];
  CGFloat lineWidth = containerSize.width;

  CGFloat imgWidth = (self.imageWidth > 0) ? self.imageWidth : lineWidth * 0.30;

  CGFloat imgHeight = textSize.height + self.inset.top + self.inset.bottom;

  CGFloat spacing = self.imageSpacing;

  CGFloat textAreaWidth = lineWidth - imgWidth - spacing;

  CGSize canvas = CGSizeMake(lineWidth + self.margin.left + self.margin.right,
                             imgHeight + self.margin.top + self.margin.bottom);

  UIGraphicsBeginImageContextWithOptions(canvas, NO, 0.0);
  CGContextRef ctx = UIGraphicsGetCurrentContext();

  CGRect contentRect = [self contentRectForContainer:canvas];

  [self drawBackgroundInRect:contentRect context:ctx];
  [self drawBorderInRect:contentRect context:ctx];

  CGRect imageRect = CGRectMake(contentRect.origin.x, contentRect.origin.y,
                                imgWidth, contentRect.size.height);

  if (self.isLoading) {
    CGContextSaveGState(ctx);

    UIBezierPath *clip = [self imageClipPath:imageRect];
    [clip addClip];

    [[UIColor colorWithWhite:0.80 alpha:1.0] setFill];
    UIRectFill(imageRect);

    CGContextRestoreGState(ctx);
  }

  if (self.contentImage && !self.isLoading) {
    CGContextSaveGState(ctx);

    UIBezierPath *clip = [self imageClipPath:imageRect];
    [clip addClip];

    ImageResizeMode mode =
        [ImageLayoutUtils resizeModeFromString:self.imageResizeMode];

    CGRect target = [ImageLayoutUtils rectForImage:self.contentImage
                                            inRect:imageRect
                                        resizeMode:mode];

    [self.contentImage drawInRect:target];

    CGContextRestoreGState(ctx);
  }

  CGRect textRect = CGRectMake(
      CGRectGetMaxX(imageRect) + spacing + self.inset.left,
      contentRect.origin.y + self.inset.top,
      textAreaWidth - self.inset.left - self.inset.right, textSize.height);

  [self.labelText drawInRect:textRect
              withAttributes:@{
                NSFontAttributeName : self.font,
                NSForegroundColorAttributeName : self.textColor
              }];

  UIImage *output = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return output;
}

#pragma mark - SIZE

- (CGSize)requiredSizeForLineFragment:(CGSize)lineSize {

  CGSize textSize = [self textSize];

  CGFloat height = textSize.height + self.inset.top + self.inset.bottom +
                   self.margin.top + self.margin.bottom;

  return CGSizeMake(lineSize.width, height);
}

#pragma mark - IMAGE CLIP PATH

- (UIBezierPath *)imageClipPath:(CGRect)rect {

  CGFloat tl = self.imageCornerRadiusTopLeft;
  CGFloat tr = self.imageCornerRadiusTopRight;
  CGFloat bl = self.imageCornerRadiusBottomLeft;
  CGFloat br = self.imageCornerRadiusBottomRight;

  UIBezierPath *path = [UIBezierPath bezierPath];

  CGFloat minX = CGRectGetMinX(rect);
  CGFloat minY = CGRectGetMinY(rect);
  CGFloat maxX = CGRectGetMaxX(rect);
  CGFloat maxY = CGRectGetMaxY(rect);

  [path moveToPoint:CGPointMake(minX + tl, minY)];

  // top edge → top-right
  [path addLineToPoint:CGPointMake(maxX - tr, minY)];
  if (tr > 0)
    [path addArcWithCenter:CGPointMake(maxX - tr, minY + tr)
                    radius:tr
                startAngle:-M_PI_2
                  endAngle:0
                 clockwise:YES];

  // right edge → bottom-right
  [path addLineToPoint:CGPointMake(maxX, maxY - br)];
  if (br > 0)
    [path addArcWithCenter:CGPointMake(maxX - br, maxY - br)
                    radius:br
                startAngle:0
                  endAngle:M_PI_2
                 clockwise:YES];

  // bottom edge → bottom-left
  [path addLineToPoint:CGPointMake(minX + bl, maxY)];
  if (bl > 0)
    [path addArcWithCenter:CGPointMake(minX + bl, maxY - bl)
                    radius:bl
                startAngle:M_PI_2
                  endAngle:M_PI
                 clockwise:YES];

  // left edge → top-left
  [path addLineToPoint:CGPointMake(minX, minY + tl)];
  if (tl > 0)
    [path addArcWithCenter:CGPointMake(minX + tl, minY + tl)
                    radius:tl
                startAngle:M_PI
                  endAngle:3 * M_PI_2
                 clockwise:YES];

  [path closePath];
  return path;
}

@end
