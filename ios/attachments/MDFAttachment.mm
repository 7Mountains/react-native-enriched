#import "MDFAttachment.h"
#import "AttachmentUtils.h"
#import "ColorExtension.h"
#import "EnrichedImageLoader.h"
#import "MDFParams.h"
#import "MDFStyleProps.h"
#import "RichImageLabelView.h"

@implementation MDFAttachment {
  RichImageLabelView *_view;
  MDFStyleProps *_styles;
  MDFParams *_params;
  BOOL _needsRedraw;
}

#pragma mark - Init

- (instancetype)initWithParams:(MDFParams *)params
                        styles:(MDFStyleProps *)styles {

  self = [super init];
  if (!self)
    return nil;

  _styles = styles;
  _params = params;

  return self;
}

#pragma mark - Build View

- (RichImageLabelView *)buildView {
  RichImageLabelView *view = [[RichImageLabelView alloc] init];

  view.minHeight = _styles.minHeight;

  view.backgroundColor = _styles.backgroundColor;
  view.containerBorderWidth = _styles.borderWidth;
  view.containerCornerRadius = _styles.borderRadius;
  view.containerBorderColor = _styles.borderColor;
  view.borderLeftWidth = _styles.borderLeftWidth;

  view.padding = _styles.padding;

  view.imageSize = _styles.imageSize;

  view.imageContainerCornerRadius = _styles.imageContainerBorderRadius;
  view.imageContainerSize = _styles.imageContainerSize;

  view.textPadding = _styles.textContainerPadding;
  view.textMargin = _styles.textContainerMargin;

  UIColor *tintColor =
      [UIColor colorFromString:_params.tintColor] ?: UIColor.clearColor;

  view.imageContainerColor = tintColor;
  view.borderLeftColor = tintColor;

  view.titleText = [[NSAttributedString alloc]
      initWithString:_params.label
          attributes:@{
            NSFontAttributeName : _styles.font ?: [UIFont systemFontOfSize:14],
            NSForegroundColorAttributeName : _styles.textColor
                ?: UIColor.labelColor
          }];

  view.image = MakeLoaderImage();

  [self loadImageAsyncWithURL:_styles.imageURL];

  return view;
}

- (RichImageLabelView *)view {
  if (!_view) {
    _view = [self buildView];
  }
  return _view;
}

#pragma mark - Layout

- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)textContainer
                      proposedLineFragment:(CGRect)lineFrag
                             glyphPosition:(CGPoint)position
                            characterIndex:(NSUInteger)charIndex {

  CGFloat padding = textContainer ? textContainer.lineFragmentPadding : 0.0;
  CGFloat width = lineFrag.size.width - padding * 2;

  CGSize contentSize = CGSizeMake(
      width - _styles.margin.left - _styles.margin.right, CGFLOAT_MAX);

  CGSize fitting = [self.view sizeThatFits:contentSize];

  CGFloat height = fitting.height + _styles.margin.top + _styles.margin.bottom;

  return CGRectMake(0, 0, width, height);
}

#pragma mark - Render

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

#pragma mark - Image

- (void)loadImageAsyncWithURL:(NSURL *)url {
  if (!url)
    return;

  __weak __typeof__(self) weakSelf = self;

  [[EnrichedImageLoader shared] loadImage:url
                               completion:^(UIImage *img) {
                                 __strong __typeof__(weakSelf) self = weakSelf;
                                 if (!self)
                                   return;

                                 dispatch_async(dispatch_get_main_queue(), ^{
                                   self.view.image = img;
                                   self->_needsRedraw = YES;
                                   [self notifyUpdate];
                                 });
                               }];
}

@end
