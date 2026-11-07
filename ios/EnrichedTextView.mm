#import "EnrichedTextView.h"
#import "AttachmentInvalidationBatcher.h"
#import "ColorExtension.h"
#import "EnrichedPreparedText.h"
#import "EnrichedTextAccessibilityElement.h"
#import "EnrichedTextBuilder.h"
#import "EnrichedTextPressRecognizer.h"
#import "EnrichedTextStyleFactory.h"
#import "InputConfig.h"
#import "LayoutManagerExtension.h"
#import "MediaAttachment.h"
#import "MentionParams.h"
#import "StringExtension.h"
#import "StyleHeaders.h"
#import <React/RCTConversions.h>
#import <React/RCTSurfaceTouchHandler.h>
#import <ReactNativeEnriched/EnrichedTextViewComponentDescriptor.h>
#import <react/renderer/components/RNEnrichedTextInputViewSpec/EventEmitters.h>
#import <react/renderer/components/RNEnrichedTextInputViewSpec/Props.h>
#import <react/utils/ManagedObjectWrapper.h>

using namespace facebook::react;

// The events of a press on a link or a mention, as named in JS
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

@interface EnrichedTextView () <EnrichedTextAccessibilityContainer,
                                EnrichedTextPressRecognizerDelegate,
                                UIGestureRecognizerDelegate>
@end

@implementation EnrichedTextView {
  UITextView *_textView;
  NSTextStorage *_textStorage;
  EnrichedPreparedText *_preparedText;
  NSDictionary<NSNumber *, id> *_stylesDict;
  AttachmentInvalidationBatcher *_attachmentBatcher;
  EnrichedTextPressRecognizer *_pressRecognizer;
  CAShapeLayer *_pressLayer;
  NSInteger _numberOfLines;
  NSLineBreakMode _lineBreakMode;
  BOOL _pressableLinks;
  BOOL _pressableMentions;
  BOOL _longPressableLinks;
  BOOL _longPressableMentions;
  NSArray<EnrichedTextAccessibilityElement *> *_accessibilityElements;
}

// MARK: - Component utils

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<
      EnrichedTextViewComponentDescriptor>();
}

Class<RCTComponentViewProtocol> EnrichedTextViewCls(void) {
  return EnrichedTextView.class;
}

// MARK: - Init

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps =
        std::make_shared<const EnrichedTextViewProps>();
    _props = defaultProps;
    _lineBreakMode = NSLineBreakByTruncatingTail;

    [self setupTextView];

    // For the drawing of the lists, quotes, code blocks and checkboxes
    _stylesDict = [EnrichedTextStyleFactory makeStylesWithInput:self];
    _attachmentBatcher =
        [[AttachmentInvalidationBatcher alloc] initWithTextView:_textView];
  }
  return self;
}

- (void)setupTextView {
  // TextKit 1, as the measurement (EnrichedTextBuilder) and the drawing of
  // the paragraphs (LayoutManagerExtension)
  _textStorage = [[NSTextStorage alloc] init];
  NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
  NSTextContainer *textContainer =
      [[NSTextContainer alloc] initWithSize:CGSizeMake(0, CGFLOAT_MAX)];
  textContainer.widthTracksTextView = NO;
  textContainer.heightTracksTextView = NO;
  [EnrichedTextBuilder configureTextContainer:textContainer
                         maximumNumberOfLines:_numberOfLines
                                lineBreakMode:_lineBreakMode];
  [layoutManager addTextContainer:textContainer];
  [_textStorage addLayoutManager:layoutManager];

  _textView = [[UITextView alloc] initWithFrame:CGRectZero
                                  textContainer:textContainer];
  _textView.editable = NO;
  _textView.selectable = NO;
  _textView.scrollEnabled = NO;
  _textView.backgroundColor = UIColor.clearColor;
  _textView.textContainerInset = UIEdgeInsetsZero;
  _textView.dataDetectorTypes = UIDataDetectorTypeNone;
  _textView.textDragInteraction.enabled = NO;
  _textView.layoutManager.input = self;
  [self addSubview:_textView];

  // Behind the text
  _pressLayer = [CAShapeLayer layer];
  [_textView.layer insertSublayer:_pressLayer atIndex:0];

  _pressRecognizer = [[EnrichedTextPressRecognizer alloc] init];
  _pressRecognizer.pressDelegate = self;
  _pressRecognizer.delegate = self;
  [_textView addGestureRecognizer:_pressRecognizer];
}

// MARK: - Style host

- (UITextView *)textView {
  return _textView;
}

- (InputConfig *)config {
  return _preparedText.config;
}

- (NSDictionary<NSAttributedStringKey, id> *)defaultTypingAttributes {
  return nil;
}

- (NSDictionary<NSNumber *, id> *)stylesDict {
  return _stylesDict;
}

- (void)mediaAttachmentDidUpdate:(MediaAttachment *)attachment {
  [_attachmentBatcher enqueueAttachment:attachment];
}

// MARK: - Props

- (void)updateProps:(Props::Shared const &)props
           oldProps:(Props::Shared const &)oldProps {
  const auto &newProps =
      *std::static_pointer_cast<const EnrichedTextViewProps>(props);

  NSLineBreakMode lineBreakMode =
      EnrichedNSLineBreakModeFromEllipsizeMode(newProps.ellipsizeMode);

  if (newProps.numberOfLines != _numberOfLines ||
      lineBreakMode != _lineBreakMode) {
    _numberOfLines = newProps.numberOfLines;
    _lineBreakMode = lineBreakMode;
    [EnrichedTextBuilder configureTextContainer:_textView.textContainer
                           maximumNumberOfLines:_numberOfLines
                                  lineBreakMode:_lineBreakMode];
  }

  if (_textView.selectable != newProps.selectable) {
    _textView.selectable = newProps.selectable;
    _textView.textDragInteraction.enabled = NO;
  }

  _textView.tintColor = RCTUIColorFromSharedColor(newProps.selectionColor);

  _pressableLinks = newProps.pressableLinks;
  _pressableMentions = newProps.pressableMentions;
  _longPressableLinks = newProps.longPressableLinks;
  _longPressableMentions = newProps.longPressableMentions;
  _accessibilityElements = nil;

  [super updateProps:props oldProps:oldProps];
}

// MARK: - State

// The text comes with every change of the props it's built from, after them
- (void)updateState:(State::Shared const &)state
           oldState:(State::Shared const &)oldState {
  auto textState =
      std::static_pointer_cast<const EnrichedTextViewShadowNode::ConcreteState>(
          state);

  EnrichedPreparedText *preparedText =
      textState != nullptr ? (EnrichedPreparedText *)unwrapManagedObject(
                                 textState->getData().getPreparedText())
                           : nil;

  if (preparedText == nil) {
    const auto &props =
        *std::static_pointer_cast<const EnrichedTextViewProps>(_props);
    preparedText = [EnrichedTextBuilder preparedTextWithProps:props
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
  [_textStorage setAttributedString:preparedText.text];
  _accessibilityElements = nil;

  // Built for a host without a view: the attachments are redrawn by this one
  // once their images load
  [_textStorage enumerateAttribute:NSAttachmentAttributeName
                           inRange:NSMakeRange(0, _textStorage.length)
                           options:0
                        usingBlock:^(id value, NSRange range, BOOL *stop) {
                          if ([value isKindOfClass:[MediaAttachment class]]) {
                            ((MediaAttachment *)value).delegate = self;
                          }
                        }];
}

// MARK: - Layout

- (void)updateLayoutMetrics:(const LayoutMetrics &)layoutMetrics
           oldLayoutMetrics:(const LayoutMetrics &)oldLayoutMetrics {
  [super updateLayoutMetrics:layoutMetrics oldLayoutMetrics:oldLayoutMetrics];

  // The measured text, inside the padding and the border
  CGRect contentFrame = RCTCGRectFromRect(layoutMetrics.getContentFrame());
  _textView.frame = contentFrame;
  _textView.textContainer.size =
      CGSizeMake(contentFrame.size.width, CGFLOAT_MAX);
  _accessibilityElements = nil;
}

- (void)prepareForRecycle {
  [super prepareForRecycle];

  [self cancelCurrentPress];
  _preparedText = nil;
  [_textStorage setAttributedString:[[NSAttributedString alloc] init]];
  _accessibilityElements = nil;
}

// MARK: - Press recognizer delegate

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
      EnrichedTextPressableRange *link =
          [[EnrichedTextPressableRange alloc] init];
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
          [[EnrichedTextPressableRange alloc] init];
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

// MARK: - Presses

- (BOOL)canLongPressRange:(EnrichedTextPressableRange *)range {
  return range.url != nil ? _longPressableLinks : _longPressableMentions;
}

// The character under the point: the nearest glyph only when it's touched
- (NSUInteger)characterIndexAtPoint:(CGPoint)point {
  if (_textStorage.length == 0) {
    return NSNotFound;
  }

  NSLayoutManager *layoutManager = _textView.layoutManager;
  NSTextContainer *textContainer = _textView.textContainer;
  UIEdgeInsets inset = _textView.textContainerInset;
  CGPoint containerPoint =
      CGPointMake(point.x - inset.left, point.y - inset.top);

  NSUInteger glyphIndex = [layoutManager glyphIndexForPoint:containerPoint
                                            inTextContainer:textContainer
                             fractionOfDistanceThroughGlyph:NULL];
  CGRect glyphRect =
      [layoutManager boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1)
                               inTextContainer:textContainer];

  if (!CGRectContainsPoint(glyphRect, containerPoint)) {
    return NSNotFound;
  }

  return [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
}

- (void)enumerateRectsForRange:(EnrichedTextPressableRange *)range
                    usingBlock:(void (^)(CGRect rect, BOOL *stop))block {
  NSLayoutManager *layoutManager = _textView.layoutManager;
  UIEdgeInsets inset = _textView.textContainerInset;
  NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:range.range
                                             actualCharacterRange:NULL];

  [layoutManager
      enumerateEnclosingRectsForGlyphRange:glyphRange
                  withinSelectedGlyphRange:NSMakeRange(NSNotFound, 0)
                           inTextContainer:_textView.textContainer
                                usingBlock:^(CGRect rect, BOOL *stop) {
                                  block(
                                      CGRectOffset(rect, inset.left, inset.top),
                                      stop);
                                }];
}

- (void)cancelReactTouches {
  __weak EnrichedTextView *weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    EnrichedTextView *strongSelf = weakSelf;
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

// A press of the previous text, or of a recycled view, ends
- (void)cancelCurrentPress {
  EnrichedTextPressableRange *range = _pressRecognizer.pressedRange;
  if (range == nil) {
    return;
  }

  _pressRecognizer.enabled = NO;
  _pressRecognizer.enabled = YES;
  [self pressRecognizer:_pressRecognizer didEndPressingRange:range];
}

// Behind the text of the range, in its color
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
      std::static_pointer_cast<const EnrichedTextViewEventEmitter>(
          _eventEmitter);
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
        mentionEventFrom<EnrichedTextViewEventEmitter::OnMentionPressIn>(
            mention));
    break;
  case EnrichedTextPressEventPressOut:
    eventEmitter->onMentionPressOut(
        mentionEventFrom<EnrichedTextViewEventEmitter::OnMentionPressOut>(
            mention));
    break;
  case EnrichedTextPressEventPress:
    eventEmitter->onMentionPress(
        mentionEventFrom<EnrichedTextViewEventEmitter::OnMentionPress>(
            mention));
    break;
  case EnrichedTextPressEventLongPress:
    eventEmitter->onMentionLongPress(
        mentionEventFrom<EnrichedTextViewEventEmitter::OnMentionLongPress>(
            mention));
    break;
  }
}

// MARK: - Accessibility

// The text is read by its elements: the whole text, then its links and
// mentions, which VoiceOver can press
- (BOOL)isAccessibilityElement {
  return NO;
}

- (NSArray *)accessibilityElements {
  if (_accessibilityElements == nil) {
    _accessibilityElements = [self buildAccessibilityElements];
  }

  return _accessibilityElements;
}

- (NSArray<EnrichedTextAccessibilityElement *> *)buildAccessibilityElements {
  if (_textStorage.length == 0) {
    return @[];
  }

  CGRect textFrame = _textView.frame;
  NSMutableArray<EnrichedTextAccessibilityElement *> *elements =
      [NSMutableArray array];

  EnrichedTextAccessibilityElement *textElement =
      [[EnrichedTextAccessibilityElement alloc]
          initWithAccessibilityContainer:self];
  NSString *label = super.accessibilityLabel;
  textElement.accessibilityLabel =
      label.length > 0 ? label : _textStorage.string;
  textElement.accessibilityTraits =
      super.accessibilityTraits | UIAccessibilityTraitStaticText;
  textElement.accessibilityFrameInContainerSpace = textFrame;
  // Off the links and the mentions, as React Native's Text
  textElement.activationPointInContainerSpace =
      CGPointMake(CGRectGetMinX(textFrame) + 1, CGRectGetMinY(textFrame) + 1);
  [elements addObject:textElement];

  for (EnrichedTextPressableRange *range in [self pressableRanges]) {
    __block CGRect frame = CGRectNull;
    __block CGRect firstRect = CGRectNull;

    [self enumerateRectsForRange:range
                      usingBlock:^(CGRect rect, BOOL *stop) {
                        if (CGRectIsNull(firstRect)) {
                          firstRect = rect;
                        }
                        frame = CGRectUnion(frame, rect);
                      }];

    // Cut by the number of lines
    if (CGRectIsNull(frame) || CGRectIsEmpty(frame)) {
      continue;
    }

    EnrichedTextAccessibilityElement *element =
        [[EnrichedTextAccessibilityElement alloc]
            initWithAccessibilityContainer:self];
    element.pressableRange = range;
    element.accessibilityLabel =
        [_textStorage.string substringWithRange:range.range];
    element.accessibilityTraits = range.url != nil ? UIAccessibilityTraitLink
                                                   : UIAccessibilityTraitButton;
    element.accessibilityFrameInContainerSpace =
        CGRectOffset(frame, textFrame.origin.x, textFrame.origin.y);
    // On its first line, where a touch presses it
    element.activationPointInContainerSpace =
        CGPointMake(CGRectGetMidX(firstRect) + textFrame.origin.x,
                    CGRectGetMidY(firstRect) + textFrame.origin.y);
    [elements addObject:element];
  }

  return elements;
}

// The links and the mentions that can be pressed, in the order of the text
- (NSArray<EnrichedTextPressableRange *> *)pressableRanges {
  NSMutableArray<EnrichedTextPressableRange *> *ranges = [NSMutableArray array];
  NSRange textRange = NSMakeRange(0, _textStorage.length);

  if (_pressableLinks) {
    [_textStorage enumerateAttribute:[LinkStyle attributeKey]
                             inRange:textRange
                             options:0
                          usingBlock:^(id value, NSRange range, BOOL *stop) {
                            if ([value isKindOfClass:NSString.class]) {
                              EnrichedTextPressableRange *link =
                                  [[EnrichedTextPressableRange alloc] init];
                              link.range = range;
                              link.url = value;
                              [ranges addObject:link];
                            }
                          }];
  }

  if (_pressableMentions) {
    [_textStorage enumerateAttribute:[MentionStyle attributeKey]
                             inRange:textRange
                             options:0
                          usingBlock:^(id value, NSRange range, BOOL *stop) {
                            if ([value isKindOfClass:MentionParams.class]) {
                              EnrichedTextPressableRange *mention =
                                  [[EnrichedTextPressableRange alloc] init];
                              mention.range = range;
                              mention.mention = value;
                              [ranges addObject:mention];
                            }
                          }];
  }

  [ranges sortUsingComparator:^NSComparisonResult(
              EnrichedTextPressableRange *first,
              EnrichedTextPressableRange *second) {
    return [@(first.range.location) compare:@(second.range.location)];
  }];

  return ranges;
}

// As Android's TalkBack: a press, without a press in and out
- (void)activatePressableRange:(EnrichedTextPressableRange *)range {
  [self emitEvent:EnrichedTextPressEventPress forRange:range];
}

// MARK: - Gesture recognizer delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:
        (UIGestureRecognizer *)otherGestureRecognizer {
  if (gestureRecognizer != _pressRecognizer) {
    return NO;
  }

  UIView *otherView = otherGestureRecognizer.view;

  // A scroll starting on a link still scrolls: the press ends as the finger
  // moves
  if ([otherView isKindOfClass:[UIScrollView class]] &&
      otherView != _textView &&
      otherGestureRecognizer ==
          ((UIScrollView *)otherView).panGestureRecognizer) {
    return YES;
  }

  // Selectable: the text view selects the text held, unless the range has a
  // long press of its own
  if (otherView == _textView) {
    EnrichedTextPressableRange *range = _pressRecognizer.pressedRange;
    return range == nil || ![self canLongPressRange:range];
  }

  return NO;
}

@end
