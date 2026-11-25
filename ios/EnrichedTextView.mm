#import "EnrichedTextView.h"
#import "ColorExtension.h"
#import "EnrichedPreparedText.h"
#import "EnrichedTextAccessibilityElement.h"
#import "EnrichedTextBuilder.h"
#import "EnrichedTextContent.h"
#import "EnrichedTextPressRecognizer.h"
#import "EnrichedTextStyleFactory.h"
#import "InputConfig.h"
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
  EnrichedTextContent *_content;
  EnrichedPreparedText *_pendingPreparedText;
  NSDictionary<NSNumber *, id> *_stylesDict;
  EnrichedTextPressRecognizer *_pressRecognizer;
  CAShapeLayer *_pressLayer;
  NSInteger _numberOfLines;
  SharedColor _selectionColor;
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

    // Behind the text
    _pressLayer = [CAShapeLayer layer];

    _pressRecognizer = [[EnrichedTextPressRecognizer alloc] init];
    _pressRecognizer.pressDelegate = self;
    _pressRecognizer.delegate = self;

    [self setupContentSelectable:NO];

    // For the drawing of the lists, quotes, code blocks and checkboxes
    _stylesDict = [EnrichedTextStyleFactory makeStylesWithInput:self];
  }
  return self;
}

// Made again when the text becomes selectable or not, with the text it shows
- (void)setupContentSelectable:(BOOL)selectable {
  UIView *previousView = _content.view;
  EnrichedPreparedText *preparedText = _content.preparedText;
  [previousView removeFromSuperview];

  _content = [[EnrichedTextContent alloc] initWithHost:self
                                            selectable:selectable
                                  maximumNumberOfLines:_numberOfLines
                                         lineBreakMode:_lineBreakMode];
  UIView *view = _content.view;
  // Set, it's passed down to all the subviews of the text view
  view.tintColor = RCTUIColorFromSharedColor(_selectionColor);
  [self addSubview:view];
  [self.layer insertSublayer:_pressLayer below:view.layer];
  [view addGestureRecognizer:_pressRecognizer];
  [_content setFrame:previousView != nil ? previousView.frame : CGRectZero
            nextText:_pendingPreparedText];

  if (preparedText != nil) {
    [self setPreparedText:preparedText];
  }
  _accessibilityElements = nil;
}

// MARK: - Style host

- (UITextView *)textView {
  return _content.textView;
}

- (InputConfig *)config {
  return _content.preparedText.config;
}

- (NSDictionary<NSAttributedStringKey, id> *)defaultTypingAttributes {
  return nil;
}

- (NSDictionary<NSNumber *, id> *)stylesDict {
  return _stylesDict;
}

- (void)mediaAttachmentDidUpdate:(MediaAttachment *)attachment {
  [_content redrawAttachment:attachment];
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
    [_content setMaximumNumberOfLines:_numberOfLines
                        lineBreakMode:_lineBreakMode];
  }

  if (_content.isSelectable != newProps.selectable) {
    [self setupContentSelectable:newProps.selectable];
  }

  // Set, it's passed down to all the subviews of the text view
  if (!(newProps.selectionColor == _selectionColor)) {
    _selectionColor = newProps.selectionColor;
    _content.view.tintColor = RCTUIColorFromSharedColor(_selectionColor);
  }

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

  _pendingPreparedText = preparedText;
}

- (void)finalizeUpdates:(RNComponentViewUpdateMask)updateMask {
  [super finalizeUpdates:updateMask];

  if (_pendingPreparedText != nil) {
    [self setPreparedText:_pendingPreparedText];
    _pendingPreparedText = nil;
  }
}

- (void)setPreparedText:(EnrichedPreparedText *)preparedText {
  if (preparedText == _content.preparedText) {
    return;
  }

  [self cancelCurrentPress];
  [_content setPreparedText:preparedText];
  _accessibilityElements = nil;
}

// MARK: - Layout

- (void)updateLayoutMetrics:(const LayoutMetrics &)layoutMetrics
           oldLayoutMetrics:(const LayoutMetrics &)oldLayoutMetrics {
  [super updateLayoutMetrics:layoutMetrics oldLayoutMetrics:oldLayoutMetrics];

  // The measured text, inside the padding and the border
  CGRect contentFrame = RCTCGRectFromRect(layoutMetrics.getContentFrame());

  if (!CGRectEqualToRect(_content.view.frame, contentFrame)) {
    // Behind the text, in its coordinates: not animated as a layer of its own
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _pressLayer.frame = contentFrame;
    [CATransaction commit];
  }
  [_content setFrame:contentFrame nextText:_pendingPreparedText];
  _accessibilityElements = nil;
}

- (void)prepareForRecycle {
  [super prepareForRecycle];

  [self cancelCurrentPress];
  _pendingPreparedText = nil;
  [_content clear];
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

  NSTextStorage *textStorage = _content.textStorage;
  NSRange textRange = NSMakeRange(0, textStorage.length);
  NSRange range;

  if (_pressableLinks) {
    id url = [textStorage attribute:[LinkStyle attributeKey]
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
    id mention = [textStorage attribute:[MentionStyle attributeKey]
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
  if (_content.textStorage.length == 0) {
    return NSNotFound;
  }

  // In the content view: its container at its origin, without an inset
  NSLayoutManager *layoutManager = _content.layoutManager;
  NSTextContainer *textContainer = _content.textContainer;
  CGPoint containerPoint = point;

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
  NSLayoutManager *layoutManager = _content.layoutManager;
  NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:range.range
                                             actualCharacterRange:NULL];

  [layoutManager
      enumerateEnclosingRectsForGlyphRange:glyphRange
                  withinSelectedGlyphRange:NSMakeRange(NSNotFound, 0)
                           inTextContainer:_content.textContainer
                                usingBlock:^(CGRect rect, BOOL *stop) {
                                  block(rect, stop);
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

    UIColor *color =
        [_content.textStorage attribute:NSForegroundColorAttributeName
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
  NSString *text = _content.textStorage.string;
  if (text.length == 0) {
    return @[];
  }

  CGRect textFrame = _content.view.frame;
  NSMutableArray<EnrichedTextAccessibilityElement *> *elements =
      [NSMutableArray array];

  EnrichedTextAccessibilityElement *textElement =
      [[EnrichedTextAccessibilityElement alloc]
          initWithAccessibilityContainer:self];
  NSString *label = super.accessibilityLabel;
  textElement.accessibilityLabel = label.length > 0 ? label : text;
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
    element.accessibilityLabel = [text substringWithRange:range.range];
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
  NSTextStorage *textStorage = _content.textStorage;
  NSRange textRange = NSMakeRange(0, textStorage.length);

  if (_pressableLinks) {
    [textStorage enumerateAttribute:[LinkStyle attributeKey]
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
    [textStorage enumerateAttribute:[MentionStyle attributeKey]
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
      otherView != _content.view &&
      otherGestureRecognizer ==
          ((UIScrollView *)otherView).panGestureRecognizer) {
    return YES;
  }

  // Selectable: the text view selects the text held, unless the range has a
  // long press of its own
  if (otherView == _content.view) {
    EnrichedTextPressableRange *range = _pressRecognizer.pressedRange;
    return range == nil || ![self canLongPressRange:range];
  }

  return NO;
}

@end
