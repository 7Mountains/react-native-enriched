#import "BaseLabelAttachment.h"
#import "ContentParams.h"
#import "ContentStyleProps.h"
#import "EnrichedParagraphStyle.h"
#import "ImageLabelAttachmentUtils.h"

@implementation BaseLabelAttachment {
  NSString *_labelText;
  UIFont *_font;
  UIColor *_textColor;

  UIColor *_bgColor;
  UIColor *_borderColor;

  CGFloat _borderWidth;
  CGFloat _cornerRadius;

  UIEdgeInsets _inset;
  UIEdgeInsets _margin;

  BorderStyle _borderStyleEnum;

  CGSize _textSize;
}

- (instancetype)initWithParams:(ContentParams *)params
                        styles:(ContentStyleProps *)styles {
  self = [super init];
  if (!self)
    return nil;

  _labelText = params.text ?: @"";
  _font = styles.font ?: [UIFont systemFontOfSize:12];
  _textColor = styles.textColor ?: UIColor.blackColor;

  _bgColor = styles.backgroundColor;
  _borderColor = styles.borderColor;
  _borderWidth = styles.borderWidth;
  _borderStyleEnum = ParseBorderStyle(styles.borderStyle);
  _cornerRadius = styles.borderRadius;

  _margin = UIEdgeInsetsMake(styles.marginTop, styles.marginLeft,
                             styles.marginBottom, styles.marginRight);

  _inset = UIEdgeInsetsMake(styles.paddingTop, styles.paddingLeft,
                            styles.paddingBottom, styles.paddingRight);

  NSDictionary *attrs = @{NSFontAttributeName : _font};
  _textSize = [_labelText sizeWithAttributes:attrs];

  self.image = nil;

  return self;
}

- (CGRect)contentRectForContainer:(CGSize)containerSize {
  return CGRectMake(_margin.left, _margin.top,
                    containerSize.width - _margin.left - _margin.right,
                    containerSize.height - _margin.top - _margin.bottom);
}

- (void)drawBackgroundAndBorderInRect:(CGRect)rect context:(CGContextRef)ctx {
  if (!_bgColor && (_borderWidth <= 0 || !_borderColor))
    return;

  CGRect drawRect = rect;

  if (_borderWidth > 0) {
    drawRect = CGRectInset(drawRect, _borderWidth / 2.0, _borderWidth / 2.0);
  }

  UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:drawRect
                                                  cornerRadius:_cornerRadius];

  if (_bgColor) {
    [_bgColor setFill];
    [path fill];
  }

  if (_borderWidth > 0 && _borderColor) {
    path.lineWidth = _borderWidth;
    ApplyBorderStyle(path, _borderStyleEnum);
    [_borderColor setStroke];
    [path stroke];
  }
}

- (void)drawTextInRect:(CGRect)rect context:(CGContextRef)ctx {
  if (_labelText.length == 0)
    return;

  CGRect contentRect = UIEdgeInsetsInsetRect(rect, _inset);

  EnrichedParagraphStyle *style = [EnrichedParagraphStyle new];
  style.alignment = NSTextAlignmentCenter;
  style.lineBreakMode = NSLineBreakByTruncatingTail;

  NSDictionary *attrs = @{
    NSFontAttributeName : _font,
    NSForegroundColorAttributeName : _textColor,
    NSParagraphStyleAttributeName : style
  };

  CGRect textRect =
      CGRectMake(CGRectGetMidX(contentRect) - _textSize.width / 2.0,
                 CGRectGetMidY(contentRect) - _textSize.height / 2.0,
                 _textSize.width, _textSize.height);

  [_labelText drawInRect:CGRectIntegral(textRect) withAttributes:attrs];
}

#pragma mark - Renderer

- (UIImage *)renderImageWithSize:(CGSize)size {
  if (size.width <= 0 || size.height <= 0)
    return nil;

  UIGraphicsImageRendererFormat *format =
      [UIGraphicsImageRendererFormat preferredFormat];
  format.opaque = NO;
  format.scale = UIScreen.mainScreen.scale;

  UIGraphicsImageRenderer *renderer =
      [[UIGraphicsImageRenderer alloc] initWithSize:size format:format];

  return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
    [self drawAttachmentInRendererContext:context size:size];
  }];
}

- (void)drawAttachmentInRendererContext:
            (UIGraphicsImageRendererContext *)context
                                   size:(CGSize)size {
  CGContextRef ctx = context.CGContext;

  CGRect contentRect = [self contentRectForContainer:size];

  [self drawBackgroundAndBorderInRect:contentRect context:ctx];
  [self drawTextInRect:contentRect context:ctx];
}

#pragma mark - NSTextAttachment overrides

- (UIImage *)imageForBounds:(CGRect)bounds
              textContainer:(NSTextContainer *)textContainer
             characterIndex:(NSUInteger)charIndex {

  CGSize size = CGSizeMake(round(bounds.size.width), round(bounds.size.height));

  return [self renderImageWithSize:size];
}

- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)textContainer
                      proposedLineFragment:(CGRect)lineFrag
                             glyphPosition:(CGPoint)position
                            characterIndex:(NSUInteger)charIndex {
  CGFloat height = _textSize.height + _inset.top + _inset.bottom +
                   _borderWidth * 2 + _margin.top + _margin.bottom;

  return (CGRect){.origin = CGPointZero,
                  .size = CGSizeMake(lineFrag.size.width, ceil(height))};
}

@end
