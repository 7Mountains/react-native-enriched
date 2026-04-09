#import "RichImageLabelView.h"

static const CGSize kDefaultImageSize = CGSizeMake(40.0, 40.0);
static const CGFloat kDefaultMinHeight = 56.0;
static const CGSize kDefaultImageContainerSize = CGSizeMake(56.0, 56.0);

@implementation RichImageLabelView {
  CALayer *_leftBorderLayer;
  UIView *_imageContainer;
  UIView *_textContainer;
  UIImageView *_imageView;
  UILabel *_titleLabel;
  UILabel *_descriptionLabel;
  UILabel *_subtitleLabel;
  UILabel *_subdescriptionLabel;

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
  _titleLabel.numberOfLines = 1;
  _titleLabel.textAlignment = NSTextAlignmentLeft;

  _imageSize = kDefaultImageSize;
  _minHeight = kDefaultMinHeight;
  _imageContainerSize = kDefaultImageContainerSize;

  _textPadding = UIEdgeInsetsZero;
  _textMargin = UIEdgeInsetsZero;

  _leftBorderLayer = [CALayer layer];

  [self.layer addSublayer:_leftBorderLayer];

  [_imageContainer addSubview:_imageView];
  [_textContainer addSubview:_titleLabel];

  [self addSubview:_imageContainer];
  [self addSubview:_textContainer];

  return self;
}

#pragma mark - Helpers

- (CGSize)sizeForLabel:(UILabel *_Nullable)label width:(CGFloat)width {
  if (!label || !label.attributedText.length || width <= 0)
    return CGSizeZero;

  CGRect rect = [label.attributedText
      boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                   options:NSStringDrawingUsesLineFragmentOrigin |
                           NSStringDrawingUsesFontLeading
                   context:nil];

  return CGSizeMake(ceil(rect.size.width), ceil(rect.size.height));
}

#pragma mark - Layout

- (CGFloat)calculateTextHeight:(CGFloat)textWidth {
  CGSize titleSize = [self sizeForLabel:_titleLabel width:textWidth];
  CGSize descSize = [self sizeForLabel:_descriptionLabel width:textWidth];
  CGSize subtitleSize = [self sizeForLabel:_subtitleLabel width:textWidth];
  CGSize subdescSize = [self sizeForLabel:_subdescriptionLabel width:textWidth];

  CGFloat height = 0;

  if (_titleLabel.attributedText.length > 0) {
    height += _titleMargin.top + titleSize.height + _titleMargin.bottom;
  }

  if (_descriptionLabel.attributedText.length > 0) {
    height +=
        _descriptionMargin.top + descSize.height + _descriptionMargin.bottom;
  }

  if (_subtitleLabel.attributedText.length > 0) {
    height +=
        _subtitleMargin.top + subtitleSize.height + _subtitleMargin.bottom;
  }

  if (_subdescriptionLabel.attributedText.length > 0) {
    height += _subdescriptionMargin.top + subdescSize.height +
              _subdescriptionMargin.bottom;
  }

  return height;
}

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

  CGFloat textHeight = [self calculateTextHeight:textWidth] + _textPadding.top +
                       _textPadding.bottom;

  CGFloat imageHeight =
      _imageContainerSize.height > 0 ? _imageContainerSize.height : 0;

  CGFloat contentHeight = MAX(textHeight, imageHeight);

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

  BOOL hasDesc = _descriptionLabel.attributedText.length > 0;
  BOOL hasSubtitle = _subtitleLabel.attributedText.length > 0;
  BOOL hasSubdesc = _subdescriptionLabel.attributedText.length > 0;

  CGSize titleSize = [self sizeForLabel:_titleLabel width:innerWidth];
  CGSize descSize = [self sizeForLabel:_descriptionLabel width:innerWidth];
  CGSize subtitleSize = [self sizeForLabel:_subtitleLabel width:innerWidth];
  CGSize subdescSize = [self sizeForLabel:_subdescriptionLabel
                                    width:innerWidth];

  CGFloat textHeight = [self calculateTextHeight:textWidth];

  CGFloat containerHeight =
      textHeight + self.textPadding.top + self.textPadding.bottom;

  CGFloat centerY = self.padding.top + contentHeight / 2.0;
  CGFloat containerY = centerY - containerHeight / 2.0;

  _textContainer.frame =
      CGRectMake(textX, containerY, textWidth, containerHeight);

  CGFloat contentX = self.textPadding.left;
  CGFloat currentY = self.textPadding.top;

  currentY += _titleMargin.top;

  _titleLabel.frame =
      CGRectMake(contentX, currentY, innerWidth, titleSize.height);

  currentY = CGRectGetMaxY(_titleLabel.frame) + _titleMargin.bottom;

  if (hasDesc) {
    currentY += _descriptionMargin.top;

    _descriptionLabel.frame =
        CGRectMake(contentX, currentY, innerWidth, descSize.height);

    currentY =
        CGRectGetMaxY(_descriptionLabel.frame) + _descriptionMargin.bottom;
  }

  if (hasSubtitle) {
    currentY += _subtitleMargin.top;

    _subtitleLabel.frame =
        CGRectMake(contentX, currentY, innerWidth, subtitleSize.height);

    currentY = CGRectGetMaxY(_subtitleLabel.frame) + _subtitleMargin.bottom;
  }

  if (hasSubdesc) {
    currentY += _subdescriptionMargin.top;

    _subdescriptionLabel.frame =
        CGRectMake(contentX, currentY, innerWidth, subdescSize.height);

    currentY = CGRectGetMaxY(_subdescriptionLabel.frame) +
               _subdescriptionMargin.bottom;
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
  if (_descriptionLabel == nil) {
    _descriptionLabel = [UILabel new];
    _descriptionLabel.numberOfLines = 0;
    _descriptionLabel.textAlignment = NSTextAlignmentLeft;
  }

  if (descriptionText.length > 0 && !_descriptionLabel.superview) {
    [_textContainer addSubview:_descriptionLabel];
  }

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

- (void)setSubTitleText:(NSAttributedString *)subtitleText {
  if (!_subtitleLabel) {
    _subtitleLabel = [UILabel new];
    _subtitleLabel.numberOfLines = 1;
    _subtitleLabel.textAlignment = NSTextAlignmentLeft;
  }

  _subtitleLabel.attributedText = subtitleText;

  if (subtitleText.length > 0 && !_subtitleLabel.superview) {
    [_textContainer addSubview:_subtitleLabel];
  }

  [self setNeedsLayout];
}

- (void)setSubDescriptionText:(NSAttributedString *)subdescriptionText {
  if (!_subdescriptionLabel) {
    _subdescriptionLabel = [UILabel new];
    _subdescriptionLabel.numberOfLines = 0;
    _subdescriptionLabel.textAlignment = NSTextAlignmentLeft;
  }

  _subdescriptionLabel.attributedText = subdescriptionText;

  if (subdescriptionText.length > 0 && !_subdescriptionLabel.superview) {
    [_textContainer addSubview:_subdescriptionLabel];
  }

  [self setNeedsLayout];
}

@end
