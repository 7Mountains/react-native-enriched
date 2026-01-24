#import "EnrichedTextInputView.h"
#import "AlignmentConverter.h"
#import "AttachmentInvalidationBatcher.h"
#import "BaseLabelAttachment.h"
#import "ColorExtension.h"
#import "EnrichedCommandHandler.h"
#import "EnrichedTextConfigBuilder.h"
#import "EnrichedTextStyleFactory.h"
#import "HeadingsParagraphInvariantUtils.h"
#import "LayoutManagerExtension.h"
#import "ParagraphAttributesUtils.h"
#import "StringExtension.h"
#import "Strings.h"
#import "StyleHeaders.h"
#import "TextBlockTapGestureRecognizer.h"
#import "UIView+React.h"
#import "WordsUtils.h"
#import "ZeroWidthSpaceUtils.h"
#import <React/RCTConversions.h>
#import <ReactNativeEnriched/EnrichedTextInputViewComponentDescriptor.h>
#import <folly/dynamic.h>
#import <react/renderer/components/RNEnrichedTextInputViewSpec/EventEmitters.h>
#import <react/renderer/components/RNEnrichedTextInputViewSpec/Props.h>
#import <react/renderer/components/RNEnrichedTextInputViewSpec/RCTComponentViewHelpers.h>
#import <react/utils/ManagedObjectWrapper.h>

using namespace facebook::react;

@interface EnrichedTextInputView () <RCTEnrichedTextInputViewViewProtocol,
                                     UITextViewDelegate, NSObject>
@end

@implementation EnrichedTextInputView {
  EnrichedTextInputViewShadowNode::ConcreteState::Shared _state;
  int _componentViewHeightUpdateCounter;
  NSMutableSet<NSNumber *> *_activeStyles;
  LinkData *_recentlyActiveLinkData;
  NSRange _recentlyActiveLinkRange;
  NSString *_recentInputString;
  MentionParams *_recentlyActiveMentionParams;
  NSRange _recentlyActiveMentionRange;
  NSString *_recentlyEmittedHtml;
  BOOL _emitHtml;
  NSString *_recentlyEmittedColor;
  UILabel *_placeholderLabel;
  UIColor *_placeholderColor;
  BOOL _emitFocusBlur;
  UITapGestureRecognizer *tapRecognizer;
  NSString *_recentlyEmittedAlignment;
  AttachmentInvalidationBatcher *_attachmentBatcher;
  BOOL _emitChangeText;
  EnrichedCommandHandler *_commandHandler;
}

// MARK: - Component utils

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<
      EnrichedTextInputViewComponentDescriptor>();
}

Class<RCTComponentViewProtocol> EnrichedTextInputViewCls(void) {
  return EnrichedTextInputView.class;
}

+ (BOOL)shouldBeRecycled {
  return NO;
}

// MARK: - Init

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps =
        std::make_shared<const EnrichedTextInputViewProps>();
    _props = defaultProps;
    [self setDefaults];
    [self setupTextView];
    [self addSubview:textView];
    _attachmentBatcher =
        [[AttachmentInvalidationBatcher alloc] initWithTextView:textView];
  }
  return self;
}

- (void)setDefaults {
  _componentViewHeightUpdateCounter = 0;
  _activeStyles = [[NSMutableSet alloc] init];
  _recentlyActiveLinkRange = NSMakeRange(0, 0);
  _recentlyActiveMentionRange = NSMakeRange(0, 0);
  recentlyChangedRange = NSMakeRange(0, 0);
  _recentInputString = @"";
  _recentlyEmittedHtml = @"<html>\n<p></p>\n</html>";
  _emitHtml = NO;
  _recentlyEmittedColor = nil;
  blockEmitting = NO;
  _emitFocusBlur = YES;
  _recentlyEmittedAlignment = nil;
  _emitChangeText = NO;

  defaultTypingAttributes =
      [[NSMutableDictionary<NSAttributedStringKey, id> alloc] init];

  stylesDict = [EnrichedTextStyleFactory makeStylesWithInput:self];
  conflictingStyles = [EnrichedTextStyleFactory makeConflictingStyles];
  blockingStyles = [EnrichedTextStyleFactory makeBlockingStyles];

  parser = [[InputParser alloc] initWithInput:self];
  _commandHandler = [[EnrichedCommandHandler alloc] initWithInput:self];
}

- (void)setupTextView {
  textView = [[InputTextView alloc] init];
  textView.backgroundColor = UIColor.clearColor;
  textView.textContainerInset = UIEdgeInsetsZero;
  textView.textContainer.lineFragmentPadding = 0;
  textView.delegate = self;
  textView.input = self;
  textView.layoutManager.input = self;
  textView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

  TextBlockTapGestureRecognizer *blockTapGesture =
      [[TextBlockTapGestureRecognizer alloc]
          initWithTarget:self
                  action:@selector(onTextBlockTap:)
                textView:textView
                   input:self];

  for (UIGestureRecognizer *gestureRecognizer in textView.gestureRecognizers) {
    [gestureRecognizer requireGestureRecognizerToFail:blockTapGesture];
  }

  [textView addGestureRecognizer:blockTapGesture];
}

// MARK: - Props

- (void)updateProps:(Props::Shared const &)props
           oldProps:(Props::Shared const &)oldProps {
  const auto &oldViewProps =
      *std::static_pointer_cast<EnrichedTextInputViewProps const>(_props);
  const auto &newViewProps =
      *std::static_pointer_cast<EnrichedTextInputViewProps const>(props);
  BOOL isFirstMount = NO;

  if (config == nullptr) {
    isFirstMount = YES;
  }

  InputConfig *newConfig =
      [EnrichedTextConfigBuilder makeConfigFromProps:newViewProps
                                        oldViewProps:oldViewProps
                                      previousConfig:config];

  BOOL configHasChanged = newConfig != config;

  // rich text style

  if (newViewProps.scrollEnabled != oldViewProps.scrollEnabled ||
      textView.scrollEnabled != newViewProps.scrollEnabled) {
    [textView setScrollEnabled:newViewProps.scrollEnabled];
  }

  BOOL defaultValueChanged =
      newViewProps.defaultValue != oldViewProps.defaultValue;

  if (configHasChanged) {
    // we want to preserve the selection between props changes
    NSRange prevSelectedRange = textView.selectedRange;

    // now set the new config
    config = newConfig;

    // we already applied html with styles in default value
    if (!defaultValueChanged && textView.textStorage.string.length > 0) {
      // all the text needs to be rebuilt
      // we get the current html using old config, then switch to new config and
      // replace text using the html this way, the newest config attributes are
      // being used!

      // the html needs to be generated using the old config
      NSString *currentHtml = [parser
          parseToHtmlFromRange:NSMakeRange(0,
                                           textView.textStorage.string.length)];
      // no emitting during styles reload
      blockEmitting = YES;

      if (currentHtml != nullptr) {
        [parser replaceWholeFromHtml:currentHtml
            notifyAnyTextMayHaveBeenModified:!isFirstMount];
      }

      blockEmitting = NO;
    }

    // fill the typing attributes with style props
    defaultTypingAttributes[NSForegroundColorAttributeName] =
        [config primaryColor];
    defaultTypingAttributes[NSFontAttributeName] = [config primaryFont];
    defaultTypingAttributes[NSUnderlineColorAttributeName] =
        [config primaryColor];
    defaultTypingAttributes[NSStrikethroughColorAttributeName] =
        [config primaryColor];
    defaultTypingAttributes[NSParagraphStyleAttributeName] =
        [[NSParagraphStyle alloc] init];
    textView.typingAttributes = defaultTypingAttributes;
    textView.selectedRange = prevSelectedRange;
  }

  // editable
  if (newViewProps.editable != textView.editable) {
    textView.editable = newViewProps.editable;
  }

  // default value - must be set before placeholder to make sure it correctly
  // shows on first mount
  if (defaultValueChanged) {
    NSString *newDefaultValue =
        [NSString fromCppString:newViewProps.defaultValue];

    if (newDefaultValue == nullptr) {
      // just plain text
      textView.text = newDefaultValue;
    } else {
      // we've got some seemingly proper html
      [parser replaceWholeFromHtml:newDefaultValue
          notifyAnyTextMayHaveBeenModified:!isFirstMount];
    }
    textView.selectedRange = NSRange(textView.textStorage.string.length, 0);
  }

  // placeholderTextColor
  if (newViewProps.placeholderTextColor != oldViewProps.placeholderTextColor) {
    textView.placeholderColor =
        RCTUIColorFromSharedColor(newViewProps.placeholderTextColor);
  }

  // placeholder
  if (newViewProps.placeholder != oldViewProps.placeholder) {
    [textView
        setPlaceholderText:[NSString fromCppString:newViewProps.placeholder]];
  }

  // selection color sets both selection and cursor on iOS (just as in RN)
  if (newViewProps.selectionColor != oldViewProps.selectionColor) {
    if (isColorMeaningful(newViewProps.selectionColor)) {
      textView.tintColor =
          RCTUIColorFromSharedColor(newViewProps.selectionColor);
    } else {
      textView.tintColor = nullptr;
    }
  }

  // autoCapitalize
  if (newViewProps.autoCapitalize != oldViewProps.autoCapitalize) {
    NSString *str = [NSString fromCppString:newViewProps.autoCapitalize];
    if ([str isEqualToString:@"none"]) {
      textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    } else if ([str isEqualToString:@"sentences"]) {
      textView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    } else if ([str isEqualToString:@"words"]) {
      textView.autocapitalizationType = UITextAutocapitalizationTypeWords;
    } else if ([str isEqualToString:@"characters"]) {
      textView.autocapitalizationType =
          UITextAutocapitalizationTypeAllCharacters;
    }

    // textView needs to be refocused on autocapitalization type change and we
    // don't want to emit these events
    if ([textView isFirstResponder]) {
      _emitFocusBlur = NO;
      [textView reactBlur];
      [textView reactFocus];
      _emitFocusBlur = YES;
    }
  }

  // isOnChangeHtmlSet
  _emitHtml = newViewProps.isOnChangeHtmlSet;

  // isOnChangeTextSet
  _emitChangeText = newViewProps.isOnChangeTextSet;

  [super updateProps:props oldProps:oldProps];

  // if default value changed it will be fired in default value update
  // if this is initial mount it will be called in didMoveToWindow
  if (!defaultValueChanged && !isFirstMount) {
    // run the changes callback
    [self anyTextMayHaveBeenModified];
  }

  // autofocus - needs to be done at the very end
  if (isFirstMount && newViewProps.autoFocus) {
    [textView reactFocus];
  }
  [textView updatePlaceholderVisibility];
}

- (void)updateLayoutMetrics:(const LayoutMetrics &)layoutMetrics
           oldLayoutMetrics:(const LayoutMetrics &)oldLayoutMetrics {
  [super updateLayoutMetrics:layoutMetrics oldLayoutMetrics:oldLayoutMetrics];

  textView.frame = UIEdgeInsetsInsetRect(
      self.bounds, RCTUIEdgeInsetsFromEdgeInsets(layoutMetrics.borderWidth));
  textView.textContainerInset = RCTUIEdgeInsetsFromEdgeInsets(
      layoutMetrics.contentInsets - layoutMetrics.borderWidth);
}

// make sure the newest state is kept in _state property
- (void)updateState:(State::Shared const &)state
           oldState:(State::Shared const &)oldState {
  _state = std::static_pointer_cast<
      const EnrichedTextInputViewShadowNode::ConcreteState>(state);

  // first render with all the needed stuff already defined (state and
  // componentView) so we need to run a single height calculation for any
  // initial values
  if (oldState == nullptr) {
    [self commitSize:textView.textContainer.size];
  }
}

- (void)commitSize:(CGSize)size {
  if (_state == nullptr) {
    return;
  }

  auto selfRef = wrapManagedObjectWeakly(self);
  facebook::react::Size newSize{.width = size.width, .height = size.height};
  _state->updateState(
      facebook::react::EnrichedTextInputViewState(newSize, selfRef));
}

- (CGSize)measureInitialSizeWithMaxWidth:(CGFloat)maxWidth {
  NSTextContainer *container = textView.textContainer;
  NSLayoutManager *layoutManager = textView.layoutManager;

  container.size = CGSizeMake(maxWidth, CGFLOAT_MAX);

  [layoutManager ensureLayoutForTextContainer:container];

  CGRect used = [layoutManager usedRectForTextContainer:container];
  CGFloat height = ceil(used.size.height);

  // Empty text fallback
  if (textView.textStorage.length == 0) {
    UIFont *font =
        textView.typingAttributes[NSFontAttributeName] ?: textView.font;
    if (font) {
      height = ceil(font.lineHeight);
    }
  }

  return CGSizeMake(maxWidth, height);
}

// MARK: - Active styles

- (void)tryUpdatingActiveStyles {
  // style updates are emitted only if something differs from the previously
  // active styles
  BOOL updateNeeded = NO;

  // active styles are kept in a separate set until we're sure they can be
  // emitted
  NSMutableSet *newActiveStyles = [_activeStyles mutableCopy];

  // data for onLinkDetected event
  LinkData *detectedLinkData;
  NSRange detectedLinkRange = NSMakeRange(0, 0);

  // data for onMentionDetected event
  MentionParams *detectedMentionParams;
  NSRange detectedMentionRange = NSMakeRange(0, 0);
  NSRange selectionRange = textView.selectedRange;

  for (NSNumber *type in stylesDict) {
    id<BaseStyleProtocol> style = stylesDict[type];
    BOOL wasActive = [newActiveStyles containsObject:type];
    BOOL isActive = [style detectStyle:selectionRange];
    if (wasActive != isActive) {
      updateNeeded = YES;
      if (isActive) {
        [newActiveStyles addObject:type];
      } else {
        [newActiveStyles removeObject:type];
      }
    }

    // onLinkDetected event
    if (isActive && [type intValue] == [LinkStyle getStyleType]) {
      // get the link data
      LinkData *candidateLinkData;
      NSRange candidateLinkRange = NSMakeRange(0, 0);
      LinkStyle *linkStyleClass =
          (LinkStyle *)stylesDict[@([LinkStyle getStyleType])];
      if (linkStyleClass != nullptr) {
        candidateLinkData =
            [linkStyleClass getLinkDataAt:textView.selectedRange.location];
        candidateLinkRange =
            [linkStyleClass getFullLinkRangeAt:textView.selectedRange.location];
      }

      if (wasActive == NO) {
        // we changed selection from non-link to a link
        detectedLinkData = candidateLinkData;
        detectedLinkRange = candidateLinkRange;
      } else if (![_recentlyActiveLinkData.url
                     isEqualToString:candidateLinkData.url] ||
                 ![_recentlyActiveLinkData.text
                     isEqualToString:candidateLinkData.text] ||
                 !NSEqualRanges(_recentlyActiveLinkRange, candidateLinkRange)) {
        // we changed selection from one link to the other or modified current
        // link's text
        detectedLinkData = candidateLinkData;
        detectedLinkRange = candidateLinkRange;
      }
    }

    // onMentionDetected event
    if (isActive && [type intValue] == [MentionStyle getStyleType]) {
      // get mention data
      MentionParams *candidateMentionParams;
      NSRange candidateMentionRange = NSMakeRange(0, 0);
      MentionStyle *mentionStyleClass =
          (MentionStyle *)stylesDict[@([MentionStyle getStyleType])];
      if (mentionStyleClass != nullptr) {
        candidateMentionParams = [mentionStyleClass
            getMentionParamsAt:textView.selectedRange.location];
        candidateMentionRange = [mentionStyleClass
            getFullMentionRangeAt:textView.selectedRange.location];
      }

      if (wasActive == NO) {
        // selection was changed from a non-mention to a mention
        detectedMentionParams = candidateMentionParams;
        detectedMentionRange = candidateMentionRange;
      } else if (![_recentlyActiveMentionParams
                     isEqualToMentionParams:candidateMentionParams] ||
                 !NSEqualRanges(_recentlyActiveMentionRange,
                                candidateMentionRange)) {
        // selection changed from one mention to another
        detectedMentionParams = candidateMentionParams;
        detectedMentionRange = candidateMentionRange;
      }
    }
  }

  if (updateNeeded) {
    auto emitter = [self getEventEmitter];
    if (emitter != nullptr) {
      // update activeStyles only if emitter is available
      _activeStyles = newActiveStyles;

      emitter->onChangeState({
        .isBold = [_activeStyles containsObject:@([BoldStyle getStyleType])],
        .isItalic =
            [_activeStyles containsObject:@([ItalicStyle getStyleType])],
        .isUnderline =
            [_activeStyles containsObject:@([UnderlineStyle getStyleType])],
        .isStrikeThrough =
            [_activeStyles containsObject:@([StrikethroughStyle getStyleType])],
        .isColored =
            [_activeStyles containsObject:@([ColorStyle getStyleType])],
        .isInlineCode =
            [_activeStyles containsObject:@([InlineCodeStyle getStyleType])],
        .isLink = [_activeStyles containsObject:@([LinkStyle getStyleType])],
        .isMention =
            [_activeStyles containsObject:@([MentionStyle getStyleType])],
        .isH1 = [_activeStyles containsObject:@([H1Style getStyleType])],
        .isH2 = [_activeStyles containsObject:@([H2Style getStyleType])],
        .isH3 = [_activeStyles containsObject:@([H3Style getStyleType])],
        .isH4 = [_activeStyles containsObject:@([H4Style getStyleType])],
        .isH5 = [_activeStyles containsObject:@([H5Style getStyleType])],
        .isH6 = [_activeStyles containsObject:@([H6Style getStyleType])],
        .isUnorderedList =
            [_activeStyles containsObject:@([UnorderedListStyle getStyleType])],
        .isOrderedList =
            [_activeStyles containsObject:@([OrderedListStyle getStyleType])],
        .isBlockQuote =
            [_activeStyles containsObject:@([BlockQuoteStyle getStyleType])],
        .isCodeBlock =
            [_activeStyles containsObject:@([CodeBlockStyle getStyleType])],
        .isImage = [_activeStyles containsObject:@([ImageStyle getStyleType])],
        .isCheckList =
            [_activeStyles containsObject:@([CheckBoxStyle getStyleType])],
        .isContent =
            [_activeStyles containsObject:@([ContentStyle getStyleType])]
      });
    }
  }

  if (detectedLinkData != nullptr) {
    // emit onLinkeDetected event
    [self emitOnLinkDetectedEvent:detectedLinkData.text
                              url:detectedLinkData.url
                            range:detectedLinkRange];
  }

  if (detectedMentionParams != nullptr) {
    // emit onMentionDetected event
    [self emitOnMentionDetectedEvent:detectedMentionParams.text
                           indicator:detectedMentionParams.indicator
                          attributes:detectedMentionParams.extraAttributes];

    _recentlyActiveMentionParams = detectedMentionParams;
    _recentlyActiveMentionRange = detectedMentionRange;
  }

  [self emitCurrentSelectionColorIfChanged];
  [self emitParagraphAlignmentIfChanged];

  // emit onChangeHtml event if needed
  [self tryEmittingOnChangeHtmlEvent];
}

// MARK: - Native commands and events

- (void)handleCommand:(const NSString *)commandName args:(const NSArray *)args {
  [_commandHandler handleCommand:(NSString *)commandName args:(NSArray *)args];
}

- (std::shared_ptr<EnrichedTextInputViewEventEmitter>)getEventEmitter {
  if (_eventEmitter != nullptr && !blockEmitting) {
    auto emitter =
        static_cast<const EnrichedTextInputViewEventEmitter &>(*_eventEmitter);
    return std::make_shared<EnrichedTextInputViewEventEmitter>(emitter);
  } else {
    return nullptr;
  }
}

- (void)blur {
  [textView reactBlur];
}

- (void)focus {
  [textView reactFocus];
}

- (void)setValue:(NSString *)value {
  if (value == nullptr) {
    // just plain text
    textView.text = value;
  } else {
    // we've got some seemingly proper html
    [parser replaceWholeFromHtml:value notifyAnyTextMayHaveBeenModified:YES];
  }

  // set recentlyChangedRange and check for changes
  recentlyChangedRange = NSMakeRange(0, textView.textStorage.string.length);
  textView.selectedRange = NSRange(textView.textStorage.string.length, 0);
  [self anyTextMayHaveBeenModified];
}

- (void)setCustomSelection:(NSInteger)visibleStart end:(NSInteger)visibleEnd {
  NSString *text = textView.textStorage.string;

  NSUInteger actualStart = [self getActualIndex:visibleStart text:text];
  NSUInteger actualEnd = [self getActualIndex:visibleEnd text:text];

  textView.selectedRange = NSMakeRange(actualStart, actualEnd - actualStart);
}

// Helper: Walks through the string skipping ZWSPs to find the Nth visible
// character
- (NSUInteger)getActualIndex:(NSInteger)visibleIndex text:(NSString *)text {
  NSUInteger currentVisibleCount = 0;
  NSUInteger actualIndex = 0;

  while (actualIndex < text.length) {
    if (currentVisibleCount == visibleIndex) {
      return actualIndex;
    }

    // If the current char is not a hidden space, it counts towards our visible
    // index.
    if ([text characterAtIndex:actualIndex] != ZWSChar) {
      currentVisibleCount++;
    }

    actualIndex++;
  }

  return actualIndex;
}

- (void)emitOnLinkDetectedEvent:(NSString *)text
                            url:(NSString *)url
                          range:(NSRange)range {
  auto emitter = [self getEventEmitter];
  if (emitter != nullptr) {
    // update recently active link info
    LinkData *newLinkData = [[LinkData alloc] init];
    newLinkData.text = text;
    newLinkData.url = url;
    _recentlyActiveLinkData = newLinkData;
    _recentlyActiveLinkRange = range;

    emitter->onLinkDetected({
        .text = [text toCppString],
        .url = [url toCppString],
        .start = static_cast<int>(range.location),
        .end = static_cast<int>(range.location + range.length),
    });
  }
}

- (void)emitCurrentSelectionColorIfChanged {
  NSRange selectedRange = textView.selectedRange;
  UIColor *uniformColor = nil;

  if (selectedRange.length == 0) {
    id colorAttr = textView.typingAttributes[NSForegroundColorAttributeName];
    uniformColor = colorAttr ? (UIColor *)colorAttr : [config primaryColor];
  } else {
    // Selection range: check for uniform color
    __block UIColor *firstColor = nil;
    __block BOOL hasMultiple = NO;

    [textView.textStorage
        enumerateAttribute:NSForegroundColorAttributeName
                   inRange:selectedRange
                   options:0
                usingBlock:^(id _Nullable value, NSRange range,
                             BOOL *_Nonnull stop) {
                  UIColor *thisColor =
                      value ? (UIColor *)value : [config primaryColor];
                  if (firstColor == nil) {
                    firstColor = thisColor;
                  } else if (![firstColor isEqual:thisColor]) {
                    hasMultiple = YES;
                    *stop = YES;
                  }
                }];

    if (!hasMultiple && firstColor != nil) {
      uniformColor = firstColor;
    }
  }

  NSString *hexColor =
      uniformColor ? [uniformColor hexString] : [config.primaryColor hexString];

  if (![_recentlyEmittedColor isEqual:hexColor]) {
    auto emitter = [self getEventEmitter];
    if (emitter != nullptr) {
      emitter->onColorChangeInSelection({.color = [hexColor toCppString]});
    }
    _recentlyEmittedColor = hexColor;
  }
}

- (void)emitParagraphAlignmentIfChanged {
  NSRange selectedRange = textView.selectedRange;
  NSTextAlignment alignment = NSTextAlignmentNatural;

  if (selectedRange.length == 0) {
    NSParagraphStyle *style =
        textView.typingAttributes[NSParagraphStyleAttributeName];
    alignment = style ? style.alignment : NSTextAlignmentNatural;
  } else {
    NSTextStorage *storage = textView.textStorage;

    NSUInteger start = selectedRange.location;

    if (storage.length == 0 || start >= storage.length) {
      alignment = NSTextAlignmentNatural;
    } else {
      NSRange effectiveRange = NSMakeRange(0, 0);
      NSParagraphStyle *style = [storage attribute:NSParagraphStyleAttributeName
                                           atIndex:start
                             longestEffectiveRange:&effectiveRange
                                           inRange:selectedRange];

      BOOL coversWholeSelection =
          (NSMaxRange(effectiveRange) >= NSMaxRange(selectedRange));

      if (coversWholeSelection) {
        alignment = style ? style.alignment : NSTextAlignmentNatural;
      } else {
        alignment = NSTextAlignmentNatural;
      }
    }
  }

  NSString *stringAlignment =
      [AlignmentConverter stringFromAlignment:alignment];

  if ([stringAlignment isEqualToString:_recentlyEmittedAlignment]) {
    return;
  }

  auto emitter = [self getEventEmitter];
  if (emitter != nullptr) {
    emitter->onParagraphAlignmentChange(
        {.alignment = [stringAlignment toCppString]});
    _recentlyEmittedAlignment = stringAlignment;
  }
}

- (void)emitOnMentionDetectedEvent:(NSString *)text
                         indicator:(NSString *)indicator
                        attributes:(NSDictionary<NSString *, id> *_Nullable)
                                       attributes {
  auto emitter = [self getEventEmitter];
  if (emitter != nullptr) {
    auto data = [NSJSONSerialization dataWithJSONObject:attributes
                                                options:0
                                                  error:nil];
    std::string json((const char *)data.bytes, data.length);
    emitter->onMentionDetected({.text = [text toCppString],
                                .indicator = [indicator toCppString],
                                .payload = json});
  }
}

- (void)emitOnMentionEvent:(NSString *)indicator text:(NSString *)text {
  auto emitter = [self getEventEmitter];
  if (emitter != nullptr) {
    if (text != nullptr) {
      folly::dynamic fdStr = [text toCppString];
      emitter->onMention({.indicator = [indicator toCppString], .text = fdStr});
    } else {
      folly::dynamic nul = nullptr;
      emitter->onMention({.indicator = [indicator toCppString], .text = nul});
    }
  }
}

- (void)tryEmittingOnChangeHtmlEvent {
  if (!_emitHtml || textView.markedTextRange != nullptr) {
    return;
  }
  auto emitter = [self getEventEmitter];
  if (emitter != nullptr) {
    NSString *htmlOutput = [parser
        parseToHtmlFromRange:NSMakeRange(0,
                                         textView.textStorage.string.length)];
    // make sure html really changed
    if (![htmlOutput isEqualToString:_recentlyEmittedHtml]) {
      _recentlyEmittedHtml = htmlOutput;
      emitter->onChangeHtml({.value = [htmlOutput toCppString]});
    }
  }
}
- (void)requestHTML:(NSInteger)requestId prettify:(BOOL)prettify {
  auto emitter = [self getEventEmitter];
  if (!emitter) {
    return;
  }

  [self->parser
      parseToHTMLAsync:prettify
            completion:^(NSString *_Nullable html, NSError *_Nullable error) {
              if (error || !html) {
                emitter->onRequestHtmlResult(
                    {.requestId = static_cast<int>(requestId),
                     .html = folly::dynamic(nullptr)});
                return;
              }

              emitter->onRequestHtmlResult(
                  {.requestId = static_cast<int>(requestId),
                   .html = [html toCppString]});
            }];
}

// MARK: - Styles manipulation

- (void)setColor:(NSString *)colorText {
  UIColor *color = [UIColor colorFromString:colorText];
  ColorStyle *colorStyle = (ColorStyle *)stylesDict[@(Colored)];

  [colorStyle applyStyle:textView.selectedRange color:color];
  [self anyTextMayHaveBeenModified];
}

- (void)removeColor {
  ColorStyle *colorStyle = (ColorStyle *)stylesDict[@(Colored)];
  [colorStyle removeColorInSelectedRange];
  [self anyTextMayHaveBeenModified];
}

- (void)toggleRegularStyle:(StyleType)type {
  id<BaseStyleProtocol> styleClass = stylesDict[@(type)];

  if ([self handleStyleBlocksAndConflicts:type range:textView.selectedRange]) {
    [styleClass applyStyle:textView.selectedRange];
    [self anyTextMayHaveBeenModified];
  }
}

- (void)toggleParagraphStyle:(StyleType)type {
  id<BaseStyleProtocol> styleClass = stylesDict[@(type)];
  // we always pass whole paragraph/s range to these styles
  NSRange paragraphRange = [textView.textStorage.string
      paragraphRangeForRange:textView.selectedRange];

  if ([self handleStyleBlocksAndConflicts:type range:paragraphRange]) {
    [styleClass applyStyle:paragraphRange];
    [self anyTextMayHaveBeenModified];
  }
}

- (void)addLinkAt:(NSInteger)start
              end:(NSInteger)end
             text:(NSString *)text
              url:(NSString *)url {
  LinkStyle *linkStyleClass =
      (LinkStyle *)stylesDict[@([LinkStyle getStyleType])];
  if (linkStyleClass == nullptr) {
    return;
  }

  // translate the output start-end notation to range
  NSRange linkRange = NSMakeRange(start, end - start);
  if ([self handleStyleBlocksAndConflicts:[LinkStyle getStyleType]
                                    range:linkRange]) {
    [linkStyleClass addLink:text
                        url:url
                      range:linkRange
                     manual:YES
              withSelection:YES];
    [self anyTextMayHaveBeenModified];
  }
}

- (void)addDividerAtNewLine {
  DividerStyle *dividerStyle = stylesDict[(@([DividerStyle getStyleType]))];
  [dividerStyle insertDividerAtNewLine];
  [self anyTextMayHaveBeenModified];
}

- (void)addMention:(NSString *)indicator
              text:(NSString *)text
        attributes:(NSString *)attributes {
  MentionStyle *mentionStyleClass =
      (MentionStyle *)stylesDict[@([MentionStyle getStyleType])];
  if (mentionStyleClass == nullptr) {
    return;
  }
  if ([mentionStyleClass getActiveMentionRange] == nullptr) {
    return;
  }

  if ([self handleStyleBlocksAndConflicts:[MentionStyle getStyleType]
                                    range:[[mentionStyleClass
                                              getActiveMentionRange]
                                              rangeValue]]) {
    NSDictionary<NSString *, id> *parsedAttributes = nil;
    if (attributes.length > 0) {
      NSData *data = [attributes dataUsingEncoding:NSUTF8StringEncoding];

      if (data) {
        NSError *error = nil;
        id json = [NSJSONSerialization
            JSONObjectWithData:data
                       options:NSJSONReadingMutableContainers
                         error:&error];

        if (!error && [json isKindOfClass:[NSDictionary class]]) {
          parsedAttributes = (NSDictionary *)json;
        }
      }
    }

    [mentionStyleClass addMention:indicator
                             text:text
                       attributes:parsedAttributes ?: @{}];
    [self anyTextMayHaveBeenModified];
  }
}

- (void)addImage:(NSString *)uri width:(float)width height:(float)height {
  ImageStyle *imageStyleClass =
      (ImageStyle *)stylesDict[@([ImageStyle getStyleType])];
  if (imageStyleClass == nullptr) {
    return;
  }

  if ([self handleStyleBlocksAndConflicts:[ImageStyle getStyleType]
                                    range:textView.selectedRange]) {
    [imageStyleClass addImage:uri width:width height:height];
    [self anyTextMayHaveBeenModified];
  }
}

- (void)startMentionWithIndicator:(NSString *)indicator {
  MentionStyle *mentionStyleClass =
      (MentionStyle *)stylesDict[@([MentionStyle getStyleType])];
  if (mentionStyleClass == nullptr) {
    return;
  }

  if ([self handleStyleBlocksAndConflicts:[MentionStyle getStyleType]
                                    range:textView.selectedRange]) {
    [mentionStyleClass startMentionWithIndicator:indicator];
    [self anyTextMayHaveBeenModified];
  }
}

- (void)setParagraphAlignment:(NSString *)alignment {
  ParagraphAlignmentStyle *paragraphAlignmentStyle = (ParagraphAlignmentStyle *)
      stylesDict[@([ParagraphAlignmentStyle getStyleType])];
  if (paragraphAlignmentStyle == nullptr)
    return;

  NSTextAlignment convertedAlignment =
      [AlignmentConverter alignmentFromString:alignment];

  [paragraphAlignmentStyle applyStyle:textView.selectedRange
                            alignment:convertedAlignment];
}

// returns false when style shouldn't be applied and true when it can be
- (BOOL)handleStyleBlocksAndConflicts:(StyleType)type range:(NSRange)range {
  // handle blocking styles: if any is present we do not apply the toggled style
  NSArray<NSNumber *> *blocking =
      [self getPresentStyleTypesFrom:blockingStyles[@(type)] range:range];
  if (blocking.count != 0) {
    return NO;
  }

  // handle conflicting styles: all of their occurences have to be removed
  NSArray<NSNumber *> *conflicting =
      [self getPresentStyleTypesFrom:conflictingStyles[@(type)] range:range];
  if (conflicting.count != 0) {
    for (NSNumber *style in conflicting) {
      id<BaseStyleProtocol> styleClass = stylesDict[style];

      if (range.length >= 1) {
        // for ranges, we need to remove each occurence
        NSArray<StylePair *> *allOccurences =
            [styleClass findAllOccurences:range];

        for (StylePair *pair in allOccurences) {
          [styleClass removeAttributes:[pair.rangeValue rangeValue]];
        }
      } else {
        // with in-place selection, we just remove the adequate typing
        // attributes
        [styleClass removeTypingAttributes];
      }
    }
  }
  return YES;
}

- (NSArray<NSNumber *> *)getPresentStyleTypesFrom:(NSArray<NSNumber *> *)types
                                            range:(NSRange)range {
  NSMutableArray<NSNumber *> *resultArray =
      [[NSMutableArray<NSNumber *> alloc] init];
  for (NSNumber *type in types) {
    id<BaseStyleProtocol> styleClass = stylesDict[type];

    if (range.length >= 1) {
      if ([styleClass anyOccurence:range]) {
        [resultArray addObject:type];
      }
    } else {
      if ([styleClass detectStyle:range]) {
        [resultArray addObject:type];
      }
    }
  }
  return resultArray;
}

- (void)manageSelectionBasedChanges {
  // link typing attributes fix
  LinkStyle *linkStyleClass =
      (LinkStyle *)stylesDict[@([LinkStyle getStyleType])];
  if (linkStyleClass != nullptr) {
    [linkStyleClass manageLinkTypingAttributes];
  }
  NSString *currentString = [textView.textStorage.string copy];

  // mention typing attribtues fix and active editing
  MentionStyle *mentionStyleClass =
      (MentionStyle *)stylesDict[@([MentionStyle getStyleType])];
  if (mentionStyleClass != nullptr) {
    [mentionStyleClass manageMentionTypingAttributes];

    // mention editing runs if only a selection was done (no text change)
    // otherwise we would double-emit with a second call in the
    // anyTextMayHaveBeenModified method
    if ([_recentInputString isEqualToString:currentString]) {
      [mentionStyleClass manageMentionEditing];
    }
  }

  // typing attributes for empty lines selection reset
  if (textView.selectedRange.length == 0 &&
      [_recentInputString isEqualToString:currentString]) {
    // no string change means only a selection changed with no character changes
    NSRange paragraphRange = [textView.textStorage.string
        paragraphRangeForRange:textView.selectedRange];
    if (paragraphRange.length == 0 ||
        (paragraphRange.length == 1 &&
         [[NSCharacterSet newlineCharacterSet]
             characterIsMember:[textView.textStorage.string
                                   characterAtIndex:paragraphRange
                                                        .location]])) {
      // user changed selection to an empty line (or empty line with a newline)
      // typing attributes need to be reset
      textView.typingAttributes = defaultTypingAttributes;
    }
  }

  // update active styles as well
  [self tryUpdatingActiveStyles];
}

- (void)handleWordModificationBasedChanges:(NSString *)word
                                   inRange:(NSRange)range {
  // manual links refreshing and automatic links detection handling
  LinkStyle *linkStyle =
      (LinkStyle *)[stylesDict objectForKey:@([LinkStyle getStyleType])];

  if (linkStyle != nullptr) {
    // manual links need to be handled first because they can block automatic
    // links after being refreshed
    [linkStyle handleManualLinks:word inRange:range];
    [linkStyle handleAutomaticLinks:word inRange:range];
  }
}

- (void)anyTextMayHaveBeenModified {
  // we don't do no text changes when working with iOS marked text
  if (textView.markedTextRange != nullptr) {
    return;
  }

  // zero width space adding or removal
  [ZeroWidthSpaceUtils handleZeroWidthSpacesInInput:self];

  // emptying input typing attributes management
  if (textView.textStorage.string.length == 0 &&
      _recentInputString.length > 0) {
    // reset typing attribtues
    textView.typingAttributes = defaultTypingAttributes;
  }

  // inline code on newlines fix
  InlineCodeStyle *codeStyle = stylesDict[@([InlineCodeStyle getStyleType])];
  if (codeStyle != nullptr) {
    [codeStyle handleNewlines];
  }

  // blockquote colors management
  BlockQuoteStyle *bqStyle = stylesDict[@([BlockQuoteStyle getStyleType])];
  if (bqStyle != nullptr) {
    [bqStyle manageBlockquoteColor];
  }

  // codeblock font and color management
  CodeBlockStyle *codeBlockStyle = stylesDict[@([CodeBlockStyle getStyleType])];
  if (codeBlockStyle != nullptr) {
    [codeBlockStyle manageCodeBlockFontAndColor];
  }

  // improper headings fix
  H1Style *h1Style = stylesDict[@([H1Style getStyleType])];
  H2Style *h2Style = stylesDict[@([H2Style getStyleType])];
  H3Style *h3Style = stylesDict[@([H3Style getStyleType])];
  H4Style *h4Style = stylesDict[@([H4Style getStyleType])];
  H5Style *h5Style = stylesDict[@([H5Style getStyleType])];
  H6Style *h6Style = stylesDict[@([H6Style getStyleType])];

  bool canHandleImproperHeadings = h1Style != nullptr && h2Style != nullptr &&
                                   h3Style != nullptr && h4Style != nullptr &&
                                   h5Style != nullptr && h6Style != nullptr;

  if (canHandleImproperHeadings) {
    [HeadingsParagraphInvariantUtils handleImproperHeadingStyles:@[
      h1Style, h2Style, h3Style, h4Style, h5Style, h6Style
    ]
                                                           input:self];
  }

  // mentions management: removal and editing
  MentionStyle *mentionStyleClass =
      (MentionStyle *)stylesDict[@([MentionStyle getStyleType])];
  if (mentionStyleClass != nullptr) {
    [mentionStyleClass handleExistingMentions];
    [mentionStyleClass manageMentionEditing];
  }

  // placholder management
  [textView updatePlaceholderVisibility];

  if (![textView.textStorage.string isEqualToString:_recentInputString]) {
    // modified words handling
    NSArray *modifiedWords =
        [WordsUtils getAffectedWordsFromText:textView.textStorage.string
                           modificationRange:recentlyChangedRange];
    if (modifiedWords != nullptr) {
      for (NSDictionary *wordDict in modifiedWords) {
        NSString *wordText = (NSString *)[wordDict objectForKey:@"word"];
        NSValue *wordRange = (NSValue *)[wordDict objectForKey:@"range"];

        if (wordText == nullptr || wordRange == nullptr) {
          continue;
        }

        [self handleWordModificationBasedChanges:wordText
                                         inRange:[wordRange rangeValue]];
      }
    }

    // emit onChangeText event
    auto emitter = [self getEventEmitter];
    if (emitter != nullptr && _emitChangeText) {
      // set the recent input string only if the emitter is defined
      _recentInputString = [textView.textStorage.string copy];

      // emit string without zero width spaces
      NSString *stringToBeEmitted = [[textView.textStorage.string
          stringByReplacingOccurrencesOfString:ZWS
                                    withString:@""] copy];

      emitter->onChangeText({.value = [stringToBeEmitted toCppString]});
    }
  }

  // update active styles as well
  [self tryUpdatingActiveStyles];
}

// MARK: - UITextView delegate methods

- (void)textViewDidBeginEditing:(UITextView *)textView {
  auto emitter = [self getEventEmitter];
  if (emitter != nullptr) {
    // send onFocus event if allowed
    if (_emitFocusBlur) {
      emitter->onInputFocus({});
    }

    NSString *textAtSelection =
        [[[NSMutableString alloc] initWithString:textView.textStorage.string]
            substringWithRange:textView.selectedRange];
    emitter->onChangeSelection(
        {.start = static_cast<int>(textView.selectedRange.location),
         .end = static_cast<int>(textView.selectedRange.location +
                                 textView.selectedRange.length),
         .text = [textAtSelection toCppString]});
  }
  // manage selection changes since textViewDidChangeSelection sometimes doesn't
  // run on focus
  [self manageSelectionBasedChanges];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
  auto emitter = [self getEventEmitter];
  if (emitter != nullptr && _emitFocusBlur) {
    // send onBlur event
    emitter->onInputBlur({});
  }
}

- (BOOL)isReadOnlyParagraphAtLocation:(NSUInteger)location {
  NSTextStorage *storage = textView.textStorage;
  NSUInteger length = storage.length;

  if (length == 0)
    return NO;

  if (location > 0) {
    id left = [storage attribute:ReadOnlyParagraphKey
                         atIndex:location - 1
                  effectiveRange:nil];
    if (left)
      return YES;
  }

  if (location < length) {
    id right = [storage attribute:ReadOnlyParagraphKey
                          atIndex:location
                   effectiveRange:nil];
    if (right)
      return YES;
  }

  return NO;
}

- (bool)textView:(UITextView *)textView
    shouldChangeTextInRange:(NSRange)range
            replacementText:(NSString *)text {
  if (![text isEqualToString:@"\n"] &&
      [self isReadOnlyParagraphAtLocation:range.location]) {
    if (text.length == 0)
      return YES;
    return NO;
  }
  recentlyChangedRange = NSMakeRange(range.location, text.length);
  UnorderedListStyle *uStyle = stylesDict[@([UnorderedListStyle getStyleType])];
  OrderedListStyle *oStyle = stylesDict[@([OrderedListStyle getStyleType])];
  BlockQuoteStyle *bqStyle = stylesDict[@([BlockQuoteStyle getStyleType])];
  CodeBlockStyle *cbStyle = stylesDict[@([CodeBlockStyle getStyleType])];
  LinkStyle *linkStyle = (LinkStyle *)stylesDict[@([LinkStyle getStyleType])];
  MentionStyle *mentionStyle =
      (MentionStyle *)stylesDict[@([MentionStyle getStyleType])];
  H1Style *h1Style = stylesDict[@([H1Style getStyleType])];
  H2Style *h2Style = stylesDict[@([H2Style getStyleType])];
  H3Style *h3Style = stylesDict[@([H3Style getStyleType])];
  H4Style *h4Style = stylesDict[@([H4Style getStyleType])];
  H5Style *h5Style = stylesDict[@([H5Style getStyleType])];
  H6Style *h6Style = stylesDict[@([H6Style getStyleType])];
  CheckBoxStyle *checkBoxStyle =
      (CheckBoxStyle *)stylesDict[@([CheckBoxStyle getStyleType])];

  // some of the changes these checks do could interfere with later checks and
  // cause a crash so here I rely on short circuiting evaluation of the logical
  // expression either way it's not possible to have two of them come off at the
  // same time
  if ([uStyle handleBackspaceInRange:range replacementText:text] ||
      [uStyle tryHandlingListShorcutInRange:range replacementText:text] ||
      [oStyle handleBackspaceInRange:range replacementText:text] ||
      [oStyle tryHandlingListShorcutInRange:range replacementText:text] ||
      [checkBoxStyle handleBackspaceInRange:range replacementText:text] ||
      [checkBoxStyle handleNewlinesInRange:range replacementText:text] ||
      [bqStyle handleBackspaceInRange:range replacementText:text] ||
      [bqStyle handleNewlinesInRange:range replacementText:text] ||
      [cbStyle handleBackspaceInRange:range replacementText:text] ||
      [linkStyle handleLeadingLinkReplacement:range replacementText:text] ||
      [mentionStyle handleLeadingMentionReplacement:range
                                    replacementText:text] ||
      [h1Style handleNewlinesInRange:range replacementText:text] ||
      [h2Style handleNewlinesInRange:range replacementText:text] ||
      [h3Style handleNewlinesInRange:range replacementText:text] ||
      [h4Style handleNewlinesInRange:range replacementText:text] ||
      [h5Style handleNewlinesInRange:range replacementText:text] ||
      [h6Style handleNewlinesInRange:range replacementText:text] ||
      [ZeroWidthSpaceUtils handleBackspaceInRange:range
                                  replacementText:text
                                            input:self] ||
      [ParagraphAttributesUtils handleBackspaceInRange:range
                                       replacementText:text
                                                 input:self] ||
      // CRITICAL: This callback HAS TO be always evaluated last.
      //
      // This function is the "Generic Fallback": if no specific style claims
      // the backspace action to change its state, only then do we proceed to
      // physically delete the newline and merge paragraphs.
      [ParagraphAttributesUtils handleParagraphStylesMergeOnBackspace:range
                                                      replacementText:text
                                                                input:self]) {
    [self anyTextMayHaveBeenModified];
    return NO;
  }

  return YES;
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
  // emit the event
  NSString *textAtSelection =
      [[[NSMutableString alloc] initWithString:textView.textStorage.string]
          substringWithRange:textView.selectedRange];

  auto emitter = [self getEventEmitter];
  if (emitter != nullptr) {
    // iOS range works differently because it specifies location and length
    // here, start is the location, but end is the first index BEHIND the end.
    // So a 0 length range will have equal start and end
    emitter->onChangeSelection(
        {.start = static_cast<int>(textView.selectedRange.location),
         .end = static_cast<int>(textView.selectedRange.location +
                                 textView.selectedRange.length),
         .text = [textAtSelection toCppString]});
  }

  // manage selection changes
  [self manageSelectionBasedChanges];
}

// this function isn't called always when some text changes (for example setting
// link or starting mention with indicator doesn't fire it) so all the logic is
// in anyTextMayHaveBeenModified
- (void)textViewDidChange:(UITextView *)textView {
  [self anyTextMayHaveBeenModified];
}

// MARK: - Media attachments delegate

- (void)mediaAttachmentDidUpdate:(NSTextAttachment *)attachment {
  [_attachmentBatcher enqueueAttachment:attachment];
}

- (CGPoint)adjustedPointForViewPoint:(CGPoint)pt {
  CGPoint tvPoint = [self convertPoint:pt toView:textView];
  tvPoint.x -= textView.textContainerInset.left;
  tvPoint.y -= textView.textContainerInset.top;
  return tvPoint;
}

- (void)onTextBlockTap:(TextBlockTapGestureRecognizer *)gr {
  if (gr.state != UIGestureRecognizerStateEnded)
    return;
  if (![self->textView isFirstResponder]) {
    [self->textView becomeFirstResponder];
  }

  switch (gr.tapKind) {

  case TextBlockTapKindCheckbox: {
    CheckBoxStyle *checkboxStyle =
        (CheckBoxStyle *)stylesDict[@([CheckBoxStyle getStyleType])];

    if (checkboxStyle) {
      [checkboxStyle toggleCheckedAt:(NSUInteger)gr.characterIndex];
      [self anyTextMayHaveBeenModified];
    }
    break;
  }

  case TextBlockTapKindAttachment: {
    NSInteger newLocation = gr.characterIndex + 1;
    newLocation = MIN(newLocation, self->textView.textStorage.length);
    self->textView.selectedRange = NSMakeRange(newLocation, 0);
    break;
  }

  default:
    break;
  }
}

@end
