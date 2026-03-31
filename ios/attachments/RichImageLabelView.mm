#import "RichImageLabelView.h"

static const CGSize kDefaultImageSize = CGSizeMake(40.0, 40.0);
static const CGFloat kDefaultMinHeight = 56.0;
static const CGSize kDefaultImageContainerSize = CGSizeMake(56.0, 56.0);

static const CGFloat kDefaultDescriptionTopSpacing = 0.0;

@implementation RichImageLabelView {
  CALayer *_leftBorderLayer;
  UIView *_imageContainer;
  UIView *_textContainer;
  UIImageView *_imageView;
  UILabel *_titleLabel;
  UILabel *_descriptionLabel;

  CAShapeLayer *_borderLayer;
}

#pragma mark - Init

- (instancetype)init {
  self = [super init];
  if (!self)
    return nil;

  self.clipsToBounds = YES;
  self.layer.masksToBounds = YES;

  _imageContainer = [UIView new];
  _textContainer = [UIView new];

  _imageView = [UIImageView new];
  _imageView.clipsToBounds = YES;

  _titleLabel = [UILabel new];
  _descriptionLabel = [UILabel new];

  _titleLabel.numberOfLines = 1;
  _descriptionLabel.numberOfLines = 0;

  _titleLabel.textAlignment = NSTextAlignmentLeft;
  _descriptionLabel.textAlignment = NSTextAlignmentLeft;

  _imageSize = kDefaultImageSize;
  _minHeight = kDefaultMinHeight;
  _imageContainerSize = kDefaultImageContainerSize;

  _textPadding = UIEdgeInsetsZero;
  _textMargin = UIEdgeInsetsZero;

  _leftBorderLayer = [CALayer layer];

  [self.layer addSublayer:_leftBorderLayer];

  [_imageContainer addSubview:_imageView];
  [_textContainer addSubview:_titleLabel];
  [_textContainer addSubview:_descriptionLabel];

  [self addSubview:_imageContainer];
  [self addSubview:_textContainer];

  return self;
}

#pragma mark - Helpers

- (CGSize)sizeForLabel:(UILabel *)label width:(CGFloat)width {
  if (!label.attributedText.length || width <= 0)
    return CGSizeZero;

  CGRect rect = [label.attributedText
      boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                   options:NSStringDrawingUsesLineFragmentOrigin |
                           NSStringDrawingUsesFontLeading
                   context:nil];

  return CGSizeMake(ceil(rect.size.width), ceil(rect.size.height));
}

#pragma mark - Layout

- (CGSize)sizeThatFits:(CGSize)size {
  CGFloat contentWidth = size.width;

  CGFloat imageBlockWidth = _imageContainerSize.width > 0
                                ? _imageContainerSize.width
                                : kDefaultImageContainerSize.width;

  CGFloat textX = self.padding.left + imageBlockWidth + self.textMargin.left;

  CGFloat textWidth =
      contentWidth - textX - self.padding.right - self.textMargin.right;
  textWidth =
      MAX(textWidth - self.textPadding.left - self.textPadding.right, 0);

  CGSize titleSize = [self sizeForLabel:_titleLabel width:textWidth];
  CGSize descSize = _descriptionLabel.attributedText.length
                        ? [self sizeForLabel:_descriptionLabel width:textWidth]
                        : CGSizeZero;

  CGFloat textHeight =
      titleSize.height + (descSize.height > 0
                              ? descSize.height + kDefaultDescriptionTopSpacing
                              : 0);

  CGFloat totalTextHeight =
      textHeight + self.textPadding.top + self.textPadding.bottom;

  CGFloat imageHeight =
      _imageContainerSize.height > 0 ? _imageContainerSize.height : 0;
  CGFloat contentHeight = MAX(totalTextHeight, imageHeight);

  CGFloat finalHeight = MAX(
      contentHeight + self.padding.top + self.padding.bottom, self.minHeight);

  return CGSizeMake(size.width, ceil(finalHeight));
}

- (void)layoutSubviews {
  [super layoutSubviews];

  CGRect bounds = self.bounds;

  _leftBorderLayer.frame =
      _borderLeftWidth > 0
          ? CGRectMake(0, 0, _borderLeftWidth, bounds.size.height)
          : CGRectZero;

  CGFloat leftInset = self.padding.left + self.borderLeftWidth;
  CGFloat contentHeight =
      bounds.size.height - self.padding.top - self.padding.bottom;

  // IMAGE
  CGFloat containerH = _imageContainerSize.height > 0
                           ? _imageContainerSize.height
                           : contentHeight;
  CGFloat containerW =
      _imageContainerSize.width > 0 ? _imageContainerSize.width : containerH;

  CGFloat imageY = self.padding.top + (contentHeight - containerH) / 2.0;

  _imageContainer.frame = CGRectMake(leftInset, imageY, containerW, containerH);

  CGFloat imageW = _imageSize.width > 0 ? _imageSize.width : containerW;
  CGFloat imageH = _imageSize.height > 0 ? _imageSize.height : containerH;

  _imageView.frame = CGRectMake((containerW - imageW) / 2.0,
                                (containerH - imageH) / 2.0, imageW, imageH);

  // TEXT CONTAINER
  CGFloat textX = CGRectGetMaxX(_imageContainer.frame) + self.textMargin.left;

  CGFloat textWidth =
      bounds.size.width - self.padding.right - textX - self.textMargin.right;
  textWidth = MAX(textWidth, 0);

  CGFloat innerWidth =
      MAX(textWidth - self.textPadding.left - self.textPadding.right, 0);

  CGSize titleSize = [self sizeForLabel:_titleLabel width:innerWidth];
  BOOL hasDesc = _descriptionLabel.attributedText.length > 0;

  CGSize descSize = hasDesc
                        ? [self sizeForLabel:_descriptionLabel width:innerWidth]
                        : CGSizeZero;

  CGFloat textHeight =
      titleSize.height +
      (hasDesc ? descSize.height + kDefaultDescriptionTopSpacing : 0);

  CGFloat containerHeight =
      textHeight + self.textPadding.top + self.textPadding.bottom;

  CGFloat centerY = self.padding.top + contentHeight / 2.0;
  CGFloat containerY = centerY - containerHeight / 2.0;

  _textContainer.frame =
      CGRectMake(textX, containerY, textWidth, containerHeight);

  CGFloat contentX = self.textPadding.left;
  CGFloat currentY = self.textPadding.top;

  _titleLabel.frame =
      CGRectMake(contentX, currentY, innerWidth, titleSize.height);

  if (hasDesc) {
    _descriptionLabel.frame = CGRectMake(contentX,
                                         CGRectGetMaxY(_titleLabel.frame) +
                                             kDefaultDescriptionTopSpacing,
                                         innerWidth, descSize.height);
  } else {
    _descriptionLabel.frame = CGRectZero;
  }

  [self updateBorderPathIfNeeded];
}

#pragma mark - Border

- (void)updateBorder {
  [_borderLayer removeFromSuperlayer];
  _borderLayer = nil;

  self.layer.borderWidth = 0;

  if (_borderStyle == EnrichedBorderStyleNone || _containerBorderWidth <= 0 ||
      !_containerBorderColor) {
    return;
  }

  if (_borderStyle == EnrichedBorderStyleSolid) {
    self.layer.borderWidth = _containerBorderWidth;
    self.layer.borderColor = _containerBorderColor.CGColor;
    return;
  }

  _borderLayer = [self createShapeLayer];
  [self.layer addSublayer:_borderLayer];

  [self setNeedsLayout];
}

- (CAShapeLayer *)createShapeLayer {
  CAShapeLayer *shape = [CAShapeLayer layer];

  shape.fillColor = UIColor.clearColor.CGColor;
  shape.strokeColor = _containerBorderColor.CGColor;

  CGFloat scale = UIScreen.mainScreen.scale;
  shape.lineWidth = MAX(1.0 / scale, _containerBorderWidth);

  switch (_borderStyle) {
  case EnrichedBorderStyleDashed:
    shape.lineDashPattern = @[ @6, @3 ];
    break;

  case EnrichedBorderStyleDotted:
    shape.lineDashPattern = @[ @1, @2 ];
    shape.lineCap = kCALineCapRound;
    break;

  default:
    break;
  }

  return shape;
}

- (void)updateBorderPathIfNeeded {
  if (!_borderLayer)
    return;

  _borderLayer.frame = self.bounds;

  UIBezierPath *path =
      [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                 cornerRadius:self.layer.cornerRadius];

  _borderLayer.path = path.CGPath;
}

#pragma mark - Setters

- (void)setTitleText:(NSAttributedString *)titleText {
  _titleLabel.attributedText = titleText;
}

- (void)setDescriptionText:(NSAttributedString *)descriptionText {
  _descriptionLabel.attributedText = descriptionText;
}

- (void)setImageContainerColor:(UIColor *)color {
  _imageContainer.backgroundColor = color;
}

- (void)setImageContainerCornerRadius:(CGFloat)radius {
  _imageContainer.layer.cornerRadius = radius;
}

- (void)setImage:(UIImage *)image {
  _imageView.image = image;
}

- (void)setImageContentMode:(UIViewContentMode)mode {
  _imageView.contentMode = mode;
}

- (void)setContainerBackgroundColor:(UIColor *)color {
  self.layer.backgroundColor = color.CGColor;
}

- (void)setContainerCornerRadius:(CGFloat)radius {
  _containerCornerRadius = radius;
  self.layer.cornerRadius = radius;
  [self setNeedsLayout];
}

- (void)setBorderStyle:(EnrichedBorderStyle)style {
  if (_borderStyle == style)
    return;
  _borderStyle = style;
  [self updateBorder];
}

- (void)setContainerBorderWidth:(CGFloat)width {
  if (_containerBorderWidth == width)
    return;
  _containerBorderWidth = width;
  [self updateBorder];
}

- (void)setContainerBorderColor:(UIColor *)color {
  if ([_containerBorderColor isEqual:color])
    return;
  _containerBorderColor = color;
  [self updateBorder];
}

- (void)setBorderLeftWidth:(CGFloat)width {
  _borderLeftWidth = width;
  _leftBorderLayer.hidden = width <= 0;
  [self setNeedsLayout];
}

- (void)setBorderLeftColor:(UIColor *)color {
  _leftBorderLayer.backgroundColor = color.CGColor;
}

@end
