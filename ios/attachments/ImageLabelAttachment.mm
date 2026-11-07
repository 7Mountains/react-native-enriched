#import "ImageLabelAttachment.h"
#import "AttachmentUtils.h"
#import "ContentParams.h"
#import "ContentStyleProps.h"
#import "EnrichedImageLoader.h"
#import "ImageLayoutUtils.h"
#import "RichImageLabelView.h"

@implementation ImageLabelAttachment {
  ImageResizeMode _imageResizeMode;
  RichImageLabelView *_view;
  UIImage *_contentImage;
  ContentStyleProps *_styles;
  ContentParams *_params;
  RichImageLabelMetrics *_metrics;
  BOOL _needsRedraw;
}

#pragma mark - Init

- (instancetype)initWithParams:(ContentParams *)params
                        styles:(ContentStyleProps *)styles {
  self = [super init];
  if (!self)
    return nil;

  _styles = styles;
  _params = params;
  _metrics = [self buildMetrics];
  self.image = nil;

  return self;
}

// Built once: the bounds are measured on any thread, from the metrics
- (RichImageLabelMetrics *)buildMetrics {
  RichImageLabelMetrics *metrics = [RichImageLabelMetrics new];

  metrics.minHeight = _styles.minHeight;
  metrics.padding = _styles.padding;
  metrics.textPadding = _styles.textContainerPadding;
  metrics.textMargin = _styles.textContainerMargin;
  metrics.imageContainerSize = _styles.imageContainerSize;

  metrics.titleMargin = _styles.titleMargin;
  metrics.descriptionMargin = _styles.descriptionMargin;
  metrics.subtitleMargin = _styles.subtitleMargin;
  metrics.subdescriptionMargin = _styles.subdescriptionMargin;

  metrics.titleText = [[NSAttributedString alloc]
      initWithString:_params.title
          attributes:@{
            NSFontAttributeName : _styles.titleFont,
            NSForegroundColorAttributeName : _styles.titleColor
          }];

  if ([_params.descriptionText isKindOfClass:NSString.class] &&
      _params.descriptionText.length > 0) {
    metrics.descriptionText = [[NSAttributedString alloc]
        initWithString:_params.descriptionText
            attributes:@{
              NSFontAttributeName : _styles.descriptionFont,
              NSForegroundColorAttributeName : _styles.descriptionColor
            }];
  }

  if ([_params.subTitle isKindOfClass:NSString.class]) {
    metrics.subTitleText = [[NSAttributedString alloc]
        initWithString:_params.subTitle
            attributes:@{
              NSFontAttributeName : _styles.subTitleFont,
              NSForegroundColorAttributeName : _styles.subTitleColor
            }];
  }

  if ([_params.subDescriptionText isKindOfClass:NSString.class]) {
    metrics.subDescriptionText = [[NSAttributedString alloc]
        initWithString:_params.subDescriptionText
            attributes:@{
              NSFontAttributeName : _styles.subDescriptionFont,
              NSForegroundColorAttributeName : _styles.subdescriptionColor
            }];
  }

  return metrics;
}

- (RichImageLabelView *)buildView {
  [self loadImageAsyncWithURI:_params.url];
  RichImageLabelView *view = [[RichImageLabelView alloc] init];

  [view applyMetrics:_metrics];

  view.layer.backgroundColor = _styles.backgroundColor.CGColor;
  view.containerBorderWidth = _styles.borderWidth;
  view.containerCornerRadius = _styles.borderRadius;
  view.containerBorderColor = _styles.borderColor;
  view.borderStyle = _styles.borderStyle;

  view.imageSize = _styles.imageSize;
  view.imageContainerColor = _styles.imageContainerBackgroundColor;

  view.image = MakeLoaderImage();

  return view;
}

- (RichImageLabelView *)view {
  if (!_view) {
    _view = [self buildView];
  }
  return _view;
}

- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)textContainer
                      proposedLineFragment:(CGRect)lineFrag
                             glyphPosition:(CGPoint)position
                            characterIndex:(NSUInteger)charIndex {
  CGFloat padding = textContainer ? textContainer.lineFragmentPadding : 0.0;
  CGFloat width = lineFrag.size.width - padding * 2;

  CGSize contentSize = CGSizeMake(
      width - _styles.margin.left - _styles.margin.right, CGFLOAT_MAX);

  // Not with the view: the bounds are measured off the main thread too
  CGSize fitting = [_metrics sizeThatFits:contentSize];

  CGFloat height = fitting.height + _styles.margin.top + _styles.margin.bottom;

  return CGRectMake(0, 0, width, height);
}

- (UIImage *)imageForBounds:(CGRect)imageBounds
              textContainer:(NSTextContainer *)textContainer
             characterIndex:(NSUInteger)charIndex {
  if (!_needsRedraw && self.image) {
    return self.image;
  }

  _needsRedraw = NO;

  CGSize contentSize = CGSizeMake(imageBounds.size.width - _styles.margin.left -
                                      _styles.margin.right,
                                  CGFLOAT_MAX);

  CGSize fitting = [self.view sizeThatFits:contentSize];
  CGSize finalSize =
      CGSizeMake(imageBounds.size.width,
                 fitting.height + _styles.margin.top + _styles.margin.bottom);

  UIGraphicsImageRenderer *renderer =
      [[UIGraphicsImageRenderer alloc] initWithSize:finalSize];

  self.image =
      [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        self.view.frame = CGRectMake(0, 0, fitting.width, fitting.height);

        CGContextRef cg = context.CGContext;
        CGContextSaveGState(cg);
        CGContextTranslateCTM(cg, _styles.margin.left, _styles.margin.top);
        [self.view.layer renderInContext:cg];
        CGContextRestoreGState(cg);
      }];

  return self.image;
}

- (void)updateImage:(UIImage *)image {
  dispatch_async(dispatch_get_main_queue(), ^{
    self.view.image = image;

    UIImageView *imageView = [self.view viewWithTag:1001];
    if ([imageView isKindOfClass:[UIImageView class]]) {
      imageView.image = image;
    }

    self->_needsRedraw = YES;

    [self notifyUpdate];
  });
}

#pragma mark - Image Loading

- (void)loadImageAsyncWithURI:(NSString *)uri {
  __weak __typeof__(self) weakSelf = self;

  if (!uri.length)
    return;

  NSURL *url = [NSURL URLWithString:uri];

  [[EnrichedImageLoader shared]
       loadImage:url
      completion:^(UIImage *img) {
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if (!strongSelf)
          return;

        if (!img && strongSelf->_styles.fallbackImageURL) {
          NSURL *fallbackURL = strongSelf->_styles.fallbackImageURL;
          [[EnrichedImageLoader shared] loadImage:fallbackURL
                                       completion:^(UIImage *fallbackImage) {
                                         [strongSelf updateImage:fallbackImage];
                                       }];
          return;
        };

        [strongSelf updateImage:img];
      }];
}

@end
