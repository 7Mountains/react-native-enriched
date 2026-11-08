#import "EnrichedText.h"
#import "ColorExtension.h"
#import "EnrichedPreparedText.h"
#import "EnrichedTextBuilder.h"
#import "EnrichedTextPressRecognizer.h"
#import "EnrichedTextShadowNode.h"
#import "MediaAttachment.h"
#import "MentionParams.h"
#import "StringExtension.h"
#import "StyleHeaders.h"
#import <React/RCTConversions.h>
#import <React/RCTSurfaceTouchHandler.h>
#import <ReactNativeEnriched/EnrichedTextComponentDescriptor.h>
#import <react/renderer/components/RNEnrichedTextInputViewSpec/EventEmitters.h>
#import <react/renderer/components/RNEnrichedTextInputViewSpec/Props.h>
#import <react/utils/ManagedObjectWrapper.h>

using namespace facebook::react;

typedef NS_ENUM(NSInteger, EnrichedTextPressEvent) {
  EnrichedTextPressEventPressIn,
  EnrichedTextPressEventPressOut,
  EnrichedTextPressEventPress,
  EnrichedTextPressEventLongPress,
};

static const CGFloat kPressedAlpha = 0.2;
static const CGFloat kPressedCornerRadius = 4;

template <typename MentionEvent>
static MentionEvent mentionEventFrom(MentionParams *mention) {
  folly::dynamic attributes = folly::dynamic::object();

  for (NSString *key in mention.extraAttributes) {
    id value = mention.extraAttributes[key];
    NSString *string =
        [value isKindOfClass:NSString.class] ? value : [value description];
    attributes[[key toCppString]] = [string toCppString];
  }

  return MentionEvent{
      .text = [mention.text toCppString],
      .indicator = [mention.indicator toCppString],
      .type = [mention.type toCppString],
      .attributes = attributes,
  };
}

@interface EnrichedText () <EnrichedTextPressRecognizerDelegate,
                            UIGestureRecognizerDelegate,
                            MediaAttachmentDelegate>
@end

@implementation EnrichedText {
  UILabel *_label;
  NSTextStorage *_textStorage;
  NSLayoutManager *_layoutManager;
  NSTextContainer *_textContainer;
  EnrichedPreparedText *_preparedText;
  EnrichedTextPressRecognizer *_pressRecognizer;
  CAShapeLayer *_pressLayer;
  NSInteger _numberOfLines;
  NSLineBreakMode _lineBreakMode;
  BOOL _pressableLinks;
  BOOL _pressableMentions;
  BOOL _longPressableLinks;
  BOOL _longPressableMentions;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<EnrichedTextComponentDescriptor>();
}

Class<RCTComponentViewProtocol> EnrichedTextCls(void) {
  return EnrichedText.class;
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps =
        std::make_shared<const EnrichedTextProps>();
    _props = defaultProps;
    _lineBreakMode = NSLineBreakByTruncatingTail;

    _label = [[UILabel alloc] initWithFrame:CGRectZero];
    _label.backgroundColor = UIColor.clearColor;
    _label.numberOfLines = 0;
    _label.lineBreakMode = NSLineBreakByWordWrapping;
    _label.userInteractionEnabled = YES;
    _label.isAccessibilityElement = YES;
    [self addSubview:_label];

    _textStorage = [[NSTextStorage alloc] init];
    _layoutManager = [[NSLayoutManager alloc] init];
    _textContainer =
        [[NSTextContainer alloc] initWithSize:CGSizeMake(0, CGFLOAT_MAX)];
    [EnrichedTextBuilder configureTextContainer:_textContainer
                           maximumNumberOfLines:_numberOfLines
                                  lineBreakMode:_lineBreakMode];
    [_layoutManager addTextContainer:_textContainer];
    [_textStorage addLayoutManager:_layoutManager];

    _pressLayer = [CAShapeLayer layer];
    [_label.layer insertSublayer:_pressLayer atIndex:0];

    _pressRecognizer = [[EnrichedTextPressRecognizer alloc] init];
    _pressRecognizer.pressDelegate = self;
    _pressRecognizer.delegate = self;
    [_label addGestureRecognizer:_pressRecognizer];
  }
  return self;
}

- (void)updateProps:(Props::Shared const &)props
           oldProps:(Props::Shared const &)oldProps {
  const auto &newProps =
      *std::static_pointer_cast<const EnrichedTextProps>(props);

  NSLineBreakMode lineBreakMode =
      EnrichedNSLineBreakModeFromEllipsizeMode(newProps.ellipsizeMode);
  if (newProps.numberOfLines != _numberOfLines ||
      lineBreakMode != _lineBreakMode) {
    _numberOfLines = newProps.numberOfLines;
    _lineBreakMode = lineBreakMode;
    _label.numberOfLines = MAX(_numberOfLines, 0);
    _label.lineBreakMode =
        _numberOfLines > 0 ? _lineBreakMode : NSLineBreakByWordWrapping;
    [EnrichedTextBuilder configureTextContainer:_textContainer
                           maximumNumberOfLines:_numberOfLines
                                  lineBreakMode:_lineBreakMode];
  }

  _pressableLinks = newProps.pressableLinks;
  _pressableMentions = newProps.pressableMentions;
  _longPressableLinks = newProps.longPressableLinks;
  _longPressableMentions = newProps.longPressableMentions;
  _pressRecognizer.enabled = _pressableLinks || _pressableMentions;

  [super updateProps:props oldProps:oldProps];
}

- (void)updateState:(State::Shared const &)state
           oldState:(State::Shared const &)oldState {
  auto textState =
      std::static_pointer_cast<const EnrichedTextShadowNode::ConcreteState>(
          state);
  EnrichedPreparedText *preparedText =
      textState != nullptr ? (EnrichedPreparedText *)unwrapManagedObject(
                                 textState->getData().getPreparedText())
                           : nil;

  if (preparedText == nil) {
    const auto &props =
        *std::static_pointer_cast<const EnrichedTextProps>(_props);
    preparedText = [EnrichedTextBuilder preparedTextWithLabelProps:props
                                                fontSizeMultiplier:1];
  }

  [self setPreparedText:preparedText];
}

- (void)setPreparedText:(EnrichedPreparedText *)preparedText {
  if (preparedText == _preparedText) {
    return;
  }

  [self cancelCurrentPress];
  _preparedText = preparedText;
  NSAttributedString *text =
      preparedText.text ?: [[NSAttributedString alloc] init];
  _label.attributedText = text;
  [_textStorage setAttributedString:text];
  _label.accessibilityLabel = text.string;

  [_textStorage enumerateAttribute:NSAttachmentAttributeName
                           inRange:NSMakeRange(0, _textStorage.length)
                           options:0
                        usingBlock:^(id value, NSRange range, BOOL *stop) {
                          if ([value isKindOfClass:[MediaAttachment class]]) {
                            ((MediaAttachment *)value).delegate = self;
                          }
                        }];
}

- (void)updateLayoutMetrics:(const LayoutMetrics &)layoutMetrics
           oldLayoutMetrics:(const LayoutMetrics &)oldLayoutMetrics {
  [super updateLayoutMetrics:layoutMetrics oldLayoutMetrics:oldLayoutMetrics];

  CGRect contentFrame = RCTCGRectFromRect(layoutMetrics.getContentFrame());
  _label.frame = contentFrame;
  _textContainer.size = CGSizeMake(contentFrame.size.width, CGFLOAT_MAX);
}

- (void)prepareForRecycle {
  [super prepareForRecycle];
  [self cancelCurrentPress];
  _preparedText = nil;
  _label.attributedText = nil;
  [_textStorage setAttributedString:[[NSAttributedString alloc] init]];
}

- (void)mediaAttachmentDidUpdate:(MediaAttachment *)attachment {
  [_layoutManager
      invalidateDisplayForCharacterRange:NSMakeRange(0, _textStorage.length)];
  [_label setNeedsDisplay];
}

- (EnrichedTextPressableRange *)
          pressRecognizer:(EnrichedTextPressRecognizer *)pressRecognizer
    pressableRangeAtPoint:(CGPoint)point {
  if (!_pressableLinks && !_pressableMentions) {
    return nil;
  }

  NSUInteger index = [self characterIndexAtPoint:point];
  if (index == NSNotFound) {
    return nil;
  }

  NSRange textRange = NSMakeRange(0, _textStorage.length);
  NSRange range;
  if (_pressableLinks) {
    id url = [_textStorage attribute:[LinkStyle attributeKey]
                             atIndex:index
               longestEffectiveRange:&range
                             inRange:textRange];
    if ([url isKindOfClass:NSString.class]) {
      EnrichedTextPressableRange *link = [EnrichedTextPressableRange new];
      link.range = range;
      link.url = url;
      return link;
    }
  }

  if (_pressableMentions) {
    id mention = [_textStorage attribute:[MentionStyle attributeKey]
                                 atIndex:index
                   longestEffectiveRange:&range
                                 inRange:textRange];
    if ([mention isKindOfClass:MentionParams.class]) {
      EnrichedTextPressableRange *mentionRange =
          [EnrichedTextPressableRange new];
      mentionRange.range = range;
      mentionRange.mention = mention;
      return mentionRange;
    }
  }

  return nil;
}

- (BOOL)pressRecognizer:(EnrichedTextPressRecognizer *)pressRecognizer
                  range:(EnrichedTextPressableRange *)range
          containsPoint:(CGPoint)point {
  __block BOOL containsPoint = NO;
  [self enumerateRectsForRange:range
                    usingBlock:^(CGRect rect, BOOL *stop) {
                      if (CGRectContainsPoint(rect, point)) {
                        containsPoint = YES;
                        *stop = YES;
                      }
                    }];
  return containsPoint;
}

- (BOOL)pressRecognizer:(EnrichedTextPressRecognizer *)pressRecognizer
      canLongPressRange:(EnrichedTextPressableRange *)range {
  return [self canLongPressRange:range];
}

- (void)pressRecognizer:(EnrichedTextPressRecognizer *)pressRecognizer
    didBeginPressingRange:(EnrichedTextPressableRange *)range {
  [self setHighlightedRange:range];
  [self emitEvent:EnrichedTextPressEventPressIn forRange:range];
  [self cancelReactTouches];
}

- (void)pressRecognizer:(EnrichedTextPressRecognizer *)pressRecognizer
    didEndPressingRange:(EnrichedTextPressableRange *)range {
  [self setHighlightedRange:nil];
  [self emitEvent:EnrichedTextPressEventPressOut forRange:range];
}

- (void)pressRecognizer:(EnrichedTextPressRecognizer *)pressRecognizer
            didTapRange:(EnrichedTextPressableRange *)range {
  [self emitEvent:EnrichedTextPressEventPress forRange:range];
}

- (void)pressRecognizer:(EnrichedTextPressRecognizer *)pressRecognizer
      didLongPressRange:(EnrichedTextPressableRange *)range {
  [self emitEvent:EnrichedTextPressEventLongPress forRange:range];
}

- (BOOL)canLongPressRange:(EnrichedTextPressableRange *)range {
  return range.url != nil ? _longPressableLinks : _longPressableMentions;
}

- (NSUInteger)characterIndexAtPoint:(CGPoint)point {
  if (_textStorage.length == 0) {
    return NSNotFound;
  }

  NSUInteger glyphIndex = [_layoutManager glyphIndexForPoint:point
                                             inTextContainer:_textContainer
                              fractionOfDistanceThroughGlyph:NULL];
  CGRect glyphRect =
      [_layoutManager boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1)
                                inTextContainer:_textContainer];
  if (!CGRectContainsPoint(glyphRect, point)) {
    return NSNotFound;
  }
  return [_layoutManager characterIndexForGlyphAtIndex:glyphIndex];
}

- (void)enumerateRectsForRange:(EnrichedTextPressableRange *)range
                    usingBlock:(void (^)(CGRect rect, BOOL *stop))block {
  NSRange glyphRange = [_layoutManager glyphRangeForCharacterRange:range.range
                                              actualCharacterRange:NULL];
  [_layoutManager
      enumerateEnclosingRectsForGlyphRange:glyphRange
                  withinSelectedGlyphRange:NSMakeRange(NSNotFound, 0)
                           inTextContainer:_textContainer
                                usingBlock:block];
}

- (void)cancelReactTouches {
  __weak EnrichedText *weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    EnrichedText *strongSelf = weakSelf;
    if (strongSelf == nil || strongSelf->_pressRecognizer.pressedRange == nil) {
      return;
    }
    for (UIView *view = strongSelf.superview; view != nil;
         view = view.superview) {
      for (UIGestureRecognizer *recognizer in view.gestureRecognizers) {
        if ([recognizer isKindOfClass:[RCTSurfaceTouchHandler class]]) {
          recognizer.enabled = NO;
          recognizer.enabled = YES;
          return;
        }
      }
    }
  });
}

- (void)cancelCurrentPress {
  EnrichedTextPressableRange *range = _pressRecognizer.pressedRange;
  if (range == nil) {
    return;
  }
  _pressRecognizer.enabled = NO;
  _pressRecognizer.enabled = YES;
  [self pressRecognizer:_pressRecognizer didEndPressingRange:range];
}

- (void)setHighlightedRange:(nullable EnrichedTextPressableRange *)range {
  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  if (range == nil) {
    _pressLayer.path = nil;
  } else {
    UIBezierPath *path = [UIBezierPath bezierPath];
    [self enumerateRectsForRange:range
                      usingBlock:^(CGRect rect, BOOL *stop) {
                        [path appendPath:
                                  [UIBezierPath
                                      bezierPathWithRoundedRect:rect
                                                   cornerRadius:
                                                       kPressedCornerRadius]];
                      }];
    UIColor *color = [_textStorage attribute:NSForegroundColorAttributeName
                                     atIndex:range.range.location
                              effectiveRange:NULL]
                         ?: UIColor.labelColor;
    _pressLayer.fillColor =
        [[color resolvedColorWithTraitCollection:self.traitCollection]
            colorWithAlphaIfNotTransparent:kPressedAlpha]
            .CGColor;
    _pressLayer.path = path.CGPath;
  }
  [CATransaction commit];
}

- (void)emitEvent:(EnrichedTextPressEvent)event
         forRange:(EnrichedTextPressableRange *)range {
  auto eventEmitter =
      std::static_pointer_cast<const EnrichedTextEventEmitter>(_eventEmitter);
  if (eventEmitter == nullptr) {
    return;
  }

  if (range.url != nil) {
    std::string url = [range.url toCppString];
    switch (event) {
    case EnrichedTextPressEventPressIn:
      eventEmitter->onLinkPressIn({.url = url});
      break;
    case EnrichedTextPressEventPressOut:
      eventEmitter->onLinkPressOut({.url = url});
      break;
    case EnrichedTextPressEventPress:
      eventEmitter->onLinkPress({.url = url});
      break;
    case EnrichedTextPressEventLongPress:
      eventEmitter->onLinkLongPress({.url = url});
      break;
    }
    return;
  }

  MentionParams *mention = range.mention;
  switch (event) {
  case EnrichedTextPressEventPressIn:
    eventEmitter->onMentionPressIn(
        mentionEventFrom<EnrichedTextEventEmitter::OnMentionPressIn>(mention));
    break;
  case EnrichedTextPressEventPressOut:
    eventEmitter->onMentionPressOut(
        mentionEventFrom<EnrichedTextEventEmitter::OnMentionPressOut>(mention));
    break;
  case EnrichedTextPressEventPress:
    eventEmitter->onMentionPress(
        mentionEventFrom<EnrichedTextEventEmitter::OnMentionPress>(mention));
    break;
  case EnrichedTextPressEventLongPress:
    eventEmitter->onMentionLongPress(
        mentionEventFrom<EnrichedTextEventEmitter::OnMentionLongPress>(
            mention));
    break;
  }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:
        (UIGestureRecognizer *)otherGestureRecognizer {
  if (gestureRecognizer != _pressRecognizer) {
    return NO;
  }
  UIView *otherView = otherGestureRecognizer.view;
  return [otherView isKindOfClass:[UIScrollView class]] &&
         otherGestureRecognizer ==
             ((UIScrollView *)otherView).panGestureRecognizer;
}

@end
