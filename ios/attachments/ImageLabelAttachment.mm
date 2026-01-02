#import "ImageLabelAttachment.h"
#import "ContentParams.h"
#import "ContentStyleProps.h"
#import "EnrichedImageLoader.h"
#import "ImageLabelAttachmentUtils.h"
#import "ImageLayoutUtils.h"

@implementation ImageLabelAttachment {
  NSDictionary *_headers;
  NSString *_labelText;
  UIFont *_font;
  UIColor *_textColor;
  NSString *_fallbackUri;

  UIColor *_bgColor;
  UIColor *_borderColor;

  CGFloat _borderWidth;
  CGFloat _cornerRadius;

  UIEdgeInsets _inset;
  UIEdgeInsets _margin;

  CGFloat _imageWidth;
  CGFloat _imageHeight;
  CGFloat _imageSpacing;

  ImageResizeMode _imageResizeMode;

  CGFloat _imageCornerRadiusTopLeft;
  CGFloat _imageCornerRadiusTopRight;
  CGFloat _imageCornerRadiusBottomLeft;
  CGFloat _imageCornerRadiusBottomRight;
  BorderStyle _borderStyleEnum;
}

#pragma mark - Init

- (instancetype)initWithParams:(ContentParams *)params
                        styles:(ContentStyleProps *)styles {
  self = [super init];
  if (!self)
    return nil;
  self.uri = params.url;
  _labelText = params.text;
  _font = styles.font;
  _textColor = styles.textColor;
  _fallbackUri = styles.fallbackImageURI;

  _bgColor = styles.backgroundColor;
  _borderColor = styles.borderColor;
  _borderWidth = styles.borderWidth;
  _borderStyleEnum = ParseBorderStyle(styles.borderStyle);
  _cornerRadius = styles.borderRadius;

  _margin = UIEdgeInsetsMake(styles.marginTop, styles.marginLeft,
                             styles.marginBottom, styles.marginRight);

  _inset = UIEdgeInsetsMake(styles.paddingTop, styles.paddingLeft,
                            styles.paddingBottom, styles.paddingRight);

  _imageWidth = styles.imageWidth;
  _imageHeight = styles.imageHeight;
  _imageResizeMode =
      [ImageLayoutUtils resizeModeFromString:styles.imageResizeMode];
  ;

  _imageCornerRadiusTopLeft = styles.imageBorderRadiusTopLeft;
  _imageCornerRadiusTopRight = styles.imageBorderRadiusTopRight;
  _imageCornerRadiusBottomLeft = styles.imageBorderRadiusBottomLeft;
  _imageCornerRadiusBottomRight = styles.imageBorderRadiusBottomRight;

  _imageSpacing = 8.0;

  self.image = MakeLoaderImage();
  self.height = [self calculateHeight];

  [self loadAsync];

  return self;
}

- (CGFloat)calculateHeight {
  CGFloat textHeight =
      [_labelText sizeWithAttributes:@{NSFontAttributeName : _font}].height;

  CGFloat imageH = _imageHeight > 0 ? _imageHeight : textHeight;

  return MAX(textHeight, imageH) + _margin.top + _margin.bottom;
}

#pragma mark - Drawing helpers

- (CGSize)textSize {
  return [_labelText sizeWithAttributes:@{NSFontAttributeName : _font}];
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect {
  return ImageRect(contentRect, _imageWidth, _imageHeight);
}

- (void)drawBackgroundInRect:(CGRect)contentRect {
  if (!_bgColor)
    return;

  UIBezierPath *bg = [UIBezierPath bezierPathWithRoundedRect:contentRect
                                                cornerRadius:_cornerRadius];
  [_bgColor setFill];
  [bg fill];
}

- (void)drawBorderInRect:(CGRect)contentRect {
  if (_borderWidth <= 0 || !_borderColor)
    return;

  CGRect borderRect =
      CGRectInset(contentRect, _borderWidth * 0.5, _borderWidth * 0.5);

  UIBezierPath *border = [UIBezierPath bezierPathWithRoundedRect:borderRect
                                                    cornerRadius:_cornerRadius];

  border.lineWidth = _borderWidth;
  ApplyBorderStyle(border, _borderStyleEnum);

  [_borderColor setStroke];
  [border stroke];
}

- (void)drawImageInRect:(CGRect)contentRect context:(CGContextRef)ctx {
  CGRect imageRect = [self imageRectForContentRect:contentRect];

  CGContextSaveGState(ctx);

  UIBezierPath *clip = [self imageClipPath:imageRect];
  [clip addClip];

  CGRect target = [ImageLayoutUtils rectForImage:self.image
                                          inRect:imageRect
                                      resizeMode:_imageResizeMode];

  [self.image drawInRect:target];

  CGContextRestoreGState(ctx);
}

- (void)drawTextInRect:(CGRect)contentRect {
  CGSize textSize = [self textSize];

  CGRect imageRect = [self imageRectForContentRect:contentRect];

  CGFloat textX = CGRectGetMaxX(imageRect) + _imageSpacing + _inset.left;

  CGFloat textY =
      contentRect.origin.y + (contentRect.size.height - textSize.height) * 0.5;

  NSDictionary *attrs = @{
    NSFontAttributeName : _font,
    NSForegroundColorAttributeName : _textColor
  };

  [_labelText drawAtPoint:CGPointMake(textX, textY) withAttributes:attrs];
}

#pragma mark - Size

- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)textContainer
                      proposedLineFragment:(CGRect)lineFrag
                             glyphPosition:(CGPoint)position
                            characterIndex:(NSUInteger)charIndex {
  CGFloat padding = textContainer ? textContainer.lineFragmentPadding : 0.0;
  CGFloat width = lineFrag.size.width - padding * 2;

  return CGRectMake(0, 0, width, self.height);
}

#pragma mark - Rendering entry

- (UIImage *)imageForBounds:(CGRect)bounds
              textContainer:(NSTextContainer *)textContainer
             characterIndex:(NSUInteger)charIndex {

  if (bounds.size.width <= 0 || bounds.size.height <= 0)
    return nil;

  UIGraphicsImageRendererFormat *format =
      [UIGraphicsImageRendererFormat defaultFormat];
  format.opaque = NO;

  auto renderer = [[UIGraphicsImageRenderer alloc] initWithSize:bounds.size
                                                         format:format];

  return [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
    CGRect contentRect = ContentRect(bounds, _margin);

    [self drawBackgroundInRect:contentRect];
    [self drawBorderInRect:contentRect];
    [self drawImageInRect:contentRect context:ctx.CGContext];
    [self drawTextInRect:contentRect];
  }];
}

#pragma mark - Image loading

- (void)updateImage:(UIImage *)image {
  dispatch_async(dispatch_get_main_queue(), ^{
    self.image = image;
    [self notifyUpdate];
  });
}

- (void)loadAsync {
  NSURL *url = [NSURL URLWithString:self.uri];

  void (^onLoadEnd)(UIImage *) = ^(UIImage *img) {
    img ? [self updateImage:img] : [self loadFallbackAsync];
  };

  if (self->_headers.count == 0) {
    [[EnrichedImageLoader shared] loadImage:url
                                 completion:^(UIImage *img) {
                                   onLoadEnd(img);
                                 }];
  } else {
    [[EnrichedImageLoader shared] loadImage:url
                                    headers:self->_headers
                                 completion:^(UIImage *img) {
                                   onLoadEnd(img);
                                 }];
  }
}

- (void)loadFallbackAsync {
  if (!_fallbackUri)
    return;

  NSURL *url = [NSURL URLWithString:_fallbackUri];

  [[EnrichedImageLoader shared] loadImage:url
                               completion:^(UIImage *img) {
                                 if (!img)
                                   return;
                                 [self updateImage:img];
                               }];
}

#pragma mark - Clip path

- (UIBezierPath *)imageClipPath:(CGRect)rect {
  CGFloat tl = _imageCornerRadiusTopLeft;
  CGFloat tr = _imageCornerRadiusTopRight;
  CGFloat bl = _imageCornerRadiusBottomLeft;
  CGFloat br = _imageCornerRadiusBottomRight;

  UIBezierPath *path = [UIBezierPath bezierPath];

  CGFloat minX = CGRectGetMinX(rect);
  CGFloat minY = CGRectGetMinY(rect);
  CGFloat maxX = CGRectGetMaxX(rect);
  CGFloat maxY = CGRectGetMaxY(rect);

  [path moveToPoint:CGPointMake(minX + tl, minY)];

  [path addLineToPoint:CGPointMake(maxX - tr, minY)];
  if (tr > 0)
    [path addArcWithCenter:CGPointMake(maxX - tr, minY + tr)
                    radius:tr
                startAngle:-M_PI_2
                  endAngle:0
                 clockwise:YES];

  [path addLineToPoint:CGPointMake(maxX, maxY - br)];
  if (br > 0)
    [path addArcWithCenter:CGPointMake(maxX - br, maxY - br)
                    radius:br
                startAngle:0
                  endAngle:M_PI_2
                 clockwise:YES];

  [path addLineToPoint:CGPointMake(minX + bl, maxY)];
  if (bl > 0)
    [path addArcWithCenter:CGPointMake(minX + bl, maxY - bl)
                    radius:bl
                startAngle:M_PI_2
                  endAngle:M_PI
                 clockwise:YES];

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
