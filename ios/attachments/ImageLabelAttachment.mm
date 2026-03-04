#import "ImageLabelAttachment.h"
#import "AttachmentUtils.h"
#import "ContentParams.h"
#import "ContentStyleProps.h"
#import "EnrichedImageLoader.h"
#import "ImageLayoutUtils.h"

@implementation ImageLabelAttachment {
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

  _textSize = [_labelText size];
  if (styles.height > 0) {
    self.height = styles.height + _margin.top + _margin.bottom;
  } else {
    self.height = [self calculateHeight];
  }
  self.image = MakeLoaderImage();
  [self loadImageAsyncWithURI:self.uri];

  return self;
}

#pragma mark - Layout

- (CGFloat)calculateHeight {
  CGFloat imageH = _imageHeight > 0 ? _imageHeight : _textSize.height;
  return MAX(_textSize.height, imageH) + _margin.top + _margin.bottom;
}

#pragma mark - Drawing helpers

- (CGRect)imageRectForContentRect:(CGRect)contentRect {
  CGFloat availableHeight = self.height - _margin.top - _margin.bottom;

  CGFloat imageH;

  if (_imageHeight == 0 || availableHeight < _imageHeight) {
    imageH = availableHeight;
  } else {
    imageH = _imageHeight;
  }

  CGFloat x = contentRect.origin.x + _inset.left;
  CGFloat y = contentRect.origin.y + _inset.top;

  return CGRectMake(x, y, _imageWidth, imageH);
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
  CGFloat availableHeight =
      contentRect.size.height - _inset.top - _inset.bottom;

  CGFloat textY = contentRect.origin.y + _inset.top +
                  (availableHeight - _textSize.height) * 0.5;

  [_labelText drawAtPoint:CGPointMake(textX, textY)];
}

- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)textContainer
                      proposedLineFragment:(CGRect)lineFrag
                             glyphPosition:(CGPoint)position
                            characterIndex:(NSUInteger)charIndex {

  CGFloat padding = textContainer ? textContainer.lineFragmentPadding : 0.0;
  CGFloat width = lineFrag.size.width - padding * 2;

  return CGRectMake(0, 0, width, self.height);
}

- (void)drawContentInBounds:(CGRect)bounds context:(CGContextRef)ctx {

  CGRect contentRect = ContentRect(bounds, _margin);

  DrawRoundedBackground(contentRect, _cornerRadius, _bgColor);
  [self drawBorderInRect:contentRect];
  [self drawImageInRect:contentRect context:ctx];
  [self drawTextInRect:contentRect];
}

@end
