#import "ImageLabelAttachment.h"
#import "ContentParams.h"
#import "ContentStyleProps.h"
#import "EnrichedImageLoader.h"
#import "ImageLabelAttachmentUtils.h"
#import "ImageLayoutUtils.h"

@implementation ImageLabelAttachment {
  NSDictionary *_headers;
  NSAttributedString *_labelText;
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
  CGSize _textSize;

  UIImage *_cachedImage;
  CGSize _cachedImageSize;
  BOOL _needsRedraw;
}

#pragma mark - Init

- (instancetype)initWithParams:(ContentParams *)params
                        styles:(ContentStyleProps *)styles {
  self = [super init];
  if (!self)
    return nil;

  self.uri = params.url;

  _labelText = [[NSAttributedString alloc]
      initWithString:params.text
          attributes:@{
            NSFontAttributeName : styles.font,
            NSForegroundColorAttributeName : styles.textColor
          }];

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

  _imageCornerRadiusTopLeft = styles.imageBorderRadiusTopLeft;
  _imageCornerRadiusTopRight = styles.imageBorderRadiusTopRight;
  _imageCornerRadiusBottomLeft = styles.imageBorderRadiusBottomLeft;
  _imageCornerRadiusBottomRight = styles.imageBorderRadiusBottomRight;

  _imageSpacing = 8.0;

  _needsRedraw = YES;

  _textSize = [_labelText size];
  self.height = [self calculateHeight];
  self.image = MakeLoaderImage();

  [self loadAsync];

  return self;
}

#pragma mark - Layout

- (CGFloat)calculateHeight {
  CGFloat imageH = _imageHeight > 0 ? _imageHeight : _textSize.height;
  return MAX(_textSize.height, imageH) + _margin.top + _margin.bottom;
}

#pragma mark - Drawing helpers

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
  if (!self.image)
    return;

  CGRect imageRect = [self imageRectForContentRect:contentRect];

  CGContextSaveGState(ctx);

  UIBezierPath *clip = MakeImageClipPath(
      imageRect, _imageCornerRadiusTopLeft, _imageCornerRadiusTopRight,
      _imageCornerRadiusBottomLeft, _imageCornerRadiusBottomRight);
  [clip addClip];

  CGRect target = [ImageLayoutUtils rectForImage:self.image
                                          inRect:imageRect
                                      resizeMode:_imageResizeMode];

  [self.image drawInRect:target];

  CGContextRestoreGState(ctx);
}

- (void)drawTextInRect:(CGRect)contentRect {
  CGRect imageRect = [self imageRectForContentRect:contentRect];

  CGFloat textX = CGRectGetMaxX(imageRect) + _imageSpacing + _inset.left;
  CGFloat textY =
      contentRect.origin.y + (contentRect.size.height - _textSize.height) * 0.5;

  [_labelText drawAtPoint:CGPointMake(textX, textY)];
}

#pragma mark - NSTextAttachment sizing

- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)textContainer
                      proposedLineFragment:(CGRect)lineFrag
                             glyphPosition:(CGPoint)position
                            characterIndex:(NSUInteger)charIndex {

  CGFloat padding = textContainer ? textContainer.lineFragmentPadding : 0.0;
  CGFloat width = lineFrag.size.width - padding * 2;

  return CGRectMake(0, 0, width, self.height);
}

#pragma mark - Rendering entry (with cache)

- (UIImage *)imageForBounds:(CGRect)bounds
              textContainer:(NSTextContainer *)textContainer
             characterIndex:(NSUInteger)charIndex {

  if (bounds.size.width <= 0 || bounds.size.height <= 0)
    return nil;

  if (!_needsRedraw && _cachedImage &&
      CGSizeEqualToSize(bounds.size, _cachedImageSize)) {
    return _cachedImage;
  }

  UIGraphicsImageRendererFormat *format =
      [UIGraphicsImageRendererFormat defaultFormat];
  format.opaque = NO;

  UIGraphicsImageRenderer *renderer =
      [[UIGraphicsImageRenderer alloc] initWithSize:bounds.size format:format];

  UIImage *image =
      [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        CGRect contentRect = ContentRect(bounds, _margin);

        [self drawBackgroundInRect:contentRect];
        [self drawBorderInRect:contentRect];
        [self drawImageInRect:contentRect context:ctx.CGContext];
        [self drawTextInRect:contentRect];
      }];

  _cachedImage = image;
  _cachedImageSize = bounds.size;
  _needsRedraw = NO;

  return image;
}

#pragma mark - Image loading

- (void)invalidateCache {
  _cachedImage = nil;
  _needsRedraw = YES;
}

- (void)updateImage:(UIImage *)image {
  dispatch_async(dispatch_get_main_queue(), ^{
    self.image = image;
    [self invalidateCache];
    [self notifyUpdate];
  });
}

- (void)loadAsync {
  __weak __typeof__(self) weakSelf = self;

  dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
    __strong __typeof__(weakSelf) strongSelf = weakSelf;
    if (!strongSelf)
      return;

    NSDictionary *headers = strongSelf->_headers;
    NSURL *url = [NSURL URLWithString:strongSelf.uri];

    void (^completion)(UIImage *) = ^(UIImage *img) {
      if (!strongSelf)
        return;

      img ? [strongSelf updateImage:img] : [strongSelf loadFallbackAsync];
    };

    if (headers.count == 0) {
      [[EnrichedImageLoader shared] loadImage:url completion:completion];
    } else {
      [[EnrichedImageLoader shared] loadImage:url
                                      headers:headers
                                   completion:completion];
    }
  });
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

@end
