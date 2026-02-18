#import "EnrichedTextInputView.h"
#import "HtmlAttributeNames.h"
#import "OccurenceUtils.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"
#import "UIView+React.h"
#import "WordsUtils.h"

// custom NSAttributedStringKeys to differentiate manually added and
// automatically detected links
static NSString *const ManualLinkAttributeName = @"ManualLinkAttributeName";
static NSString *const AutomaticLinkAttributeName =
    @"AutomaticLinkAttributeName";
// custom NSAttributedStringKey to differentiate the link during html creation
static NSString *const LinkAttributeName = @"LinkAttributeName";

@implementation LinkStyle {
  EnrichedTextInputView *_input;
}

+ (StyleType)getStyleType {
  return Link;
}

+ (BOOL)isParagraphStyle {
  return NO;
}

+ (const char *)tagName {
  return "a";
}

+ (const char *)subTagName {
  return nil;
}

+ (NSAttributedStringKey)attributeKey {
  return LinkAttributeName;
}

+ (NSDictionary<NSString *, NSString *> *_Nullable)getParametersFromValue:
    (id)value {
  NSString *url = value;
  if (!url)
    return nil;
  return @{HrefAttributeName : url};
}

+ (BOOL)isSelfClosing {
  return NO;
}

- (instancetype)initWithInput:(id)input {
  self = [super init];
  _input = (EnrichedTextInputView *)input;
  return self;
}

- (void)applyStyle:(NSRange)range {
  // no-op for links
}

- (void)addAttributes:(NSRange)range {
  // no-op for links
}

- (void)addAttributesInAttributedString:
            (NSMutableAttributedString *)attributedString
                                  range:(NSRange)range
                             attributes:(NSDictionary<NSString *, NSString *> *)
                                            attributes {
  if (range.length == 0)
    return;
  NSString *href = attributes[HrefAttributeName];
  if (href == nullptr || href.length == 0)
    return;

  UIColor *linkColor = _input->config.linkColor;

  NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithCapacity:5];
  attrs[NSForegroundColorAttributeName] = linkColor;
  attrs[NSUnderlineColorAttributeName] = linkColor;
  attrs[NSStrikethroughColorAttributeName] = linkColor;

  if ([_input->config linkDecorationLine] == DecorationUnderline) {
    attrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
  }

  NSString *string = attributedString.string;

  BOOL isAuto = NO;
  if (range.length == href.length &&
      range.location + range.length <= string.length) {
    isAuto = ([string compare:href options:0 range:range] == NSOrderedSame);
  }

  attrs[LinkAttributeName] = href;
  attrs[isAuto ? AutomaticLinkAttributeName : ManualLinkAttributeName] = href;

  [attributedString addAttributes:attrs range:range];
}

- (void)addTypingAttributes {
  // no-op for links
}

- (void)removeAttributesFromAttributedString:(NSMutableAttributedString *)string
                                       range:(NSRange)range {
  UIColor *primaryColor = [_input->config primaryColor];
  [string removeAttribute:ManualLinkAttributeName range:range];
  [string removeAttribute:AutomaticLinkAttributeName range:range];
  [string addAttribute:NSForegroundColorAttributeName
                 value:primaryColor
                 range:range];
  [string addAttribute:NSUnderlineColorAttributeName
                 value:primaryColor
                 range:range];
  [string addAttribute:NSStrikethroughColorAttributeName
                 value:primaryColor
                 range:range];
  if ([_input->config linkDecorationLine] == DecorationUnderline) {
    [string removeAttribute:NSUnderlineStyleAttributeName range:range];
  }
}

- (void)removeAttributes:(NSRange)range {
  NSArray<StylePair *> *links = [self findAllOccurences:range];
  NSTextStorage *storage = _input->textView.textStorage;
  [storage beginEditing];
  for (StylePair *pair in links) {
    NSRange linkRange =
        [self getFullLinkRangeAt:[pair.rangeValue rangeValue].location];
    [self removeAttributesFromAttributedString:storage range:linkRange];
  }
  [storage endEditing];

  // adjust typing attributes as well
  NSMutableDictionary *newTypingAttrs =
      [_input->textView.typingAttributes mutableCopy];
  newTypingAttrs[NSForegroundColorAttributeName] =
      [_input->config primaryColor];
  newTypingAttrs[NSUnderlineColorAttributeName] = [_input->config primaryColor];
  newTypingAttrs[NSStrikethroughColorAttributeName] =
      [_input->config primaryColor];
  if ([_input->config linkDecorationLine] == DecorationUnderline) {
    [newTypingAttrs removeObjectForKey:NSUnderlineStyleAttributeName];
  }
  _input->textView.typingAttributes = newTypingAttrs;
}

// used for conflicts, we have to remove the whole link
- (void)removeTypingAttributes {
  NSRange linkRange =
      [self getFullLinkRangeAt:_input->textView.selectedRange.location];
  [_input->textView.textStorage beginEditing];
  [_input->textView.textStorage removeAttribute:ManualLinkAttributeName
                                          range:linkRange];
  [_input->textView.textStorage removeAttribute:AutomaticLinkAttributeName
                                          range:linkRange];
  [_input->textView.textStorage removeAttribute:LinkAttributeName
                                          range:linkRange];
  [_input->textView.textStorage addAttribute:NSForegroundColorAttributeName
                                       value:[_input->config primaryColor]
                                       range:linkRange];
  [_input->textView.textStorage addAttribute:NSUnderlineColorAttributeName
                                       value:[_input->config primaryColor]
                                       range:linkRange];
  [_input->textView.textStorage addAttribute:NSStrikethroughColorAttributeName
                                       value:[_input->config primaryColor]
                                       range:linkRange];
  if ([_input->config linkDecorationLine] == DecorationUnderline) {
    [_input->textView.textStorage removeAttribute:NSUnderlineStyleAttributeName
                                            range:linkRange];
  }
  [_input->textView.textStorage endEditing];

  // adjust typing attributes as well
  NSMutableDictionary *newTypingAttrs =
      [_input->textView.typingAttributes mutableCopy];
  newTypingAttrs[NSForegroundColorAttributeName] =
      [_input->config primaryColor];
  newTypingAttrs[NSUnderlineColorAttributeName] = [_input->config primaryColor];
  newTypingAttrs[NSStrikethroughColorAttributeName] =
      [_input->config primaryColor];
  if ([_input->config linkDecorationLine] == DecorationUnderline) {
    [newTypingAttrs removeObjectForKey:NSUnderlineStyleAttributeName];
  }
  _input->textView.typingAttributes = newTypingAttrs;
}

- (BOOL)styleCondition:(id _Nullable)value range:(NSRange)range {
  NSString *linkValue = (NSString *)value;
  return linkValue != nullptr;
}

- (BOOL)detectStyle:(NSRange)range {
  if (range.length >= 1) {
    BOOL onlyLinks =
        [OccurenceUtils detect:LinkAttributeName
                     withInput:_input
                       inRange:range
                 withCondition:^BOOL(id _Nullable value, NSRange range) {
                   return [self styleCondition:value range:range];
                 }];
    return onlyLinks ? [self isSingleLinkIn:range] : NO;
  } else {
    return [self getLinkDataAt:range.location] != nullptr;
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:LinkAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value range:range];
               }];
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:LinkAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value range:range];
               }];
}

// MARK: - Public non-standard methods

- (void)addLink:(NSString *)text
              url:(NSString *)url
            range:(NSRange)range
           manual:(BOOL)manual
    withSelection:(BOOL)withSelection {
  NSString *currentText =
      [_input->textView.textStorage.string substringWithRange:range];

  NSMutableDictionary<NSAttributedStringKey, id> *newAttrs =
      [[NSMutableDictionary<NSAttributedStringKey, id> alloc] init];
  newAttrs[NSForegroundColorAttributeName] = [_input->config linkColor];
  newAttrs[NSUnderlineColorAttributeName] = [_input->config linkColor];
  newAttrs[NSStrikethroughColorAttributeName] = [_input->config linkColor];
  NSString *copiedUrl = [url copy];
  newAttrs[LinkAttributeName] = copiedUrl;
  if ([_input->config linkDecorationLine] == DecorationUnderline) {
    newAttrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
  }
  if (manual) {
    newAttrs[ManualLinkAttributeName] = copiedUrl;
  } else {
    newAttrs[AutomaticLinkAttributeName] = copiedUrl;
  }

  if (range.length == 0) {
    // insert link
    [TextInsertionUtils insertText:text
                                at:range.location
              additionalAttributes:newAttrs
                             input:_input
                     withSelection:withSelection];
  } else if ([currentText isEqualToString:text]) {
    // apply link attributes
    [_input->textView.textStorage addAttributes:newAttrs range:range];
    // TextInsertionUtils take care of the selection but here we have to
    // manually set it behind the link ONLY with manual links, automatic ones
    // don't need the selection fix
    if (manual && withSelection) {
      [_input->textView reactFocus];
      _input->textView.selectedRange =
          NSMakeRange(range.location + text.length, 0);
    }
  } else {
    // replace text with link
    [TextInsertionUtils replaceText:text
                                 at:range
               additionalAttributes:newAttrs
                              input:_input
                      withSelection:withSelection];
  }

  // mandatory connected links check
  NSDictionary *currentWord =
      [WordsUtils getCurrentWord:_input->textView.textStorage.string
                           range:_input->textView.selectedRange];
  if (currentWord != nullptr) {
    // get word properties
    NSString *wordText = (NSString *)[currentWord objectForKey:@"word"];
    NSValue *wordRangeValue = (NSValue *)[currentWord objectForKey:@"range"];
    if (wordText != nullptr && wordRangeValue != nullptr) {
      [self removeConnectedLinksIfNeeded:wordText
                                   range:[wordRangeValue rangeValue]];
    }
  }

  [self manageLinkTypingAttributes];
}

// get exact link data at the given location if it exists
- (LinkData *)getLinkDataAt:(NSUInteger)location {
  NSRange manualLinkRange = NSMakeRange(0, 0);
  NSRange automaticLinkRange = NSMakeRange(0, 0);
  NSRange inputRange = NSMakeRange(0, _input->textView.textStorage.length);

  // don't search at the very end of input
  NSUInteger searchLocation = location;
  if (searchLocation == _input->textView.textStorage.length) {
    return nullptr;
  }

  NSString *manualUrl =
      [_input->textView.textStorage attribute:ManualLinkAttributeName
                                      atIndex:searchLocation
                        longestEffectiveRange:&manualLinkRange
                                      inRange:inputRange];
  NSString *automaticUrl =
      [_input->textView.textStorage attribute:AutomaticLinkAttributeName
                                      atIndex:searchLocation
                        longestEffectiveRange:&automaticLinkRange
                                      inRange:inputRange];

  if ((manualUrl == nullptr && automaticUrl == nullptr) ||
      (manualLinkRange.length == 0 && automaticLinkRange.length == 0)) {
    return nullptr;
  }

  NSString *linkUrl = manualUrl == nullptr ? automaticUrl : manualUrl;
  NSRange linkRange =
      manualUrl == nullptr ? automaticLinkRange : manualLinkRange;

  LinkData *data = [[LinkData alloc] init];
  data.url = linkUrl;
  data.text =
      [_input->textView.textStorage.string substringWithRange:linkRange];
  return data;
}

// returns full range of a link at some location
- (NSRange)getFullLinkRangeAt:(NSUInteger)location {
  NSRange manualLinkRange = NSMakeRange(0, 0);
  NSRange automaticLinkRange = NSMakeRange(0, 0);
  NSRange inputRange = NSMakeRange(0, _input->textView.textStorage.length);

  // get the previous index if possible when at the very end of input
  NSUInteger searchLocation = location;
  if (searchLocation == _input->textView.textStorage.length) {
    if (searchLocation == 0) {
      return NSMakeRange(0, 0);
    } else {
      searchLocation = searchLocation - 1;
    }
  }

  NSString *manualLink =
      [_input->textView.textStorage attribute:ManualLinkAttributeName
                                      atIndex:searchLocation
                        longestEffectiveRange:&manualLinkRange
                                      inRange:inputRange];
  NSString *automaticLink =
      [_input->textView.textStorage attribute:AutomaticLinkAttributeName
                                      atIndex:searchLocation
                        longestEffectiveRange:&automaticLinkRange
                                      inRange:inputRange];

  return manualLink == nullptr
             ? automaticLink == nullptr ? NSMakeRange(0, 0) : automaticLinkRange
             : manualLinkRange;
}

- (void)manageLinkTypingAttributes {
  // link's typing attribtues need to be removed at ALL times whenever we have
  // some link around
  BOOL removeAttrs = NO;

  if (_input->textView.selectedRange.length == 0) {
    // check before
    if (_input->textView.selectedRange.location >= 1) {
      if ([self detectStyle:NSMakeRange(
                                _input->textView.selectedRange.location - 1,
                                1)]) {
        removeAttrs = YES;
      }
    }
    // check after
    if (_input->textView.selectedRange.location <
        _input->textView.textStorage.length) {
      if ([self detectStyle:NSMakeRange(_input->textView.selectedRange.location,
                                        1)]) {
        removeAttrs = YES;
      }
    }
  } else {
    if ([self anyOccurence:_input->textView.selectedRange]) {
      removeAttrs = YES;
    }
  }

  if (removeAttrs) {
    NSMutableDictionary *newTypingAttrs =
        [_input->textView.typingAttributes mutableCopy];
    newTypingAttrs[NSForegroundColorAttributeName] =
        [_input->config primaryColor];
    newTypingAttrs[NSUnderlineColorAttributeName] =
        [_input->config primaryColor];
    newTypingAttrs[NSStrikethroughColorAttributeName] =
        [_input->config primaryColor];
    if ([_input->config linkDecorationLine] == DecorationUnderline) {
      [newTypingAttrs removeObjectForKey:NSUnderlineStyleAttributeName];
    }
    _input->textView.typingAttributes = newTypingAttrs;
  }
}

// Handles detecting and removing automatic links
- (void)handleAutomaticLinks:(NSString *)word inRange:(NSRange)range {
  if (word.length == 0) {
    return;
  }

  if ([self shouldIgnoreAutomaticLinksInRange:range]) {
    return;
  }

  [self removeConnectedLinksIfNeeded:word range:range];

  if ([self hasManualLinkInRange:range]) {
    return;
  }

  BOOL matchesURL = [self stringMatchesAnyURLRegex:word];

  if (!matchesURL) {
    [self removeStaleAutomaticLinkIfNeeded:range];
    return;
  }

  if ([self isSameAutomaticLinkAlreadyApplied:word range:range]) {
    return;
  }

  [self addLink:word url:word range:range manual:NO withSelection:NO];

  [_input emitOnLinkDetectedEvent:word url:word range:range];
}

#pragma mark - Context checks

- (BOOL)shouldIgnoreAutomaticLinksInRange:(NSRange)range {
  InlineCodeStyle *inlineCodeStyle =
      _input->stylesDict[@([InlineCodeStyle getStyleType])];
  MentionStyle *mentionStyle =
      (MentionStyle *)_input->stylesDict[@([MentionStyle getStyleType])];
  CodeBlockStyle *codeBlockStyle =
      _input->stylesDict[@([CodeBlockStyle getStyleType])];

  if (!inlineCodeStyle || !mentionStyle || !codeBlockStyle) {
    return YES;
  }

  // Do not detect links inside mentions, inline code, or code blocks
  if ([mentionStyle anyOccurence:range])
    return YES;
  if ([inlineCodeStyle anyOccurence:range])
    return YES;
  if ([codeBlockStyle anyOccurence:range])
    return YES;

  return NO;
}

- (BOOL)hasManualLinkInRange:(NSRange)range {
  __block BOOL manualLinkPresent = NO;

  [_input->textView.textStorage
      enumerateAttribute:ManualLinkAttributeName
                 inRange:range
                 options:0
              usingBlock:^(id value, NSRange _, BOOL *stop) {
                if (value != nil) {
                  manualLinkPresent = YES;
                  *stop = YES;
                }
              }];

  return manualLinkPresent;
}

#pragma mark - Regex detection

- (BOOL)stringMatchesAnyURLRegex:(NSString *)string {
  NSRange fullRange = NSMakeRange(0, string.length);

  return ([[self.class fullURLRegex] numberOfMatchesInString:string
                                                     options:0
                                                       range:fullRange] > 0 ||
          [[self.class wwwURLRegex] numberOfMatchesInString:string
                                                    options:0
                                                      range:fullRange] > 0 ||
          [[self.class bareURLRegex] numberOfMatchesInString:string
                                                     options:0
                                                       range:fullRange] > 0);
}

+ (NSRegularExpression *)fullURLRegex {
  static NSRegularExpression *regex;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    regex =
        [NSRegularExpression regularExpressionWithPattern:
                                 @"http(s)?://"
                                 @"www\\.[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-z]"
                                 @"{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*)"
                                                  options:0
                                                    error:nil];
  });
  return regex;
}

+ (NSRegularExpression *)wwwURLRegex {
  static NSRegularExpression *regex;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    regex =
        [NSRegularExpression regularExpressionWithPattern:
                                 @"www\\.[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-z]"
                                 @"{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*)"
                                                  options:0
                                                    error:nil];
  });
  return regex;
}

+ (NSRegularExpression *)bareURLRegex {
  static NSRegularExpression *regex;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    regex = [NSRegularExpression
        regularExpressionWithPattern:@"[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-z]{"
                                     @"2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*)"
                             options:0
                               error:nil];
  });
  return regex;
}

#pragma mark - Link cleanup / deduplication

- (void)removeStaleAutomaticLinkIfNeeded:(NSRange)range {
  // anyOccurence means an automatic link exists here
  if ([self anyOccurence:range]) {
    [self removeAttributes:range];
  }
}

- (BOOL)isSameAutomaticLinkAlreadyApplied:(NSString *)url range:(NSRange)range {
  if (![self detectStyle:range]) {
    return NO;
  }

  LinkData *currentData = [self getLinkDataAt:range.location];
  if (!currentData) {
    return NO;
  }

  return (currentData.url != nil && [currentData.url isEqualToString:url]);
}

// handles refreshing manual links
- (void)handleManualLinks:(NSString *)word inRange:(NSRange)wordRange {
  // look for manual links within the word
  __block NSString *manualLinkMinValue = @"";
  __block NSString *manualLinkMaxValue = @"";
  __block NSInteger manualLinkMinIdx = -1;
  __block NSInteger manualLinkMaxIdx = -1;

  [_input->textView.textStorage
      enumerateAttribute:ManualLinkAttributeName
                 inRange:wordRange
                 options:0
              usingBlock:^(id value, NSRange range, BOOL *stop) {
                NSString *urlValue = (NSString *)value;
                if (urlValue != nullptr) {
                  NSInteger linkMin = range.location;
                  NSInteger linkMax = range.location + range.length - 1;
                  if (manualLinkMinIdx == -1 || linkMin < manualLinkMinIdx) {
                    manualLinkMinIdx = linkMin;
                    manualLinkMinValue = value;
                  }
                  if (manualLinkMaxIdx == -1 || linkMax > manualLinkMaxIdx) {
                    manualLinkMaxIdx = linkMax;
                    manualLinkMaxValue = value;
                  }
                }
              }];

  // no manual links
  if (manualLinkMinIdx == -1 || manualLinkMaxIdx == -1) {
    return;
  }

  // heuristic for refreshing manual links:
  // we update the Manual attribute between the bounds of existing ones
  // we do that only if the bounds point to the same url
  // this way manual link gets "extended" only if some characters were added
  // inside it
  if ([manualLinkMinValue isEqualToString:manualLinkMaxValue]) {
    NSRange newRange =
        NSMakeRange(manualLinkMinIdx, manualLinkMaxIdx - manualLinkMinIdx + 1);
    [_input->textView.textStorage addAttribute:NSForegroundColorAttributeName
                                         value:[_input->config linkColor]
                                         range:newRange];
    [_input->textView.textStorage addAttribute:NSUnderlineColorAttributeName
                                         value:[_input->config linkColor]
                                         range:newRange];
    [_input->textView.textStorage addAttribute:NSStrikethroughColorAttributeName
                                         value:[_input->config linkColor]
                                         range:newRange];
    if ([_input->config linkDecorationLine] == DecorationUnderline) {
      [_input->textView.textStorage addAttribute:NSUnderlineStyleAttributeName
                                           value:@(NSUnderlineStyleSingle)
                                           range:newRange];
    }
    [_input->textView.textStorage addAttribute:ManualLinkAttributeName
                                         value:manualLinkMinValue
                                         range:newRange];
    [_input->textView.textStorage addAttribute:LinkAttributeName
                                         value:manualLinkMinValue
                                         range:newRange];
  }

  // link typing attributes need to be fixed after these changes
  [self manageLinkTypingAttributes];
}

// replacing whole input (that starts with a link) with a manually typed letter
// improperly applies link's attributes to all the following text
- (BOOL)handleLeadingLinkReplacement:(NSRange)range
                     replacementText:(NSString *)text {
  // whole textView range gets replaced with a single letter
  if (_input->textView.textStorage.string.length > 0 &&
      NSEqualRanges(
          range, NSMakeRange(0, _input->textView.textStorage.string.length)) &&
      text.length == 1) {
    // first character detection is enough for the removal to be done
    if ([self detectStyle:NSMakeRange(0, 1)]) {
      [self
          removeAttributes:NSMakeRange(
                               0, _input->textView.textStorage.string.length)];
      // do the replacing manually
      [TextInsertionUtils replaceText:text
                                   at:range
                 additionalAttributes:nullptr
                                input:_input
                        withSelection:YES];
      return YES;
    }
  }
  return NO;
}

// MARK: - Private non-standard methods

// determines whether a given range contains only links pointing to one url
// assumes the whole range is links only already
- (BOOL)isSingleLinkIn:(NSRange)range {
  return [self findAllOccurences:range].count == 1;
}

- (void)removeConnectedLinksIfNeeded:(NSString *)word range:(NSRange)wordRange {
  BOOL anyAutomatic =
      [OccurenceUtils any:AutomaticLinkAttributeName
                withInput:_input
                  inRange:wordRange
            withCondition:^BOOL(id _Nullable value, NSRange range) {
              return [self styleCondition:value range:range];
            }];
  BOOL anyManual =
      [OccurenceUtils any:ManualLinkAttributeName
                withInput:_input
                  inRange:wordRange
            withCondition:^BOOL(id _Nullable value, NSRange range) {
              return [self styleCondition:value range:range];
            }];

  // both manual and automatic links are somewhere - delete!
  if (anyAutomatic && anyManual) {
    [self removeAttributes:wordRange];
    [self manageLinkTypingAttributes];
  }

  // we are now sure there is only one type of link there - and make sure it
  // covers the whole word
  BOOL onlyLinks = [OccurenceUtils
      detectMultiple:@[ ManualLinkAttributeName, AutomaticLinkAttributeName ]
           withInput:_input
             inRange:wordRange
       withCondition:^BOOL(id _Nullable value, NSRange range) {
         return [self styleCondition:value range:range];
       }];

  // only one link might be present!
  if (onlyLinks && ![self isSingleLinkIn:wordRange]) {
    [self removeAttributes:wordRange];
    [self manageLinkTypingAttributes];
  }
}

@end
